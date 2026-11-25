# Nicmo (pub package `nicmo`)

Public-transport trip planner in Flutter, organised **by city**. Medellín
(Valle de Aburrá) has a network; Bogotá, Cali, Barranquilla, Cartagena,
Bucaramanga and Pereira are "coming soon" (map and place search only). The
user writes in Spanish; UI strings exist in es / en / de / zh.

The global `~/.claude/CLAUDE.md` describes an unrelated NestJS backend: its
agents, commands and conventions do not apply here.

Pending work and next steps: `docs/PENDIENTES.md`.

## Commands

- `flutter test` — all tests (VM). `flutter test test/polyline_test.dart --platform chrome` for code that must behave the same on the web (bitwise ops differ in JS).
- `flutter analyze` — must stay free of errors and warnings (old `withOpacity` infos are known).
- `flutter gen-l10n` — after editing `lib/il8n/app_*.arb` (template `app_en.arb`; placeholders declared there).
- `dart format lib test`.
- README screenshots on a connected phone: `flutter drive -d <device> --driver=test_driver/integration_test.dart --target=integration_test/screenshots_test.dart`. One run does en + es, light + dark, with three candidates (`_a/_b/_c`) per welcome screen; it writes full-size PNGs to `docs/screenshots/<lang>/`. The README uses only a curated 8 per language as 480 px JPEGs (es section → `es/`, every other language → `en/`). HyperOS asks to accept the USB install, and flutter uninstalls the app when the run ends.
- `flutter build web` — if it fails with "Couldn't resolve the package 'nichollsflut'", delete `.dart_tool/flutter_build` (stale cache from the old package name). Linux desktop builds need clang/cmake/ninja, which are not installed.
- UI check without a phone: serve `build/web` (`python3 -m http.server`) and drive `/usr/bin/google-chrome` headless at 390×844 (puppeteer-core), then read the screenshots.

## Architecture

| Layer | Where |
|---|---|
| Domain | `lib/domain/city/city.dart` (`City`, `CityBounds`, `CityCatalog`), `lib/domain/transit/` (`TransitNetwork.fromLayers`, `LineGroup`, `Itinerary`, service interfaces) |
| Infrastructure | `lib/infrastructure/transit/` (city network repository, `MultimodalTripPlanner`), `geocoding/` (Nominatim, Colombian addresses, `SearchArea`), `map/` (OpenFreeMap styles, offline tiles per city) |
| State | Global `ValueNotifier`s: `cityController` (`lib/state/city_state.dart`), `tripController`, `locationController`, map filters |
| UI | `lib/screens/*`, `lib/widget/*`; routes in `lib/routes/route.dart` (go_router, custom transitions in `transitions.dart`) |

- **Cities.** The catalog is `assets/cities/cities.json`. The network of a city lives in `assets/cities/<city>/{metro,buses,urban}.json`, one file per layer, with geometry as Google encoded polylines (`path`).
  - Only the current city's network is in memory.
  - Map tiles are saved only for active cities (`vector_tiles/<city>/`).
  - The city is chosen on the last onboarding step and managed from the **Ciudades** screen (`/cities`), which is opened from the side menu. The menu never lists cities.
- **Line groups.**
  - Metro system: `metro`, `tram`, `cable`.
  - Buses: `metroplus`, `feeder` (`AL-*`), `bus` (`BU-*`, conventional).
  - Street buses (`feeder`, `bus`) stop on request anywhere along their path (`stopsOnRequest`).
  - The planner treats variants with the same `code` as one alternative and always keeps the best trunk-only trip.
- `kMultiCityEnabled` (`lib/app_info.dart`) is **false**: launch strategy is Medellín / Valle de Aburrá only. The welcome step shows only Medellín, preselected; the side menu hides the city chip and the Ciudades item. Keep the multi-city code working behind the flag.
- Do not show bus operators/companies (the user considers it unnecessary).
- Only routes **published and accessible to the public** are used; private or permission-gated datasets are excluded even if the user can log in.
- No accounts and no profile: login, sign-up, verification and the profile screen were removed (with `image_picker` and the camera / photo / microphone permissions); the welcome steps go straight to the map (`/home`). The shell has two branches: map and settings.
- Terms and conditions: `lib/screens/legal/` (`/terms`, linked from the welcome city step and from Settings). Content in `terms_content.dart` (es + en; other languages show en). Bump `kTermsVersion` on any change. `kPrivacyContactEmail` is empty until the owner provides one (the contact line is hidden meanwhile). There is no account data and no own server; searches go to Nominatim and tiles to OpenFreeMap/OSM — keep the terms truthful if that changes (e.g. notifications or ads need opt-in and a terms update).

## No backend

- The app is fully client-side: routes are planned on the device from the bundled city assets. The planned Nicmo API (own OSRM to draw walking / car legs along the streets) was dropped on 2026-11-25; walking and car legs are drawn as straight lines and car time is the straight distance at `ItineraryLeg.carMetersPerMin`.
- Never store Mapbox or Google routing results (their terms forbid it).

## Data pipeline (`tool/`, Python 3, run with `-I`)

- `city_layers.py` — load/save a city's layers, polyline encode/decode.
- `import_metro_open_data.py <folder>` — Metro de Medellín open data (feeders, GTFS line O) → `buses` layer.
- `build_bus_routes.py <dir>` + `build_metropolitan_routes.py` + `import_urban_buses.py <bus_routes.json> [<metropolitan_routes.json>]` — Medellín Secretaría de Movilidad routes (ArcGIS `VM_Movilidad`) and AMVA metropolitan routes (Itagüí geoportal) → `urban` layer, plus official paths for integrated feeders.
- Sources, coverage gaps (north of the valley and municipal routes of Envigado/Bello/Sabaneta have no open source yet) and the scaling plan: `docs/rutas_buses_valle_aburra_2026.md`, `docs/escalabilidad_ciudades.md`, planner details in `docs/metro_trip_planner.md`.

## Conventions

- Comments explain why; match the surrounding density. Identifiers in English, user-facing text via l10n.
- Never invent transit routes: every line must come from a cited open source (Moovit/Google data is not allowed).
- Narrow phones (360 dp) and large text must not overflow: tests run at 360×780.
