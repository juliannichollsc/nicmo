"""Imports the conventional bus routes of the Valle de Aburrá into the
"urban" layer of assets/cities/medellin/ (see city_layers.py).

Input: bus_routes.json made by tool/build_bus_routes.py from
  * Alcaldía de Medellín, Secretaría de Movilidad, "Rutas de Transporte
    Público" (ArcGIS MapServer transporte/VM_Movilidad, layer 2: one
    polyline per route and direction) and its stops (layer 0), CC BY-SA 4.0,
  * OpenStreetMap bus relations (ODbL).

  python3 tool/import_urban_buses.py <bus_routes.json> [<metropolitan_routes.json>]

The optional second file (tool/build_metropolitan_routes.py) adds the
metropolitan routes of the AMVA published by the Municipio de Itagüí
(lines "BU-AMVA-<code>").

What it does:
  * Routes integrated with the Metro (codes "254i", "C23ii"...) become
    feeder lines "AL-<code>" in the "buses" layer, replacing the
    approximate feeders of the same code that had no street path.
  * Every other route becomes a line "BU-<code>-<official id>" (shown as
    <code>) in the "urban" layer, with its stops.
  * OSM relations are skipped when the official layer or the Metro open
    data already has the route.
  * Ends within 450 m of a station are joined to it (transfers work);
    other ends get their own station named after the route's terminal.
  * Official paths over 40 km include out-and-back branches: they are kept
    but flagged approximate, so the planner prefers other options.
Headways are not published: 10 minutes is assumed for every route.
"""

import json
import math
import re
import sys

from city_layers import layer_sources, load_merged, save_split
from import_metro_open_data import assign_colours

CITY = "medellin"
JOIN_RADIUS_M = 450
HEADWAY_MIN = 10
LONG_KM = 40
OFFICIAL = (
    "https://www.medellin.gov.co/servidormapas/rest/services/transporte/"
    "VM_Movilidad/MapServer (Rutas de Transporte Público y paraderos, "
    "Secretaría de Movilidad de Medellín, datos 2025-08-14), CC BY-SA 4.0"
)


def metres(a, b):
    dlat = (a[0] - b[0]) * 110_574
    dlng = (a[1] - b[1]) * 111_320 * math.cos(math.radians((a[0] + b[0]) / 2))
    return math.hypot(dlat, dlng)


def slug(text):
    return re.sub(r"[^A-Z0-9]+", "-", text.upper()).strip("-")


def integrated_base(ref):
    """'254iB_TV 73' -> '254I', 'C23ii' -> 'C23II', '261i Der' -> '261I'."""
    match = re.match(r"^(C?\d+)(I+)", ref.upper().replace(" ", ""))
    return match.group(1) + match.group(2) if match else None


def clean_name(route):
    name = route["name"].replace("_", " – ").strip()
    return re.sub(r"\s+", " ", name)


METROPOLITAN = (
    "https://arcgis.itagui.gov.co/waserver/rest/services/Diagnostico/"
    "03_Dimension_Funcional/MapServer/26 (Rutas de transporte metropolitano, "
    "geoportal POT del Municipio de Itagüí), información pública"
)


def main(path, *more):
    data = json.load(open(path, encoding="utf-8"))
    for extra in more:
        data["routes"] += json.load(open(extra, encoding="utf-8"))["routes"]
    network = load_merged(CITY)
    sources = layer_sources(CITY)
    stations = {s["id"]: s for s in network["stations"]}
    hubs = [s for s in network["stations"] if not s["id"].startswith("bu_")]

    def nearest_hub(point):
        best = min(hubs, key=lambda s: metres(point, (s["lat"], s["lng"])))
        d = metres(point, (best["lat"], best["lng"]))
        return best if d <= JOIN_RADIUS_M else None

    def end_station(line_id, point, name, suffix):
        hub = nearest_hub(point)
        if hub is not None:
            return hub["id"]
        sid = f"bu_{line_id.lower()}_{suffix}"
        stations[sid] = {
            "id": sid,
            "name": name,
            "lat": round(point[0], 5),
            "lng": round(point[1], 5),
            "lines": [],
        }
        return sid

    # Published official layers; OSM relations duplicate them or the feeders.
    official = [r for r in data["routes"] if not r["source"].startswith("osm:")]
    official_bases = {
        integrated_base(r["ref"] or "")
        for r in official
        if r.get("integratedWithMetro")
    } - {None}

    # Approximate feeders (no path) replaced by an official integrated route.
    removed = {
        l["id"]
        for l in network["lines"]
        if l["id"].startswith("AL-")
        and not l.get("shape")
        and l["id"][3:] in official_bases
    }
    lines = [l for l in network["lines"] if l["id"] not in removed]
    # Earlier runs of this import are replaced.
    lines = [l for l in lines if "source" not in l]
    used_ids = {l["id"] for l in lines}

    added = {"AL": 0, "BU": 0}
    for route in official:
        ref = (route["ref"] or "").strip()
        shape = route["shape"]
        if len(shape) < 2 or not ref:
            continue
        integrated = route.get("integratedWithMetro")
        prefix = "AL" if integrated else "BU"
        official_id = route["source"].rsplit("=", 1)[-1]
        line_id = f"{prefix}-{slug(ref)}"
        if route["source"].startswith("itagui-pot:"):
            line_id = f"BU-AMVA-{slug(ref)}"
        elif line_id in used_ids or prefix == "BU":
            line_id = f"{line_id}-{official_id}"
        used_ids.add(line_id)
        name = clean_name(route)
        start_name = route.get("from") or name.split(" – ")[0]
        end_name = route.get("to") or name.split(" – ")[-1]
        ends = [
            end_station(line_id, shape[0], start_name, "a"),
            end_station(line_id, shape[-1], end_name, "b"),
        ]
        if ends[0] == ends[1]:
            # Circular route: board / alight along the street anyway.
            ends[1] = end_station(line_id, shape[len(shape) // 2], name, "m")
            if ends[1] == ends[0]:
                continue
        line = {
            "id": line_id,
            "name": (f"Ruta integrada {ref}: " if integrated else "") + name,
            "code": ref,
            "mode": "bus",
            "color": "#3949AB",
            "headwayMin": HEADWAY_MIN,
            "approximate": route["lengthKm"] > LONG_KM,
            "stations": ends,
            "shape": shape,
            "stops": [
                [s[0], s[1], re.sub(r",\s*Medell[ií]n$", "", s[2])]
                for s in route.get("stops", [])
            ],
            "municipalities": route.get("municipalities", []),
            "source": route["source"],
        }
        lines.append(line)
        added[prefix] += 1

    network["lines"] = lines
    used = {sid for line in lines for sid in line["stations"]}
    network["stations"] = [s for s in stations.values() if s["id"] in used]
    assign_colours(network)

    sources.setdefault("urban", [])
    for layer in ("urban", "buses"):
        if OFFICIAL not in sources.setdefault(layer, []):
            sources[layer].append(OFFICIAL)
    if more and METROPOLITAN not in sources["urban"]:
        sources["urban"].append(METROPOLITAN)
    save_split(CITY, network, sources)
    print(
        f"{added['BU']} conventional routes, {added['AL']} integrated routes "
        f"with official paths, {len(removed)} approximate feeders replaced"
    )


if __name__ == "__main__":
    main(*sys.argv[1:])
