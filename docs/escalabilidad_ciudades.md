# Nicmo por ciudades: escalabilidad, peso y sostenimiento

Nicmo deja de ser una app solo de Medellín. Cada persona elige su ciudad al
final de la introducción. La app guarda únicamente el mapa y las rutas de las
ciudades que la persona activó. Una persona que viaja a Bogotá no ve las líneas
del Metro de Medellín, ni el celular le guarda datos que no usa.

## 1. Qué ve la persona (UX)

| Momento | Comportamiento |
|---|---|
| Introducción | Después de las 3 diapositivas viene un 4.º paso: **«¿En qué ciudad te vas a mover?»**. Las tarjetas aparecen en cascada, con las ciudades con rutas primero. «Comenzar» queda deshabilitado hasta elegir una ciudad, y «Saltar» lleva a este paso sin saltarlo. |
| Sidebar | El encabezado muestra un **chip con la ciudad actual** que dice «Cambiar ciudad», y hay un ítem **«Ciudades»**. El menú nunca lista las ciudades, para que no colapse cuando haya muchas. |
| Pantalla «Ciudades» (`/cities`) | Muestra una tarjeta grande con la ciudad actual: sus líneas y el peso de su mapa sin conexión. El escudo de la ciudad **vuela (Hero) desde el chip del sidebar**. Debajo están «Tus ciudades» (activas, con **Ir** y **Quitar**) y «Más ciudades», con buscador por nombre, municipio o sistema (p. ej. «transmilenio») y el botón **Agregar**. |
| Cambiar de ciudad | La cámara **vuela** a la otra ciudad: se aleja para ver ambos puntos, viaja y vuelve a acercarse, en vez de cruzar el país a nivel de calle. Aparece una píldora **«Ahora en X»**. El viaje, los filtros y la red anterior se descartan. |
| Ciudad «Próximamente» | Tiene mapa y búsqueda de lugares acotada a la ciudad. Un aviso explica que las rutas están en preparación. |
| Quitar ciudad | Un diálogo muestra cuánto espacio se libera; después se borra su mapa del disco. |
| Metro vs. buses | Se ven separados en el sidebar, en el filtro del mapa y en la lista de líneas. **Sistema Metro**: metro, tranvía y cable. **Buses**: Metroplús, rutas integradas y buses urbanos. |

Si alguien ya había pasado la introducción en una versión anterior, conserva
Medellín sin que se le pregunte de nuevo.

### Estrategia de lanzamiento: solo Medellín / Valle de Aburrá

`kMultiCityEnabled = false` en `lib/app_info.dart`:
- La introducción muestra solo Medellín, ya marcada, con el texto «Por ahora Nicmo cubre Medellín y todo el Valle de Aburrá».
- El sidebar oculta el chip de ciudad y el ítem «Ciudades», y su subtítulo vuelve a «Muévete por el Valle de Aburrá».
- La pantalla `/cities` sigue existiendo, pero no hay forma de llegar a ella.

Internamente nada cambia: Medellín es la ciudad `medellin`, que cubre los 10 municipios del valle, y la caché, las capas y el planificador siguen funcionando por ciudad. Para abrir más ciudades basta poner la bandera en `true`.

## 2. Arquitectura implementada

```
assets/cities/
  cities.json              catálogo: id, nombre, región, estado, centro,
                           zoom, límites, municipios, sistemas, créditos, capas
  medellin/
    metro.json     7 KB    metro, tranvía, cables y sus estaciones
    buses.json   160 KB    Metroplús, línea O y rutas integradas (AL-*)
    urban.json   342 KB    buses urbanos de Medellín (BU-*) y rutas
                           metropolitanas del AMVA (BU-AMVA-*)
```

| Pieza | Archivo | Responsabilidad |
|---|---|---|
| Dominio | `lib/domain/city/city.dart` | `City`, `CityBounds`, `CityLayer` y `CityCatalog` (incluye `at(posición)`). |
| Red por capas | `TransitNetwork.fromLayers` | Une las capas de la ciudad. Las estaciones se comparten por id y sus líneas se derivan de las líneas, así una capa nunca depende de otra. |
| Repositorio | `lib/infrastructure/transit/city_transit_network_repository.dart` | Carga solo las capas de la ciudad actual; el JSON se decodifica en un isolate (`compute`). Mantiene **una sola ciudad en memoria**. |
| Estado | `lib/state/city_state.dart` (`CityController`) | Guarda la ciudad actual y las activas (SharedPreferences). Actualiza el área de búsqueda y el área de la caché del mapa. |
| Caché del mapa | `offline_vector_tiles.dart`, `tile_bytes_store_io.dart` | Guarda las teselas en `vector_tiles/<ciudad>/`. Una tesela fuera de las ciudades activas se muestra pero no se guarda. Hay un tope por ciudad (~120 MB) y `clearArea` borra el mapa de una ciudad. Las teselas de versiones anteriores se migran a su ciudad. |
| Búsqueda | `search_area.dart` | Nominatim usa el `viewbox` de la ciudad actual, y las direcciones usan sus municipios. |
| Planificador | `multimodal_trip_planner.dart` | Los buses de calle (rutas integradas y urbanas) recogen y dejan pasajeros en cualquier punto. Las variantes de una misma ruta cuentan como una sola alternativa. Siempre ofrece la mejor opción solo por troncales (metro, tranvía, cable y Metroplús), si es razonable. |

Para **agregar una ciudad**:
1. Generar sus capas, por ejemplo desde GTFS u OSM, con `tool/city_layers.py`.
2. Añadir su carpeta a `pubspec.yaml`.
3. Cambiar `status` a `available` en `cities.json`.

No hace falta tocar código de la app.

## 3. Peso

| Concepto | Antes | Ahora |
|---|---|---|
| Red de Medellín (en el APK) | 154 KB, un solo archivo | Metro + buses 167 KB en total. Las geometrías van como *encoded polyline*, que es ~60 % más liviano. A esto se suman **196 buses urbanos y 56 rutas integradas con trazado oficial**, que antes no existían o eran aproximadas: 295 KB más. |
| Red comprimida en el paquete | — | Unos 130 KB con gzip (el APK comprime los assets). |
| Caché de mapa | Sin tope por ciudad; guardaba cualquier lugar visitado | Solo ciudades activas, ~120 MB máximo por ciudad, y se libera al quitar la ciudad. |
| Memoria | Toda la red, siempre | Solo la ciudad actual. |

## 4. Propuesta para crecer (siguientes pasos)

1. **Paquetes de ciudad descargables.** Medellín puede seguir dentro del APK, pero cada ciudad nueva debería ser un paquete versionado en un CDN:
   - Un `manifest.json` con `{city, version, sha256, bytes, layers[]}`.
   - El paquete se descarga al «Agregar» la ciudad y se guarda en el directorio de soporte de la app.
   - Así el APK no crece con cada ciudad.
   - El punto de enganche ya existe: `CityLayer.asset` pasaría a ser una URL, con un `RemoteCityDataSource` que cachee en disco.
2. **GTFS como formato de entrada estándar.**
   - Bogotá (TransMilenio/SITP), Cali (MIO), Barranquilla (Transmetro) y Bucaramanga (Metrolínea) publican o han publicado GTFS.
   - Un único importador GTFS → capas reemplazaría los scripts por ciudad.
   - Además aporta **frecuencias reales**: hoy los buses urbanos suponen 10 min.
3. **Actualización de datos sin publicar la app.** El manifest puede comprobarse cada 30 días, igual que el estilo del mapa, y descargar solo las capas que cambiaron.
4. **Recortar más peso si hace falta.**
   - Quitar los paraderos de los buses urbanos del paquete base y descargarlos aparte: hoy son la mitad de `urban.json`.
   - Bajar la precisión de la polilínea a 1e-5 en tramos rectos.
5. **Sugerir la ciudad por ubicación.** `CityCatalog.at(posición)` ya existe. Se puede sugerir la ciudad en la introducción cuando hay permiso de ubicación, sin pedir el permiso solo para eso.
6. **Sostenimiento.**
   - Reconstruir los datos cada trimestre con los scripts de `tool/`; la fuente y la fecha quedan en cada capa.
   - Agregar una prueba de CI que valide cada capa: estaciones existentes, sin huecos mayores a 300 m y un tamaño máximo por ciudad.

## 5. Herramientas de datos

| Script | Uso |
|---|---|
| `tool/city_layers.py` | Lee y escribe las capas de una ciudad, y codifica y decodifica polilíneas. |
| `tool/import_metro_open_data.py <carpeta>` | Datos abiertos del Metro de Medellín: rutas alimentadoras y GTFS de la línea O. Escribe en la capa `buses`. |
| `tool/build_bus_routes.py <dir>` | Arma `bus_routes.json` desde la capa oficial de Medellín y OSM. Ver `docs/rutas_buses_valle_aburra_2026.md`. |
| `tool/build_metropolitan_routes.py <geojson> <munis> <out>` | Rutas metropolitanas desde el geoportal de Itagüí; nombra por terminales las que no tienen nombre. |
| `tool/import_urban_buses.py <bus_routes.json> [<metropolitan_routes.json>]` | Escribe la capa `urban` y mejora las rutas integradas de `buses` con su trazado oficial. |
