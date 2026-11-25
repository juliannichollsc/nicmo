"""Per-city transit data split in layers (shared by the data tools).

A city's network lives in assets/cities/<city>/ as one JSON file per layer:

  metro.json   metro, tram and cable lines and their stations
  buses.json   buses of the integrated system (Metroplús, line O and the
               integrated feeder routes "AL-*")
  urban.json   conventional public buses ("transporte público colectivo",
               lines "BU-*"), see tool/import_urban_buses.py

The app loads only the layers of the city in use and merges them; stations
are shared by id across layers (a feeder ends at a metro station). Each
station is stored in the first layer whose lines use it, and station "lines"
are not stored: the app derives them from the lines.

Line geometry is stored as an encoded polyline ("path", precision 5, the
Google format) instead of a list of [lat, lng] pairs: ~60 % smaller.
"""

import json
import os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CITIES = os.path.join(ROOT, "assets", "cities")

# Layer of each line, in loading order.
LAYERS = ("metro", "buses", "urban")


def layer_of(line):
    if line["mode"] in ("metro", "tram", "cable"):
        return "metro"
    if line["id"].startswith("BU-"):
        return "urban"
    return "buses"


def encode_polyline(points, precision=5):
    factor = 10**precision
    result = []
    last_lat = last_lng = 0
    for lat, lng in points:
        ilat, ilng = round(lat * factor), round(lng * factor)
        for delta in (ilat - last_lat, ilng - last_lng):
            value = ~(delta << 1) if delta < 0 else delta << 1
            while value >= 0x20:
                result.append(chr((0x20 | (value & 0x1F)) + 63))
                value >>= 5
            result.append(chr(value + 63))
        last_lat, last_lng = ilat, ilng
    return "".join(result)


def decode_polyline(text, precision=5):
    factor = 10**precision
    points, index, lat, lng = [], 0, 0, 0
    while index < len(text):
        deltas = []
        for _ in range(2):
            shift = result = 0
            while True:
                b = ord(text[index]) - 63
                index += 1
                result |= (b & 0x1F) << shift
                shift += 5
                if b < 0x20:
                    break
            deltas.append(~(result >> 1) if result & 1 else result >> 1)
        lat += deltas[0]
        lng += deltas[1]
        points.append([lat / factor, lng / factor])
    return points


def _path(city, layer):
    return os.path.join(CITIES, city, f"{layer}.json")


def load_merged(city):
    """Every layer of [city] as one network {version, sources, lines,
    stations} with "shape" lists and station "lines" (tool format)."""
    merged = {"version": "", "sources": [], "lines": [], "stations": []}
    seen = set()
    for layer in LAYERS:
        path = _path(city, layer)
        if not os.path.exists(path):
            continue
        data = json.load(open(path, encoding="utf-8"))
        merged["version"] = max(merged["version"], data.get("version", ""))
        for source in data.get("sources", []):
            if source not in merged["sources"]:
                merged["sources"].append(source)
        for line in data["lines"]:
            if "path" in line:
                line["shape"] = decode_polyline(line.pop("path"))
            merged["lines"].append(line)
        for station in data["stations"]:
            if station["id"] not in seen:
                seen.add(station["id"])
                merged["stations"].append(station)
    for station in merged["stations"]:
        station["lines"] = [
            l["id"] for l in merged["lines"] if station["id"] in l["stations"]
        ]
    return merged


def layer_sources(city):
    """{layer: sources} as currently saved for [city]."""
    result = {}
    for layer in LAYERS:
        path = _path(city, layer)
        if os.path.exists(path):
            result[layer] = json.load(open(path, encoding="utf-8"))["sources"]
    return result


def save_split(city, network, sources_by_layer=None):
    """Writes [network] (tool format) as the layer files of [city], each
    with its own sources (by default, the ones it already had)."""
    sources_by_layer = sources_by_layer or layer_sources(city)
    os.makedirs(os.path.join(CITIES, city), exist_ok=True)
    stations = {s["id"]: s for s in network["stations"]}
    owner = {}
    for layer in LAYERS:
        for line in network["lines"]:
            if layer_of(line) == layer:
                for sid in line["stations"]:
                    owner.setdefault(sid, layer)
    for layer in LAYERS:
        lines = []
        for line in network["lines"]:
            if layer_of(line) != layer:
                continue
            line = dict(line)
            shape = line.pop("shape", None)
            if shape:
                line["path"] = encode_polyline(shape)
            lines.append(line)
        path = _path(city, layer)
        if not lines:
            if os.path.exists(path):
                os.remove(path)
            continue
        layer_stations = [
            {k: v for k, v in s.items() if k != "lines"}
            for sid, s in stations.items()
            if owner.get(sid) == layer
        ]
        sources = sources_by_layer.get(layer, network["sources"])
        with open(path, "w", encoding="utf-8") as f:
            json.dump(
                {
                    "version": network["version"],
                    "layer": layer,
                    "sources": sources,
                    "lines": lines,
                    "stations": layer_stations,
                },
                f,
                ensure_ascii=False,
                separators=(",", ":"),
            )
        print(f"{path}: {len(lines)} lines, {len(layer_stations)} stations, "
              f"{os.path.getsize(path) / 1024:.0f} KB")
