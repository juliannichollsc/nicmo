# Rutas de bus del Valle de Aburrá: investigación (octubre de 2026)

Objetivo: tener en Nicmo las rutas de bus **reales** que tocan Medellín,
Envigado, Sabaneta, Itagüí, Copacabana y Bello, sin inventar rutas. Cada ruta
viene de una fuente verificable.

## Resultado en la app

| Capa | Contenido | Fuente |
|---|---|---|
| `metro.json` | Metro (A, B), tranvía TA y cables (H, J, K, L, M, P) | Metro de Medellín, OSM |
| `buses.json` | Metroplús (1, 2), línea O y **136 rutas integradas** (`AL-*`); 30 de ellas aún sin trazado (aproximadas, no se dibujan) | Datos abiertos del Metro y capa oficial de Medellín |
| `urban.json` | **196 rutas de bus urbano** (`BU-*`) de más de 30 empresas, con sus paraderos | Secretaría de Movilidad de Medellín |

- **56 rutas integradas** («254i», «C23i», «261i Der»…) ahora tienen su **trazado oficial**. Reemplazan a 16 rutas aproximadas que antes no se podían dibujar.
- Las rutas de más de 40 km (98 Directa 1/2/5/6/7/9, 255P y 305) traen ramales de ida y vuelta en la geometría oficial. Se dibujan, pero quedan marcadas como aproximadas, y el planificador las usa solo si son claramente mejores.
- No se publican frecuencias: se suponen 10 min por ruta. Por eso el planificador siempre ofrece también la mejor opción solo por troncales (metro, tranvía, cable y Metroplús).

## Criterio

Solo se usan rutas **publicadas y accesibles al público**. Las fuentes privadas o que exigen permiso del publicador (por ejemplo el conjunto de rutas de Envigado en datos.gov.co, `5kmz-anpe`, que responde «permission_denied» incluso con sesión iniciada) quedan fuera.

## Rutas metropolitanas (segunda ronda)

- **Fuente:** geoportal del POT del Municipio de Itagüí, capa «Rutas de transporte metropolitano»: <https://arcgis.itagui.gov.co/waserver/rest/services/Diagnostico/03_Dimension_Funcional/MapServer/26> (idéntica a `Formulacion/04_Componente_General/MapServer/9`). Tiene 84 polilíneas y su único atributo es el código.
- **Licencia:** es información pública (Ley 1712 de 2014), pero no declara una licencia abierta. Conviene confirmar con la Alcaldía de Itagüí antes de redistribuir los datos fuera de la app.
- **Importadas:** **74 rutas**. Por municipio, pasan por Itagüí 55, Medellín 50, La Estrella 42, Sabaneta 37, Caldas 26 y Envigado 22.
- **Excluidas:** las 10 de código de 7 dígitos (4001000…). Son tramos de 0,6 a 4 km que no coinciden con la ruta del mismo número y cuyo significado no está documentado.
- **Nombres:**
  - Las rutas de la Cuenca 4 (40NN) usan el nombre que publica el operador (T4-0NN en solobus.com.co).
  - Los demás códigos no tienen nombre publicado: se nombran por sus **terminales reales**, es decir, el barrio y el municipio de cada extremo del recorrido oficial (Nominatim). Por ejemplo, 9101 «Troncal de Occidente (Caldas) – Estación Villa (Medellín)».
- **Recorridos de ida y vuelta:** los cerrados se cortan en el punto más lejano del inicio, igual que el resto: se guarda un sentido.
- **Siguen sin fuente abierta:** las rutas metropolitanas del norte (Bello, Copacabana, Girardota, Barbosa) y las municipales internas de Envigado, Bello y Sabaneta. El SIG de Envigado (`sig.envigado.gov.co`) respondía 502 el 2026-10-14.

## Fuentes

| Fuente | Estado | Licencia |
|---|---|---|
| Alcaldía de Medellín, Secretaría de Movilidad, «Rutas de Transporte Público»: <https://www.medellin.gov.co/servidormapas/rest/services/transporte/VM_Movilidad/MapServer/2>. 504 polilíneas (252 rutas × 2 sentidos), 33 empresas, actualizada el 2025-08-14. | ✅ Fuente principal | CC BY-SA 4.0 (metadato GeoMedellín 07926629-1e38-4d05-824a-392bb46562cb) |
| Paraderos, misma capa 0: 10.043 puntos de 2018, enlazados por `id_ruta` y sentido | ✅ | CC BY-SA 4.0 |
| OpenStreetMap, relaciones `route=bus` vía Overpass: solo 20 en todo el valle | ✅ Usado para validar. Sus 3 rutas vigentes ya existían como alimentadoras, así que no se duplicaron. | ODbL |
| Límites municipales OSM (`admin_level=6`) | ✅ Calcula por qué municipios pasa cada ruta (cuenta si recorre ≥ 150 m dentro) | ODbL |
| AMVA: ArcGIS `geografico.metropol.gov.co:6080` | ❌ Sin respuesta. Por HTTPS solo está el visor de la Encuesta Origen-Destino 2025. Verificado de nuevo el 2026-10-14. | — |
| AMVA: `datosabiertos.metropol.gov.co` | ❌ HTTP 502 (verificado de nuevo el 2026-10-14) | — |
| datos.gov.co, rutas de Envigado 2019 | ❌ Ahora exige autenticación | — |
| Moovit / Google | No usados: datos sin licencia abierta | — |

## Cobertura por municipio (honesta)

Rutas de bus convencional (capa `urban`, 270 rutas) que pasan **al menos 150 m** por cada municipio:

| Municipio | Rutas | Nota |
|---|---|---|
| Medellín | 246 | 196 urbanas + 50 metropolitanas |
| Itagüí | 57 | Rutas metropolitanas (Cuenca 4 y otras) |
| Copacabana | 2 | 98 Directa 6 y 9, vía Piedras Blancas |
| La Estrella | 42 | Rutas metropolitanas |
| Sabaneta | 37 | Rutas metropolitanas |
| Caldas | 26 | Rutas metropolitanas (91xx, 92xx, 93xx, 99xxx) |
| Envigado | 22 | Rutas metropolitanas que la cruzan; faltan las internas |
| Bello | 0 | Sin fuente abierta (ver «Brechas») |

Las rutas integradas del Metro sí llegan a esos municipios: Niquía y Bello
(C1), Envigado (64xx), Itagüí (54xx, 74xx), Sabaneta y Copacabana (C7). Esas ya
estaban en la capa `buses`.

## Tercera ronda: norte del valle, Envigado y Sabaneta (2026-10-14)

| Fuente | Resultado |
|---|---|
| AMVA, Sistema de Información Metropolitano: `https://sim.metropol.gov.co/arcgis/rest/services` (incluye `Planes_Ordenamiento_Territorial/POT_Bello`) | ⏳ HTTP 503 «temporalmente fuera de servicio» durante toda la sesión, y no hay copia en Wayback. **Es la fuente más prometedora** para Bello, Copacabana y Girardota: volver a consultarla. |
| Municipio de Sabaneta, ArcGIS Online `MovilidadPublica` (paraderos, ciclorrutas) | 🚫 Es pública, pero su licencia dice «Información que puede ser utilizada por las entidades u organizaciones que autorice el Municipio de Sabaneta». Excluida hasta tener autorización. Además no tiene recorridos. |
| datos.gov.co, rutas de Envigado (`5kmz-anpe`) | 🚫 Privada (permission_denied con sesión iniciada). |
| SIG de Envigado (`sig.envigado.gov.co`) | ❌ HTTP 502. |
| Portal de datos abiertos del AMVA (Wayback, etiqueta «metropolitanos») | ❌ Solo publicó accidentalidad y ciclorrutas, nunca rutas. |
| Gobernación de Antioquia (hub de datos abiertos y servicio «Transporte») | ❌ Solo hay encuestas de parque automotor; no hay recorridos. |
| ArcGIS Online (búsqueda por municipio) | ❌ Hay trabajos de estudiantes de EAFIT con estaciones del SITVA y la malla vial, pero no rutas. |
| Alcaldía de Medellín, `VC_Infraest_Gestion_Transporte/9` «Rutas Unificadas» | Son las mismas 252 rutas de Medellín ya incluidas. |
| OpenStreetMap: paraderos del valle | ❌ Ningún paradero tiene `route_ref`, así que tampoco hay códigos. |


- **Norte del valle:** no hay fuente abierta con geometría para las rutas metropolitanas de Bello, Copacabana, Girardota y Barbosa hacia Medellín, ni para las rutas internas de Bello.
- **Rutas internas de Envigado y Sabaneta:** el conjunto de Envigado en datos.gov.co es privado y el SIG municipal no responde, así que no se incluyen.
- **Nombres:** 56 rutas metropolitanas se nombran por sus terminales y no por un nombre oficial.
- **Fecha de los datos:** la capa de Itagüí es del diagnóstico del POT. Algunas rutas pudieron cambiar después.
- **Paraderos:** los de Medellín son de 2018, y las rutas metropolitanas no tienen paraderos publicados.

### Cómo cerrarlas

1. Reintentar `sim.metropol.gov.co` (POT de Bello y demás municipios) cuando vuelva a responder.
2. Pedir al Municipio de Sabaneta autorización para usar su capa `MovilidadPublica`.
3. Pedir al AMVA, por **derecho de petición**, la capa de rutas metropolitanas o un GTFS con licencia abierta, y volver a revisar `datosabiertos.metropol.gov.co`.
4. Pedir las resoluciones de rutas a las Secretarías de Movilidad de Bello, Envigado, Itagüí, Sabaneta y Copacabana.
5. Mapear esas rutas en OpenStreetMap (PTv2: `ref`, `operator`, `from`, `to`) con trazas GPS propias. `build_bus_routes.py` ya las incorpora desde OSM.
6. Reconstruir cada trimestre con `tool/build_bus_routes.py` y `tool/import_urban_buses.py`. Antes, revisar `max(fecha_actualizacion)` en el MapServer.

## Cambios 2025–2026 encontrados en prensa

- **Tarifas desde el 10 de enero de 2026:**
  - Medellín: $3.800 en bus y $3.900 en microbús.
  - Rutas metropolitanas: entre $300 y $550 más.
  - Envigado: $3.600.
  - Bello: $2.900.
- **Bellanita (Bello–Medellín):** «ruta única» desde el 1 de octubre de 2025, a $3.450 (Telemedellín).
- **Ruta 178 Nuevo Amanecer (Cootrabel):** piloto desde noviembre de 2025. En la capa oficial figura como «172-178 FUSION».
- **Julio de 2026:** las rutas C5-024 y C5-032 de Envigado se desviaron a Poblado e Industriales por un daño en la catenaria (El Colombiano).
- **17 de septiembre al 2 de octubre de 2026:** cierre de la Línea K del Metrocable, con apoyo de alimentadoras C6.

## Método (resumen)

- **Sentidos:** se deja un sentido por ruta, el más largo entre los completos. Las MultiLineString se unen; ninguna tenía huecos de más de 300 m.
- **Simplificación:** Douglas-Peucker con 10 m de tolerancia, guardada como *encoded polyline*.
- **Paraderos:** solo los que quedan a 50 m o menos del trazado.
- **Extremos de ruta:** un extremo a 450 m o menos de una estación se une a ella, así funcionan los transbordos. Los demás extremos son estaciones propias de la ruta.
- **Colores:** las rutas que pasan a menos de 300 m entre sí tienen colores distintos.
