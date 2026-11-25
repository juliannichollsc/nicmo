# Pendientes de Nicmo (al 2026-11-25)

Punto de partida para retomar. Los detalles están en los documentos enlazados.

## 1. Sin backend

- El 2026-11-25 se descartó el backend propio (`nicmo-back`, OSRM para trazar por calles). La app es totalmente independiente: planifica en el teléfono con los datos de `assets/cities/`, y los tramos a pie y en carro se dibujan en línea recta.
- Se quitaron `NicmoStreetRouter`, `env/api*.json`, `docs/rutas_calle_osrm.md` y la mención del servidor en los términos (versión 2026-11-25).

## 2. Mapbox (retirado)

- [ ] Revocar el token `pk.` en la cuenta de Mapbox (*Tokens* → eliminar): la app ya no lo usa. `env/mapbox.json`, las skills `.claude/skills/mapbox-*` y `skills-lock.json` se borraron el 2026-10-21.

## 3. Rutas de bus faltantes

Detalle en `docs/rutas_buses_valle_aburra_2026.md`.

- [ ] Reintentar `sim.metropol.gov.co`: POT de Bello y demás municipios. Respondía 503.
- [ ] Pedir al Municipio de Sabaneta autorización para usar su capa `MovilidadPublica`.
- [ ] Hacer un derecho de petición al AMVA por la capa de rutas metropolitanas o un GTFS abierto.
- [ ] Pedir las resoluciones de rutas a las Secretarías de Movilidad de Bello, Envigado, Sabaneta y Copacabana.
- [ ] Confirmar con la Alcaldía de Itagüí la licencia de su capa de rutas metropolitanas (74 rutas en la app).
- Faltan el norte del valle (Bello, Copacabana, Girardota, Barbosa) y las rutas internas de Envigado y Sabaneta.

## 4. App

- [ ] **Modo oscuro:** unos 14 de los 17 colores de bus quedan por debajo de 3:1 de contraste sobre el mapa oscuro (por ejemplo, `#283593` a 1,8:1). Hay que aclararlos en `lineColor` (`lib/widget/transit/transit_style.dart`) igual que ya se oscurecen en el tema claro.
- [ ] **Términos:** poner el correo de contacto en `kPrivacyContactEmail` (`lib/screens/legal/terms_content.dart`), que lo exige la Ley 1581. Que un abogado revise el texto y diga si hace falta una «política de tratamiento de datos» aparte.
- [ ] **Más ciudades:** al tener sus datos, poner `kMultiCityEnabled = true` en `lib/app_info.dart` (ver `docs/escalabilidad_ciudades.md`).
- Login, registro, verificación y la vista de perfil se eliminaron el 2026-10-21 (también `image_picker` y los permisos de cámara, micrófono y fotos): la intro lleva directo al mapa.

## 5. Para retomar con Claude Code

- `CLAUDE.md` (raíz) describe el proyecto, las reglas y las herramientas.
- Verificación: `flutter analyze`, `flutter test` (73 pruebas) y `flutter build web`.
