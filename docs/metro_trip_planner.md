## Metro de Medellín trip planner

The app's main flow: the user enters an origin and a destination (address, place,
station, current location or a point picked on the map), presses *Find best
route* and gets the optimal
combination of Metro de Medellín services — metro, tranvía, metrocable and
integrated buses — plus alternatives.

### Data

- Per city, see `docs/escalabilidad_ciudades.md`: `assets/cities/cities.json`
  (catalog) and `assets/cities/<city>/{metro,buses,urban}.json` (layers,
  merged by `TransitNetwork.fromLayers`; geometry as encoded polylines).
  Each layer holds lines (id, name, mode, colour,
  average speed, headway, ordered station ids, optional geometry) and stations
  (id, name, lat/lng, lines). Interchange stations share one id across lines.
  Built from metrodemedellin.gov.co and OpenStreetMap (Overpass). Lines flagged
  `approximate: true` have estimated stop coordinates.
- Base map (no API key, `lib/widget/map/base_map_layer.dart`): standard
  OpenStreetMap raster tiles render from the first frame; OpenFreeMap vector
  tiles (`positron` / `dark` styles) fade in on top with label layers removed,
  so street names are hidden. The vector style is preloaded in `main()`.
  CARTO basemaps were dropped: they now require an API key. Note that
  tile.openstreetmap.org has a fair-use policy; for heavy production traffic
  use a self-hosted or commercial raster provider.
- Live location: `lib/state/location_state.dart` (`LocationController`, a
  geolocator position stream for Android, iOS and web; the web needs HTTPS or
  localhost).
- Place search (`lib/infrastructure/geocoding/`), in this order:
  1. Colombian addresses ("Cra. 43B # 1A Sur - 70", "Diagonal 54 # 17-100,
     Niquía"): `ColombianAddress` parses type, numbers, letters, "Sur",
     metres and barrio hints; `ColombianAddressGeocoder` fetches the primary
     street geometry from Nominatim, keeps the stretches matching the hints,
     fetches the crossing street around them (and per barrio when Nominatim's
     40-result page was full) and computes the corner (within 100 m = exact).
     When the corner is not in OpenStreetMap it returns the point of the
     primary street closest to the crossing street, flagged *approximate*.
  2. Metro stations (offline).
  3. Free-text Nominatim (places, barrios, landmarks).
  All Nominatim calls share one client with a 1 request/second queue and
  an in-memory cache (`NominatimClient`). Overpass was evaluated for corners
  but its public servers were unreliable.

### Layers

| Layer | Files |
|---|---|
| Domain | `lib/domain/transit/` — `TransitNetwork`, `Itinerary`/`ItineraryLeg`, service contracts (`TripPlanner`, `PlaceSearchService`, `TransitNetworkRepository`) |
| Infrastructure | `lib/infrastructure/transit/` (asset repository, `MultimodalTripPlanner`), `lib/infrastructure/geocoding/metro_place_search_service.dart` |
| State | `lib/state/trip_state.dart` — `TripController` (`ValueNotifier<TripState>`); `lib/state/location_state.dart` |
| UI | `lib/widget/map/metro_map.dart`, `lib/widget/trip/`, `lib/widget/transit/transit_style.dart`, `lib/screens/home/home.dart`, `lib/screens/trip/trip.dart` |

### Routing algorithm (`MultimodalTripPlanner`)

Graph nodes: one *street* node per station and one *on-board* node per
(line, station).

| Edge | Cost (minutes) |
|---|---|
| origin → station, station → destination (walk) | straight distance × 1.25 / 75 m/min, stations within 1.2 km (at least the 3 closest) |
| station ↔ nearby station (walk transfer) | same, stations within 450 m |
| street → on-board (board) | headway / 2 + boarding penalty (3) |
| street → on-board, approximate feeder route | + 5 extra (official lines win ties) |
| on-board → next station (ride) | segment length / line speed + 0.4 dwell |
| on-board → street (alight) | 0.5 |
| origin → destination (walk only) | if under 2.5 km |
| origin → street of a feeder bus → on board (roadside) | walk to the closest point of the route (≤ 600 m), then headway / 2 |
| on board (roadside) ↔ neighbouring listed stops / roadside point near the destination | distance along the route / speed |

Integrated feeder buses (`AL-*`) and conventional buses (`BU-*`) stop on request, so a trip can start or end
anywhere along their street: this is what produces real chains such as
walk → bus → metro → bus → walk. Metroplús, line O, metro, tram and cable
only stop at their stations. Each ride leg carries its `headsign`
(terminal in the direction of travel).

Dijkstra (binary heap) runs several times with different weights:
default, fewer transfers (boarding penalty 12), less walking (walk × 2.5), and
up to three runs penalising routes already proposed (+15 per boarding), and
one run on trunk lines only (metro, tram, cable, Metroplús). Results are
de-duplicated by route sequence (variants of one bus route, same code, count
once), sorted by real travel time, absurd ones (> 1.8 × best + 10 min)
dropped, and tagged *recommended*, *fewest transfers*, *least walking*. The
trunk-only trip takes the last slot when it is not already listed: bus
headways are estimated, trunk ones are known.

### Animations

- Route transitions: `lib/routes/transitions.dart` (shared-axis for auth,
  fade-through into the shell, slide-up for the trip screen, animated branch
  switching inside the shell).
- Map: animated camera flights, progressive route drawing, pulsing origin,
  dropping destination pin, vehicle marker moving along each leg.
- Assets in `assets/animations/` are generated by
  `python3 tool/generate_metro_animations.py` (Lottie JSON + GIF + the dark
  green background). Edit the script, not the generated files.
