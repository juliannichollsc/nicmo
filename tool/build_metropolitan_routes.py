"""Builds metropolitan_routes.json: bus routes regulated by the Área
Metropolitana del Valle de Aburrá (AMVA) that link Medellín with Itagüí,
La Estrella, Sabaneta, Caldas and Envigado.

Source: Municipio de Itagüí, POT geoportal, layer "Rutas de transporte
metropolitano" (84 polylines, only field "nombre" = route code):
  https://arcgis.itagui.gov.co/waserver/rest/services/Diagnostico/
  03_Dimension_Funcional/MapServer/26
Download it first (WGS84 GeoJSON):
  curl -o routes.geojson '<layer>/query?where=1%3D1&outFields=*&outSR=4326&f=geojson'
Municipal boundaries (GeoJSON polygon per municipality, from OSM) give the
municipalities each route crosses.

  python3 -I tool/build_metropolitan_routes.py routes.geojson munis.json out.json

* Route names: Cuenca 4 routes (40NN) take the name the operator publishes
  for T4-0NN (solobus.com.co). The other codes have no published name: they
  are named after their real terminals (barrio and municipality at both ends
  of the official path, Nominatim reverse geocoding, cached next to out.json).
* Seven-digit codes (4001000...) are skipped: 0.6-4 km pieces that do not
  overlap the route of the same number and whose meaning is undocumented.
* Closed paths (out and back) are cut at the point farthest from the start:
  one direction is kept, like for the other routes.
"""

import json
import math
import os
import sys
import time
import urllib.parse
import urllib.request

LAYER = (
    "https://arcgis.itagui.gov.co/waserver/rest/services/Diagnostico/"
    "03_Dimension_Funcional/MapServer/26"
)
OPERATOR_NAMES = {
    "4001": "Prado – Descanso",
    "4002": "Prado – Limonar",
    "4004": "San Francisco – Éxito – Punto Clave",
    "4005": "San Francisco – Directo",
    "4006": "San Francisco – Minorista",
    "4007": "Estrella 7ª – Éxito",
    "4008": "Estrella 3ª – Éxito",
    "4010": "Séptima – Carmelo – Éxito",
    "4013": "Calatrava – Éxito",
    "4014": "Calatrava – Minorista",
    "4016": "Guayabal – Éxito",
    "4017": "Estrella 5ª – Éxito",
    "4018": "Estrella 3ª – Minorista",
    "4019": "Prado – Autopista",
    "4020": "Estrella – Autopista – Minorista",
    "4025": "Terminal Sur – Éxito",
    "4026": "Porvenir – Trinidad – Minorista",
    "4027": "Rodeo Alto – La 65",
}
ORDER = [
    "Medellín", "Envigado", "Sabaneta", "Itagüí", "Bello", "Copacabana",
    "La Estrella", "Caldas", "Girardota", "Barbosa",
]


def metres(a, b):
    dlat = (a[0] - b[0]) * 110_574
    dlng = (a[1] - b[1]) * 111_320 * math.cos(math.radians((a[0] + b[0]) / 2))
    return math.hypot(dlat, dlng)


def simplify(points, tolerance=10.0):
    if len(points) < 3:
        return points
    lat0 = math.radians(points[0][0])
    xy = [(p[1] * 111_320 * math.cos(lat0), p[0] * 110_574) for p in points]
    keep = [False] * len(points)
    keep[0] = keep[-1] = True
    stack = [(0, len(points) - 1)]
    while stack:
        s, e = stack.pop()
        (ax, ay), (bx, by) = xy[s], xy[e]
        dx, dy = bx - ax, by - ay
        l2 = dx * dx + dy * dy
        best, index = -1.0, -1
        for i in range(s + 1, e):
            px, py = xy[i]
            t = 0 if l2 == 0 else max(0, min(1, ((px - ax) * dx + (py - ay) * dy) / l2))
            d = math.hypot(px - ax - t * dx, py - ay - t * dy)
            if d > best:
                best, index = d, i
        if best > tolerance:
            keep[index] = True
            stack += [(s, index), (index, e)]
    return [p for p, k in zip(points, keep) if k]


def inside(point, polygon):
    def in_ring(ring):
        x, y, result = point[1], point[0], False
        for i in range(len(ring)):
            (x1, y1), (x2, y2) = ring[i - 1][:2], ring[i][:2]
            if (y1 > y) != (y2 > y) and x < (x2 - x1) * (y - y1) / (y2 - y1) + x1:
                result = not result
        return result

    polygons = (
        [polygon["coordinates"]]
        if polygon["type"] == "Polygon"
        else polygon["coordinates"]
    )
    return any(
        in_ring(p[0]) and not any(in_ring(h) for h in p[1:]) for p in polygons
    )


def municipality(point, munis):
    for name in ORDER:
        if name in munis and inside(point, munis[name]):
            return name
    return None


def municipalities_along(points, munis):
    """Municipalities crossed for at least ~150 m, in order."""
    seen, run, last = [], 0.0, None
    for a, b in zip(points, points[1:]):
        m = municipality(a, munis)
        run = run + metres(a, b) if m == last else metres(a, b)
        last = m
        if m and run >= 150 and m not in seen:
            seen.append(m)
    return seen


class Reverse:
    """Nominatim reverse geocoding (1 request/second), cached on disk."""

    def __init__(self, path):
        self.path = path
        self.cache = json.load(open(path)) if os.path.exists(path) else {}

    def place(self, point):
        key = f"{point[0]:.4f},{point[1]:.4f}"
        if key not in self.cache:
            query = urllib.parse.urlencode({
                "lat": point[0], "lon": point[1], "format": "jsonv2",
                "zoom": 16, "accept-language": "es",
            })
            request = urllib.request.Request(
                f"https://nominatim.openstreetmap.org/reverse?{query}",
                headers={"User-Agent": "Nicmo data tools (route terminals)"},
            )
            time.sleep(1.1)
            with urllib.request.urlopen(request, timeout=20) as response:
                address = json.load(response).get("address", {})
            self.cache[key] = address
            json.dump(self.cache, open(self.path, "w"), ensure_ascii=False)
        address = self.cache[key]
        return (
            address.get("neighbourhood")
            or address.get("suburb")
            or address.get("quarter")
            or address.get("village")
            or address.get("road")
            or ""
        )


def main(source, munis_path, out):
    features = json.load(open(source, encoding="utf-8"))["features"]
    munis = json.load(open(munis_path, encoding="utf-8"))
    reverse = Reverse(os.path.join(os.path.dirname(os.path.abspath(out)),
                                   "terminals_cache.json"))
    routes = []
    skipped = []
    for feature in features:
        code = str(feature["properties"]["nombre"]).strip()
        if len(code) == 7:
            skipped.append(code)
            continue
        geometry = feature["geometry"]
        lines = (
            [geometry["coordinates"]]
            if geometry["type"] == "LineString"
            else geometry["coordinates"]
        )
        points = [(c[1], c[0]) for line in lines for c in line]
        flags = []
        if metres(points[0], points[-1]) < 100:
            far = max(range(len(points)), key=lambda i: metres(points[0], points[i]))
            one_way = points[: far + 1]
            flags.append("roundTripCutAtFarthestPoint")
        else:
            one_way = points
        shape = [[round(p[0], 5), round(p[1], 5)] for p in simplify(one_way)]
        start, end = shape[0], shape[-1]
        start_muni = municipality(start, munis) or ""
        end_muni = municipality(end, munis) or ""
        if code in OPERATOR_NAMES:
            name = OPERATOR_NAMES[code]
            flags.append("nameFromOperator(solobus.com.co)")
        else:
            def label(point, muni):
                place = reverse.place(point)
                if place and muni and muni not in place:
                    return f"{place} ({muni})"
                return place or muni or "?"

            name = f"{label(start, start_muni)} – {label(end, end_muni)}"
            flags.append("nameFromTerminals")
        parts = [p.strip() for p in name.split("–")]
        routes.append({
            "id": f"AMVA-{code}",
            "ref": code,
            "name": name,
            "from": parts[0],
            "to": parts[-1],
            "municipalities": municipalities_along(points, munis),
            "source": f"itagui-pot:MapServer/26:nombre={code}",
            "shape": shape,
            "stops": [],
            "lengthKm": round(
                sum(metres(a, b) for a, b in zip(shape, shape[1:])) / 1000, 2
            ),
            "integratedWithMetro": False,
            "category": "Metropolitana",
            "regulator": "Área Metropolitana del Valle de Aburrá",
            "qaFlags": flags,
        })
    json.dump(
        {
            "generated": time.strftime("%Y-%m-%d"),
            "sources": [{
                "name": "Municipio de Itagüí, geoportal POT: Rutas de transporte metropolitano",
                "url": LAYER,
                "license": "Información pública (Ley 1712 de 2014); sin licencia abierta explícita",
            }],
            "routes": routes,
        },
        open(out, "w", encoding="utf-8"),
        ensure_ascii=False,
    )
    print(f"{len(routes)} routes, skipped {len(skipped)} seven-digit codes")


if __name__ == "__main__":
    main(*sys.argv[1:4])
