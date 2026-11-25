"""Imports Metro de Medellín open data into the "buses" layer of assets/cities/medellin/.

Sources (Metro de Medellín open data portal,
https://datosabiertos-metrodemedellin.opendata.arcgis.com, CC BY-SA 4.0):
  * "Rutas Alimentadoras" feature layer: street path of every feeder route
    (cuencas 3 and 6), one feature per itinerary.
  * "Paradas Alimentadoras" feature layer: their stops.
  * GTFS 2025: official path of Metroplús line O.

Updates the "buses" layer of assets/cities/medellin/ (see city_layers.py).
Download them first (GeoJSON, WGS84) and pass the folder:
  python3 tool/import_metro_open_data.py <folder>
with <folder>/routes.geojson, <folder>/stops.geojson and
<folder>/gtfs/shapes.txt.

Feeder routes become lines "AL-<route>" (replacing the approximate ones of
the same code) with:
  * shape: the official path (one direction, simplified to ~8 m),
  * stations: both ends; an end within 450 m of a metro / tram / cable /
    Metroplús station is joined to that station so transfers work,
  * stops: official stops [lat, lng, name] (drawn on the map).
Colours: a palette assigned so that routes running near each other differ.
"""

import csv
import json
import math
import re
import sys

from city_layers import layer_sources, load_merged, save_split
from collections import defaultdict

CITY = "medellin"
JOIN_RADIUS_M = 450
SOURCE = (
    "https://datosabiertos-metrodemedellin.opendata.arcgis.com "
    "(Rutas Alimentadoras, Paradas Alimentadoras, GTFS 2025), CC BY-SA 4.0"
)

# Distinct, dark enough for the light map (>= 3:1 on #F2F3F0).
PALETTE = [
    "#6A1B9A", "#00838F", "#827717", "#E65100", "#6D4C41", "#455A64",
    "#2E7D32", "#C2185B", "#283593", "#BF360C", "#00695C", "#5D4037",
    "#7B1FA2", "#1565C0", "#9E7C0C", "#AD1457",
]


def metres(a, b):
    dlat = (a[0] - b[0]) * 110_574
    dlng = (a[1] - b[1]) * 111_320 * math.cos(math.radians((a[0] + b[0]) / 2))
    return math.hypot(dlat, dlng)


def simplify(points, tolerance):
    if len(points) < 3:
        return points
    a, b = points[0], points[-1]
    ax, ay = a[1] * 110_600, a[0] * 110_600
    bx, by = b[1] * 110_600 - ax, b[0] * 110_600 - ay
    length = math.hypot(bx, by)
    best, index = 0, 0
    for i, p in enumerate(points[1:-1], 1):
        px, py = p[1] * 110_600 - ax, p[0] * 110_600 - ay
        d = math.hypot(px, py) if length == 0 else abs(bx * py - by * px) / length
        if d > best:
            best, index = d, i
    if best > tolerance:
        return simplify(points[: index + 1], tolerance)[:-1] + simplify(
            points[index:], tolerance
        )
    return [a, b]


def path_of(geometry):
    """[lat, lng] points; multi-lines joined in order."""
    if geometry["type"] == "LineString":
        parts = [geometry["coordinates"]]
    else:
        parts = geometry["coordinates"]
    points = []
    for part in parts:
        points += [[p[1], p[0]] for p in part]
    return points


def slug(text):
    text = text.lower()
    for a, b in zip("áéíóúñ", "aeioun"):
        text = text.replace(a, b)
    return re.sub(r"[^a-z0-9]+", "_", text).strip("_")


def main(folder):
    network = load_merged(CITY)
    sources = layer_sources(CITY)
    routes = json.load(open(f"{folder}/routes.geojson", encoding="utf-8"))
    stops = json.load(open(f"{folder}/stops.geojson", encoding="utf-8"))

    # One itinerary per route: direction 1, else circular (3), else any.
    by_route = defaultdict(list)
    for feature in routes["features"]:
        by_route[feature["properties"]["ruta"].strip()].append(feature)

    def pick(features):
        rank = {1: 0, 3: 1, 2: 2}
        return min(
            features,
            key=lambda f: (
                rank.get(f["properties"]["sentido"], 3),
                -len(path_of(f["geometry"])),
            ),
        )

    stops_by_route = defaultdict(list)
    for feature in stops["features"]:
        props = feature["properties"]
        lng, lat = feature["geometry"]["coordinates"][:2]
        name = (props.get("parada") or props.get("label") or "").strip()
        stops_by_route[props["ruta"].strip()].append([lat, lng, name])

    official = {f"AL-{code}" for code in by_route}
    # Approximate entries of the same codes (e.g. AL-C3-004 vs C3-004B) are
    # replaced as well: the official data splits them into variants.
    family = {re.match(r"(C\d-\d{3})", code).group(1) for code in by_route}
    removed = {
        line["id"]
        for line in network["lines"]
        if line["id"] in official
        or (
            line["id"].startswith("AL-C")
            and re.match(r"AL-(C\d-\d{3})", line["id"])
            and re.match(r"AL-(C\d-\d{3})", line["id"]).group(1) in family
        )
    }
    network["lines"] = [l for l in network["lines"] if l["id"] not in removed]

    stations = {s["id"]: s for s in network["stations"]}
    for station in stations.values():
        station["lines"] = [i for i in station["lines"] if i not in removed]
    line_modes = {l["id"]: l["mode"] for l in network["lines"]}
    # Stations a feeder can be joined to: rail, cable and Metroplús.
    hubs = [
        s
        for s in stations.values()
        if any(
            not lid.startswith("AL-") and line_modes.get(lid)
            for lid in s["lines"]
        )
    ]

    def nearest_hub(point):
        best = min(hubs, key=lambda s: metres(point, [s["lat"], s["lng"]]))
        if metres(point, [best["lat"], best["lng"]]) <= JOIN_RADIUS_M:
            return best
        return None

    def end_station(code, point, route_stops, suffix, avoid=""):
        hub = nearest_hub(point)
        if hub:
            return hub["id"]
        name = None
        if route_stops:
            near = min(route_stops, key=lambda s: metres(point, s))
            if metres(point, near) < 800 and near[2]:
                name = near[2]
        if name is None:
            # Terminal named in the route name ("C3-002 Bulerías - Aguacatala").
            label = re.sub(r"^C\d-\d{3}\w*\s*", "", line_names.get(code, ""))
            parts = [
                part.strip()
                for part in label.split(" - ")
                if part.strip()
                and "estaci" not in part.lower()
                and slug(part) not in slug(avoid)
                and slug(avoid) not in slug(part)
            ]
            name = parts[0] if parts else code
        station_id = f"al_{slug(code)}_{suffix}"
        stations[station_id] = {
            "id": station_id,
            "name": name or code,
            "lat": round(point[0], 6),
            "lng": round(point[1], 6),
            "lines": [],
        }
        return station_id

    line_names = {
        code: (pick(features)["properties"].get("linea") or "").strip()
        for code, features in by_route.items()
    }
    new_lines = []
    for code in sorted(by_route):
        feature = pick(by_route[code])
        props = feature["properties"]
        path = path_of(feature["geometry"])
        if len(path) < 2:
            continue
        line_id = f"AL-{code}"
        route_stops = []
        for stop in stops_by_route.get(code, []):
            if all(metres(stop, s) > 15 for s in route_stops):
                route_stops.append(stop)

        start, end = path[0], path[-1]
        ends = [end_station(code, start, route_stops, "a")]
        if metres(start, end) < 150:
            # Circular route: its far point becomes the other end.
            far = max(path, key=lambda p: metres(start, p))
            ends.append(
                end_station(code, far, route_stops, "b", stations[ends[0]]["name"])
            )
            far_index = path.index(far)
            path = path[: far_index + 1]
        else:
            ends.append(
                end_station(code, end, route_stops, "b", stations[ends[0]]["name"])
            )
        if ends[0] == ends[1]:
            continue
        for station_id in ends:
            if line_id not in stations[station_id]["lines"]:
                stations[station_id]["lines"].append(line_id)

        name = (props.get("linea") or code).strip()
        name = re.sub(r"\s+", " ", name)
        new_lines.append(
            {
                "id": line_id,
                "name": f"Ruta integrada {name}",
                "mode": "bus",
                "color": "#65BC4B",
                "avgSpeedKmh": 14,
                "headwayMin": 12,
                "approximate": False,
                "stations": ends,
                "shape": [
                    [round(p[0], 5), round(p[1], 5)] for p in simplify(path, 8)
                ],
                "stops": [
                    [round(s[0], 6), round(s[1], 6), s[2]] for s in route_stops
                ],
            }
        )

    network["lines"] += new_lines

    # Metroplús line O: official path from the GTFS.
    shape_o = []
    with open(f"{folder}/gtfs/shapes.txt", encoding="utf-8-sig") as f:
        for row in csv.DictReader(f):
            if row["shape_id"] == "LO_iti01":
                shape_o.append(
                    (
                        int(row["shape_pt_sequence"]),
                        [float(row["shape_pt_lat"]), float(row["shape_pt_lon"])],
                    )
                )
    if shape_o:
        points = [p for _, p in sorted(shape_o)]
        for line in network["lines"]:
            if line["id"] == "O":
                line["shape"] = [
                    [round(p[0], 5), round(p[1], 5)] for p in simplify(points, 6)
                ]

    # Drop stations no line uses any more.
    used = {sid for line in network["lines"] for sid in line["stations"]}
    network["stations"] = [s for s in stations.values() if s["id"] in used]

    assign_colours(network)
    if SOURCE not in sources.setdefault("buses", []):
        sources["buses"].append(SOURCE)
    save_split(CITY, network, sources)
    print(
        f"{len(new_lines)} official feeder routes, {len(removed)} replaced, "
        f"{len(network['lines'])} lines, {len(network['stations'])} stations"
    )


def assign_colours(network, prefixes=("AL-", "BU-")):
    """Greedy colouring: street bus routes (feeders "AL-", conventional
    buses "BU-") that come within 300 m of each other get different
    colours."""
    feeders = [
        l
        for l in network["lines"]
        if l["id"].startswith(prefixes) and l.get("shape")
    ]
    cell = 0.003  # ~330 m grid

    def cells(line):
        return {
            (int(p[0] / cell), int(p[1] / cell)) for p in line["shape"]
        }

    occupied = {l["id"]: cells(l) for l in feeders}

    def near(a, b):
        ca, cb = occupied[a], occupied[b]
        for x, y in ca:
            for dx in (-1, 0, 1):
                for dy in (-1, 0, 1):
                    if (x + dx, y + dy) in cb:
                        return True
        return False

    # Most crowded first.
    order = sorted(
        feeders,
        key=lambda l: -sum(near(l["id"], o["id"]) for o in feeders if o is not l),
    )
    colour = {}
    for line in order:
        taken = {
            colour[o["id"]]
            for o in feeders
            if o["id"] in colour and near(line["id"], o["id"])
        }
        free = [c for c in PALETTE if c not in taken] or PALETTE
        # Spread the use of each colour across the city.
        usage = defaultdict(int)
        for c in colour.values():
            usage[c] += 1
        colour[line["id"]] = min(free, key=lambda c: usage[c])
    for line in feeders:
        line["color"] = colour[line["id"]]


if __name__ == "__main__":
    main(sys.argv[1])
