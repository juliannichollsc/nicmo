"""Build bus_routes.json from official Medellín layer + OSM relations.

Inputs in <dir>/raw (download first, GeoJSON WGS84):
  medellin/rutas_tp.geojson  VM_Movilidad/MapServer/2 query (all features)
  medellin/paradas_*.geojson VM_Movilidad/MapServer/0 query (paged)
  osm/routes.json            Overpass: bus/minibus route relations, out geom
  osm/admin.json             Overpass: admin_level=6 boundaries of the valley
See docs/rutas_buses_valle_aburra_2026.md; then run
tool/import_urban_buses.py on the result.
Usage: python3 -I tool/build_bus_routes.py <dir>
"""
import glob
import json
import math
import os
import re
import sys
import unicodedata
from collections import Counter, defaultdict

BASE = sys.argv[1]
RAW = os.path.join(BASE, "raw")
GAP_M = 300.0
DP_TOL = 10.0
STOP_MAX_M = 50.0
TODAY = "2026-10-14"

VALLEY = {
    "Medellín", "Envigado", "Sabaneta", "Itagüí", "Copacabana", "Bello",
    "La Estrella", "Caldas", "Girardota", "Barbosa",
}
FOCUS = {"Medellín", "Envigado", "Sabaneta", "Itagüí", "Copacabana", "Bello"}

# ---------------------------------------------------------------- geometry
R_E = 6371008.8
LAT0 = math.radians(6.25)


def xy(lat, lon):
    return (math.radians(lon) * math.cos(LAT0) * R_E, math.radians(lat) * R_E)


def hav(a, b):
    la1, lo1, la2, lo2 = map(math.radians, (a[0], a[1], b[0], b[1]))
    h = math.sin((la2 - la1) / 2) ** 2 + math.cos(la1) * math.cos(la2) * math.sin((lo2 - lo1) / 2) ** 2
    return 2 * R_E * math.asin(math.sqrt(h))


def length_m(pts):
    return sum(hav(pts[i], pts[i + 1]) for i in range(len(pts) - 1))


def seg_dist(p, a, b):
    (px, py), (ax, ay), (bx, by) = p, a, b
    dx, dy = bx - ax, by - ay
    if dx == 0 and dy == 0:
        return math.hypot(px - ax, py - ay)
    t = max(0.0, min(1.0, ((px - ax) * dx + (py - ay) * dy) / (dx * dx + dy * dy)))
    return math.hypot(px - ax - t * dx, py - ay - t * dy)


def dp(pts, tol):
    if len(pts) < 3:
        return pts
    P = [xy(*p) for p in pts]
    keep = [False] * len(pts)
    keep[0] = keep[-1] = True
    stack = [(0, len(pts) - 1)]
    while stack:
        i, j = stack.pop()
        best, idx = 0.0, -1
        for k in range(i + 1, j):
            d = seg_dist(P[k], P[i], P[j])
            if d > best:
                best, idx = d, k
        if best > tol and idx > 0:
            keep[idx] = True
            stack.append((i, idx))
            stack.append((idx, j))
    return [p for p, k in zip(pts, keep) if k]


def dist_to_line(p, line_xy):
    q = xy(*p)
    return min(seg_dist(q, line_xy[i], line_xy[i + 1]) for i in range(len(line_xy) - 1))


def stitch(parts):
    """Order/orient polyline parts greedily. Returns (points, max_gap_m)."""
    parts = [p for p in parts if len(p) >= 2]
    if not parts:
        return [], float("inf")
    rem = parts[:]
    # start with the part whose start is farthest from any other part's end (heuristic: first)
    chain = list(rem.pop(0))
    max_gap = 0.0
    while rem:
        best = None
        for idx, p in enumerate(rem):
            for rev in (False, True):
                q = p[::-1] if rev else p
                d_end = hav(chain[-1], q[0])
                d_start = hav(q[-1], chain[0])
                for d, where in ((d_end, "end"), (d_start, "start")):
                    if best is None or d < best[0]:
                        best = (d, idx, rev, where)
        d, idx, rev, where = best
        q = rem.pop(idx)
        q = q[::-1] if rev else q
        max_gap = max(max_gap, d)
        if where == "end":
            chain.extend(q[1:] if d < 1 else q)
        else:
            chain = (q[:-1] if d < 1 else q) + chain
    return chain, max_gap


def internal_max_gap(pts):
    return max((hav(pts[i], pts[i + 1]) for i in range(len(pts) - 1)), default=0.0)


# ------------------------------------------------------------ municipalities
def load_munis():
    d = json.load(open(os.path.join(RAW, "osm", "admin.json")))
    munis = {}
    for r in d["elements"]:
        name = r["tags"].get("name")
        if name not in VALLEY:
            continue
        ways = [[(g["lat"], g["lon"]) for g in m["geometry"]] for m in r["members"]
                if m["type"] == "way" and m.get("role") in ("outer", "") and m.get("geometry")]
        rings = []
        ways = [w[:] for w in ways]
        while ways:
            ring = ways.pop(0)
            changed = True
            while changed and ring[0] != ring[-1]:
                changed = False
                for i, w in enumerate(ways):
                    if w[0] == ring[-1]:
                        ring += w[1:]
                    elif w[-1] == ring[-1]:
                        ring += w[::-1][1:]
                    elif w[-1] == ring[0]:
                        ring = w[:-1] + ring
                    elif w[0] == ring[0]:
                        ring = w[::-1][:-1] + ring
                    else:
                        continue
                    ways.pop(i)
                    changed = True
                    break
            rings.append(ring)
        lats = [p[0] for rg in rings for p in rg]
        lons = [p[1] for rg in rings for p in rg]
        munis[name] = {"rings": rings, "bbox": (min(lats), min(lons), max(lats), max(lons)), "osm": r["id"]}
    return munis


def pip(lat, lon, ring):
    inside = False
    n = len(ring)
    j = n - 1
    for i in range(n):
        yi, xi = ring[i]
        yj, xj = ring[j]
        if (yi > lat) != (yj > lat) and lon < (xj - xi) * (lat - yi) / (yj - yi + 1e-15) + xi:
            inside = not inside
        j = i
    return inside


def which_muni(lat, lon, munis):
    for name, m in munis.items():
        b = m["bbox"]
        if not (b[0] <= lat <= b[2] and b[1] <= lon <= b[3]):
            continue
        if sum(pip(lat, lon, rg) for rg in m["rings"]) % 2 == 1:
            return name
    return None


def municipalities_of(pts, munis, min_m=150.0):
    acc = Counter()
    for i in range(len(pts) - 1):
        a, b = pts[i], pts[i + 1]
        seg = hav(a, b)
        n = max(1, int(seg // 50))
        for k in range(n):
            t = (k + 0.5) / n
            m = which_muni(a[0] + (b[0] - a[0]) * t, a[1] + (b[1] - a[1]) * t, munis)
            if m:
                acc[m] += seg / n
    order = ["Medellín", "Bello", "Copacabana", "Envigado", "Sabaneta", "Itagüí",
             "La Estrella", "Caldas", "Girardota", "Barbosa"]
    return [m for m in order if acc[m] >= min_m], {k: round(v / 1000, 2) for k, v in acc.items()}


# ------------------------------------------------------------------ helpers
def slug(s):
    s = unicodedata.normalize("NFKD", s or "").encode("ascii", "ignore").decode()
    return re.sub(r"[^A-Za-z0-9]+", "-", s).strip("-").upper() or "X"


def r5(p):
    return [round(p[0], 5), round(p[1], 5)]


def split_name(name):
    if not name:
        return None, None
    parts = [x.strip() for x in re.split(r"\s+-\s+|(?<=[a-záéíóúñ])-(?=[A-ZÁÉÍÓÚÑ])", name) if x.strip()]
    if len(parts) == 2:
        return parts[0], parts[1]
    return None, None


# --------------------------------------------------- official Medellín layer
def build_official(munis, log):
    feats = json.load(open(os.path.join(RAW, "medellin", "rutas_tp.geojson")))["features"]
    stops = []
    for g in sorted(glob.glob(os.path.join(RAW, "medellin", "paradas_*.geojson"))):
        stops.extend(json.load(open(g))["features"])
    stops_by = defaultdict(list)
    for s in stops:
        p = s["properties"]
        stops_by[(str(p["id_ruta"]), p["recorrido"])].append(s)

    by_route = defaultdict(list)
    for f in feats:
        by_route[f["properties"]["id_ruta"]].append(f)

    out, dropped = [], []
    for rid, fs in by_route.items():
        cands = []
        for f in fs:
            g = f["geometry"]
            if not g:
                continue
            if g["type"] == "LineString":
                parts = [g["coordinates"]]
            else:
                parts = g["coordinates"]
            parts = [[(c[1], c[0]) for c in p] for p in parts]
            pts, gap = stitch(parts) if len(parts) > 1 else (parts[0], 0.0)
            # vertex spacing inside a single LineString is not a gap (long straight road segments)
            cands.append((gap <= GAP_M, length_m(pts), pts, gap, f))
        ok = [c for c in cands if c[0]]
        if not ok:
            p = fs[0]["properties"]
            dropped.append({"id_ruta": rid, "codigo": p["codigo"], "nombre": p["nombre"],
                            "maxGapM": round(min(c[3] for c in cands))})
            continue
        ok.sort(key=lambda c: -c[1])
        _, L, pts, gap, f = ok[0]
        p = f["properties"]
        shape = dp(pts, DP_TOL)
        line_xy = [xy(*q) for q in shape]
        st = []
        for s in sorted(stops_by.get((rid, p["recorrido"]), []), key=lambda s: s["properties"]["nro_parada"]):
            sp = s["properties"]
            lat, lon = sp.get("latitud"), sp.get("longitud")
            if lat is None:
                lon, lat = s["geometry"]["coordinates"][:2]
            if dist_to_line((lat, lon), line_xy) <= STOP_MAX_M:
                st.append([round(lat, 5), round(lon, 5), (sp.get("direccion") or "").strip()])
        muni_list, km_by = municipalities_of(shape, munis)
        frm, to = split_name(p["nombre"])
        code = (p["codigo"] or "").strip() or None
        tipo = p["tipo"]
        out.append({
            "id": f"BUS-MED-{slug(code)}-{rid}",
            "ref": code,
            "name": p["nombre"],
            "from": frm,
            "to": to,
            "operator": p["empresa"],
            "municipalities": muni_list,
            "source": f"medellin:VM_Movilidad/2:id_ruta={rid}",
            "shape": [r5(q) for q in shape],
            "stops": st,
            "lengthKm": round(length_m(shape) / 1000, 2),
            "approximate": False,
            # extra metadata (not in the minimal schema but useful for filtering)
            "direction": p["recorrido"],
            "category": tipo,
            "integratedWithMetro": tipo == "Integrada",
            "sistema": p["sistema"],
            "kmByMunicipality": km_by,
            "regulator": "Secretaría de Movilidad de Medellín",
            "dataDate": "2025-08-14",
        })
    log["official_routes_in"] = len(by_route)
    log["official_features_in"] = len(feats)
    log["official_dropped"] = dropped
    log["stops_layer_features"] = len(stops)
    return out


# ---------------------------------------------------------------- OSM routes
EXCLUDE_REF = re.compile(r"^(C3-|C6-|AL)", re.I)


def build_osm(munis, log):
    d = json.load(open(os.path.join(RAW, "osm", "routes.json")))
    groups = defaultdict(list)
    excluded = []
    for r in d["elements"]:
        t = r.get("tags", {})
        ref, name = t.get("ref"), t.get("name")
        text = " ".join(str(t.get(k, "")) for k in ("network", "operator", "name")).lower()
        reason = None
        if not ref and not name:
            reason = "sin ref ni nombre (y fuera del valle: Rionegro)"
        elif "metroplus" in text or "metroplús" in text:
            reason = "Metroplús"
        elif EXCLUDE_REF.match(ref or "") or "alimentador" in text or t.get("network") == "SIT":
            reason = "alimentadora/SIT Metro"
        if reason:
            excluded.append({"osm": r["id"], "ref": ref, "name": name, "reason": reason})
            continue
        ways, stops = [], []
        for m in r["members"]:
            if m["type"] == "way" and m.get("geometry") and not (m.get("role") or "").startswith("platform"):
                ways.append([(g["lat"], g["lon"]) for g in m["geometry"]])
            elif m["type"] == "node" and m.get("role", "").startswith(("platform", "stop")) and "lat" in m:
                stops.append([round(m["lat"], 5), round(m["lon"], 5), ""])
        # stitch in relation order, flipping ways as needed
        chain, max_gap = [], 0.0
        for wi, w in enumerate(ways):
            if not chain:
                chain = w[:]
                continue
            opts = [(hav(chain[-1], w[0]), w), (hav(chain[-1], w[-1]), w[::-1])]
            g, ww = min(opts, key=lambda o: o[0])
            # the first way's orientation is unknown: allow flipping it when joining the second
            if wi == 1:
                rc = chain[::-1]
                g2, ww2 = min([(hav(rc[-1], w[0]), w), (hav(rc[-1], w[-1]), w[::-1])], key=lambda o: o[0])
                if g2 < g:
                    chain, g, ww = rc, g2, ww2
            max_gap = max(max_gap, g)
            chain += ww[1:] if g < 1 else ww
        groups[(ref, name.split(":")[0] if name else None)].append((r, chain, max_gap, stops))
    out, dropped = [], []
    for (ref, _), items in groups.items():
        items.sort(key=lambda it: (it[2] > GAP_M, -length_m(it[1]) if it[1] else 0))
        r, chain, gap, stops = items[0]
        t = r["tags"]
        if not chain or gap > GAP_M:
            dropped.append({"osm": r["id"], "ref": ref, "name": t.get("name"), "maxGapM": round(gap)})
            continue
        shape = dp(chain, DP_TOL)
        muni_list, km_by = municipalities_of(shape, munis)
        out.append({
            "id": f"BUS-OSM-{slug(ref)}-{r['id']}",
            "ref": ref,
            "name": t.get("name"),
            "from": t.get("from"),
            "to": t.get("to"),
            "operator": t.get("operator"),
            "municipalities": muni_list,
            "source": f"osm:relation/{r['id']}",
            "shape": [r5(q) for q in shape],
            "stops": stops,
            "lengthKm": round(length_m(shape) / 1000, 2),
            "approximate": False,
            "direction": None,
            "category": "Integrada (OSM, sin verificar vigencia)",
            "integratedWithMetro": True,
            "sistema": None,
            "kmByMunicipality": km_by,
            "regulator": None,
            "dataDate": "OSM (relación creada ~2015-2017; sin verificar 2025-2026)",
            "otherDirectionsOsm": [it[0]["id"] for it in items[1:]],
        })
    log["osm_relations_in"] = len(d["elements"])
    log["osm_excluded"] = excluded
    log["osm_dropped"] = dropped
    log["osm_timestamp"] = d["osm3s"]["timestamp_osm_base"]
    return out


def main():
    munis = load_munis()
    log = {"municipal_boundaries": {k: v["osm"] for k, v in munis.items()}}
    off = build_official(munis, log)
    osm = build_osm(munis, log)
    # OSM duplicates of official codes?
    off_refs = {(r["ref"] or "").upper() for r in off}
    osm = [r for r in osm if (r["ref"] or "").upper() not in off_refs]
    routes = off + osm
    routes = [r for r in routes if set(r["municipalities"]) & VALLEY]
    routes.sort(key=lambda r: (r["source"].split(":")[0], r["ref"] or "", r["name"] or ""))
    for r in routes:
        flags = []
        if r["lengthKm"] > 40:
            flags.append("trazado muy largo (>40 km): posible recorrido con ramales ida-vuelta en la geometría oficial")
        for m, km in r["kmByMunicipality"].items():
            if m != "Medellín" and m in r["municipalities"] and km < 2:
                flags.append(f"paso marginal por {m} ({km} km)")
        if r["source"].startswith("osm"):
            flags.append("relación OSM antigua; vigencia 2026 no verificada")
        r["qaFlags"] = flags
    doc = {
        "generated": TODAY,
        "sources": [
            {"name": "Alcaldía de Medellín – Secretaría de Movilidad: Rutas de Transporte Público (MapServer transporte/VM_Movilidad, capa 2)",
             "url": "https://www.medellin.gov.co/servidormapas/rest/services/transporte/VM_Movilidad/MapServer/2",
             "license": "CC BY-SA 4.0 (metadato GeoMedellín 07926629-1e38-4d05-824a-392bb46562cb)",
             "retrieved": TODAY},
            {"name": "Alcaldía de Medellín – Paradas de rutas de transporte público colectivo (VM_Movilidad, capa 0; datos 2018)",
             "url": "https://www.medellin.gov.co/servidormapas/rest/services/transporte/VM_Movilidad/MapServer/0",
             "license": "CC BY-SA 4.0 (metadato GeoMedellín 87040290-12e9-44c1-b39d-f6cba65c0b95)",
             "retrieved": TODAY},
            {"name": "OpenStreetMap – relaciones route=bus vía Overpass API",
             "url": "https://overpass-api.de/api/interpreter",
             "license": "ODbL 1.0 (© OpenStreetMap contributors)",
             "retrieved": TODAY},
            {"name": "OpenStreetMap – límites municipales admin_level=6 (cálculo de municipios)",
             "url": "https://overpass.kumi.systems/api/interpreter",
             "license": "ODbL 1.0 (© OpenStreetMap contributors)",
             "retrieved": TODAY},
        ],
        "notes": [
            "La capa oficial cubre SOLO las rutas urbanas autorizadas por la Secretaría de Movilidad de Medellín (252 rutas, 33 empresas, fecha_actualizacion 2025-08-14). Las rutas metropolitanas reguladas por el AMVA (Medellín–Envigado/Itagüí/Sabaneta/Bello/Copacabana, etc.) y las rutas municipales de esos municipios NO tienen geometría pública abierta localizada y no están en este archivo.",
            "category='Integrada' / integratedWithMetro=true: rutas integradas tarifariamente con el Metro operadas por empresas privadas; filtrar si se quieren excluir.",
            "stops: paraderos de la capa oficial de 2018 enlazados por id_ruta y sentido, filtrados a <=50 m del trazado; name = dirección.",
            "from/to: derivados del nombre oficial sólo cuando tiene la forma 'A - B'; si no, null.",
        ],
        "routes": routes,
    }
    out_path = os.path.join(BASE, "bus_routes.json")
    with open(out_path, "w", encoding="utf-8") as fh:
        json.dump(doc, fh, ensure_ascii=False, separators=(",", ":"))
    log["routes_out"] = len(routes)
    log["by_source"] = Counter(r["source"].split(":")[0] for r in routes)
    log["by_muni"] = Counter(m for r in routes for m in r["municipalities"])
    log["by_muni_non_integrated"] = Counter(m for r in routes if not r["integratedWithMetro"] for m in r["municipalities"])
    log["by_category"] = Counter(r["category"] for r in routes)
    log["routes_with_stops"] = sum(1 for r in routes if r["stops"])
    log["total_stops"] = sum(len(r["stops"]) for r in routes)
    log["multi_muni"] = [(r["ref"], r["name"], r["municipalities"], r["kmByMunicipality"]) for r in routes if len(r["municipalities"]) > 1]
    log["size_bytes"] = os.path.getsize(out_path)
    with open(os.path.join(BASE, "scripts", "build_log.json"), "w", encoding="utf-8") as fh:
        json.dump(log, fh, ensure_ascii=False, indent=1, default=str)
    print(json.dumps({k: v for k, v in log.items() if k not in ("osm_excluded",)}, ensure_ascii=False, indent=1, default=str))


main()
