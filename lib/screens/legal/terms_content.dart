import 'package:flutter/material.dart';

/// Version of the terms shown in the app; bump the date with any change.
const String kTermsVersion = '2026-11-25';

/// Contact for privacy requests (Ley 1581 de 2012). Empty until the owner
/// sets one; the contact paragraph is hidden meanwhile.
const String kPrivacyContactEmail = '';

class TermsHighlight {
  final IconData icon;
  final String text;

  const TermsHighlight(this.icon, this.text);
}

class TermsSection {
  final String title;
  final List<String> paragraphs;

  const TermsSection(this.title, this.paragraphs);
}

class TermsContent {
  final List<TermsHighlight> highlights;
  final List<TermsSection> sections;

  /// "Write to {email} to know, update, correct or delete your data."
  final String Function(String email) contact;

  const TermsContent({
    required this.highlights,
    required this.sections,
    required this.contact,
  });

  /// Spanish (Colombian law governs) and English; other languages read the
  /// English version.
  static TermsContent of(Locale locale) =>
      locale.languageCode == 'es' ? _es : _en;
}

const _es = TermsContent(
  highlights: [
    TermsHighlight(
      Icons.explore_outlined,
      'Nicmo es una guía: sugiere rutas, no presta el servicio de transporte.',
    ),
    TermsHighlight(
      Icons.public_rounded,
      'Las rutas vienen de fuentes públicas y accesibles a cualquier persona.',
    ),
    TermsHighlight(
      Icons.lock_outline_rounded,
      'No pedimos cuenta ni registro, y no vendemos tus datos.',
    ),
    TermsHighlight(
      Icons.code_rounded,
      'Nicmo es de código abierto y no muestra anuncios.',
    ),
  ],
  sections: [
    TermsSection('1. Aceptación', [
      'Al usar Nicmo aceptas estos términos. Si no estás de acuerdo, no uses la aplicación.',
    ]),
    TermsSection('2. Qué es Nicmo', [
      'Nicmo es una herramienta informativa que sugiere combinaciones de transporte público (metro, tranvía, cables, buses y caminatas) entre dos puntos. Es una guía de orientación.',
      'Nicmo no es un operador de transporte, no vende pasajes y no está afiliado ni representa al Metro de Medellín, al Área Metropolitana del Valle de Aburrá, a las alcaldías ni a las empresas de transporte. Sus nombres se usan solo para identificar los servicios.',
    ]),
    TermsSection('3. De dónde salen las rutas', [
      'Las rutas, estaciones y paraderos se toman únicamente de información publicada y accesible al público: datos abiertos del Metro de Medellín y de la Alcaldía de Medellín (licencia CC BY-SA 4.0), el geoportal público del Municipio de Itagüí y OpenStreetMap (licencia ODbL). No usamos bases de datos privadas, de acceso restringido ni de aplicaciones de terceros.',
      'Esa información puede estar incompleta o desactualizada: las rutas cambian por obras, desvíos o decisiones de las autoridades. Los tiempos de viaje y las frecuencias son estimaciones (los tiempos en carro no tienen en cuenta el tráfico), y algunos recorridos se marcan como aproximados.',
    ]),
    TermsSection('4. Las recomendaciones son orientativas', [
      'Antes de abordar, confirma la ruta en el letrero del vehículo, en el paradero o con el operador. Tú decides cómo y por dónde desplazarte.',
      'En la medida máxima que permite la ley colombiana, Nicmo y sus responsables no responden por retrasos, cambios de recorrido, cierres, tarifas, pérdidas de conexión, ni por daños derivados de decisiones tomadas con base en las recomendaciones.',
    ]),
    TermsSection('5. Tu seguridad y tu salud', [
      'Usa la aplicación con atención a tu entorno. No la manipules mientras conduces, cruzas la calle o subes y bajas de un vehículo.',
      'Nicmo no evalúa la seguridad de las zonas, el estado de las vías ni las condiciones de accesibilidad o de salud de cada persona. Elige las caminatas y los transbordos según tus capacidades.',
      'Nicmo no es un servicio de emergencias. Ante una emergencia llama a la línea 123.',
      'Los servicios de terceros que abres desde Nicmo (por ejemplo Uber, inDrive, WhatsApp o Google Maps) se rigen por sus propios términos y no están bajo nuestro control.',
    ]),
    TermsSection('6. Tus datos personales', [
      'Tratamos los datos conforme a la Ley 1581 de 2012 y el Decreto 1377 de 2013.',
      'Nicmo no pide registro ni inicio de sesión: no recolecta tu nombre, correo ni teléfono. No vendemos ni alquilamos datos, y solo los compartimos en los casos que se describen aquí o cuando una autoridad competente lo exija por ley.',
      'Ubicación: se usa en tu dispositivo para mostrarte en el mapa y planear rutas; solo se envía a otra persona cuando tú decides compartirla.',
      'Búsquedas y mapa: el texto que buscas y los puntos que eliges se consultan en OpenStreetMap (Nominatim), y el mapa se descarga de OpenFreeMap y OpenStreetMap. Esos servicios reciben solo la consulta técnica. Las rutas se calculan en tu teléfono: Nicmo no tiene servidor propio y no recibe tus búsquedas, tus puntos ni tus rutas.',
      'Preferencias, ciudades activas, viaje en curso y mapa sin conexión se guardan en tu dispositivo. Puedes borrarlos quitando una ciudad o eliminando los datos de la aplicación.',
      'Tienes derecho a conocer, actualizar, rectificar y suprimir tus datos, y a revocar tu autorización.',
    ]),
    TermsSection('7. Publicidad y notificaciones', [
      'Nicmo no muestra anuncios ni usa servicios de publicidad o de seguimiento.',
      'Nicmo no envía notificaciones promocionales. Si se incorporan, se actualizarán estos términos y se pedirá tu autorización expresa, que podrás retirar en cualquier momento.',
    ]),
    TermsSection('8. Propiedad intelectual y licencias', [
      'El código de Nicmo es abierto, bajo la licencia Apache 2.0 (github.com/juliannichollsc/nicmo). El nombre y la marca Nicmo pertenecen a sus responsables. Los datos de transporte conservan las licencias y créditos de sus fuentes, que se muestran en el mapa y en la documentación del proyecto.',
    ]),
    TermsSection('9. Cambios a estos términos', [
      'Podemos actualizar estos términos. La versión vigente siempre estará en la aplicación con su fecha; si el cambio es importante, te lo avisaremos dentro de la app.',
    ]),
    TermsSection('10. Ley aplicable', [
      'Estos términos se rigen por las leyes de la República de Colombia, incluida la Ley 1480 de 2011 (Estatuto del Consumidor) en lo que aplique.',
    ]),
  ],
  contact: _contactEs,
);

String _contactEs(String email) =>
    'Para ejercer tus derechos sobre tus datos escribe a $email.';

const _en = TermsContent(
  highlights: [
    TermsHighlight(
      Icons.explore_outlined,
      'Nicmo is a guide: it suggests routes; it does not provide transport.',
    ),
    TermsHighlight(
      Icons.public_rounded,
      'Routes come from public sources that anyone can access.',
    ),
    TermsHighlight(
      Icons.lock_outline_rounded,
      'No account or sign-up, and we do not sell your data.',
    ),
    TermsHighlight(
      Icons.code_rounded,
      'Nicmo is open source and shows no ads.',
    ),
  ],
  sections: [
    TermsSection('1. Acceptance', [
      'By using Nicmo you accept these terms. If you do not agree, do not use the app.',
    ]),
    TermsSection('2. What Nicmo is', [
      'Nicmo is an information tool that suggests public transport combinations (metro, tram, cable cars, buses and walking) between two points. It is a guide.',
      'Nicmo is not a transport operator, does not sell tickets and is not affiliated with, nor represents, Metro de Medellín, the Área Metropolitana del Valle de Aburrá, city halls or transport companies. Their names are used only to identify the services.',
    ]),
    TermsSection('3. Where routes come from', [
      'Routes, stations and stops are taken only from information published and accessible to the public: open data of Metro de Medellín and the Alcaldía de Medellín (CC BY-SA 4.0), the public geoportal of the Municipio de Itagüí and OpenStreetMap (ODbL). We do not use private or restricted databases, nor data from third-party apps.',
      'That information may be incomplete or out of date: routes change due to works, detours or decisions of the authorities. Travel times and frequencies are estimates (car times do not account for traffic), and some paths are flagged as approximate.',
    ]),
    TermsSection('4. Recommendations are guidance', [
      'Before boarding, check the route on the vehicle sign, at the stop or with the operator. You decide how and where to travel.',
      'To the fullest extent allowed by Colombian law, Nicmo and its owners are not liable for delays, route changes, closures, fares, missed connections, or damages arising from decisions based on its recommendations.',
    ]),
    TermsSection('5. Your safety and health', [
      'Use the app paying attention to your surroundings. Do not handle it while driving, crossing the street or getting on and off a vehicle.',
      'Nicmo does not assess the safety of areas, the state of roads, nor the accessibility or health conditions of each person. Choose walks and transfers according to your abilities.',
      'Nicmo is not an emergency service. In an emergency call 123.',
      'Third-party services opened from Nicmo (such as Uber, inDrive, WhatsApp or Google Maps) follow their own terms and are not under our control.',
    ]),
    TermsSection('6. Your personal data', [
      'We process data under Colombian Law 1581 of 2012 and Decree 1377 of 2013.',
      'Nicmo asks for no sign-up or login: it does not collect your name, email or phone. We do not sell or rent data, and we share it only in the cases described here or when a competent authority requires it by law.',
      'Location is used on your device to show you on the map and plan routes; it is sent to someone else only when you choose to share it.',
      'Searches and map: the text you search and the points you pick are looked up on OpenStreetMap (Nominatim), and the map is downloaded from OpenFreeMap and OpenStreetMap. Those services receive only the technical request. Routes are planned on your phone: Nicmo has no server of its own and does not receive your searches, points or routes.',
      'Preferences, active cities, the trip in progress and the offline map are stored on your device. You can delete them by removing a city or clearing the app data.',
      'You have the right to know, update, correct and delete your data, and to revoke your authorisation.',
    ]),
    TermsSection('7. Advertising and notifications', [
      'Nicmo shows no ads and uses no advertising or tracking services.',
      'Nicmo sends no promotional notifications. If they are added, these terms will be updated and your express authorisation will be requested; you can withdraw it at any time.',
    ]),
    TermsSection('8. Intellectual property and licences', [
      'Nicmo\'s code is open source under the Apache 2.0 licence (github.com/juliannichollsc/nicmo). The Nicmo name and brand belong to its owners. Transport data keeps the licences and credits of its sources, shown on the map and in the project documentation.',
    ]),
    TermsSection('9. Changes to these terms', [
      'We may update these terms. The current version, with its date, is always available in the app; important changes will be announced in the app.',
    ]),
    TermsSection('10. Governing law', [
      'These terms are governed by the laws of the Republic of Colombia, including Law 1480 of 2011 (Consumer Statute) where applicable.',
    ]),
  ],
  contact: _contactEn,
);

String _contactEn(String email) =>
    'To exercise your rights over your data, write to $email.';
