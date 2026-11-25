// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get email => 'Correo electrónico';

  @override
  String get enterYourEmail => 'Ingresa tu correo';

  @override
  String get password => 'Contraseña';

  @override
  String get enterYourPassword => 'Ingresa tu contraseña';

  @override
  String get forgotPassword => '¿Olvidaste tu contraseña?';

  @override
  String get login => 'Iniciar sesión';

  @override
  String get dontHaveAccountSignUp => '¿No tienes cuenta? Regístrate';

  @override
  String get name => 'Nombre';

  @override
  String get enterYourName => 'Ingresa tu nombre';

  @override
  String get lastName => 'Apellido';

  @override
  String get enterYourLastName => 'Ingresa tu apellido';

  @override
  String get phone => 'Teléfono';

  @override
  String get enterYourPhone => 'Ingresa tu teléfono';

  @override
  String get confirmPassword => 'Confirmar contraseña';

  @override
  String get enterYourConfirmPassword =>
      'Ingresa tu confirmación de contraseña';

  @override
  String get alreadyHaveAccountLogin => '¿Ya tienes cuenta? Inicia sesión';

  @override
  String get register => 'Registrarse';

  @override
  String get verifyYourEmail => 'Verifica tu correo';

  @override
  String get verificationCodeSent =>
      'Hemos enviado un código de verificación a tu correo';

  @override
  String get verify => 'Verificar';

  @override
  String get resendCode => 'Reenviar código';

  @override
  String get notificationsEnabled => 'Notificaciones activadas';

  @override
  String get notificationsDisabled => 'Notificaciones desactivadas';

  @override
  String get couldNotOpenLink => 'No se pudo abrir el enlace';

  @override
  String get appearance => 'Apariencia';

  @override
  String get darkMode => 'Modo oscuro';

  @override
  String get on => 'Activado';

  @override
  String get off => 'Desactivado';

  @override
  String get notifications => 'Notificaciones';

  @override
  String get pushNotifications => 'Notificaciones push';

  @override
  String get receiveAppAlerts => 'Recibir alertas de la app';

  @override
  String get general => 'General';

  @override
  String get language => 'Idioma';

  @override
  String get english => 'Inglés';

  @override
  String get spanish => 'Español';

  @override
  String get german => 'Alemán';

  @override
  String get mandarin => 'Chino mandarín';

  @override
  String get about => 'Acerca de';

  @override
  String get aboutVersion => 'Versión 1.0.0';

  @override
  String get linkedIn => 'LinkedIn';

  @override
  String get julianNichollsC => 'Julian Nicholls C';

  @override
  String get menu => 'Menú';

  @override
  String get home => 'Inicio';

  @override
  String get settings => 'Configuración';

  @override
  String get profile => 'Perfil';

  @override
  String get map => 'Mapa';

  @override
  String get lightMode => 'Modo claro';

  @override
  String get darkModeMenu => 'Modo oscuro';

  @override
  String get selectFromGallery => 'Elegir de la galería';

  @override
  String get takeAPhoto => 'Tomar una foto';

  @override
  String get route => 'Hasta';

  @override
  String get start => 'Desde';

  @override
  String get travel => 'Navegar';

  @override
  String get metroTitle => 'Metro de Medellín';

  @override
  String get whereTo => '¿A dónde vas?';

  @override
  String get whereToHint => 'Escribe una dirección, lugar o estación';

  @override
  String get originHint => 'Punto de partida';

  @override
  String get destinationHint => 'Destino';

  @override
  String get myLocation => 'Mi ubicación';

  @override
  String get cancel => 'Cancelar';

  @override
  String get findRoutes => 'Buscar rutas';

  @override
  String get searchingRoutes => 'Buscando la mejor ruta…';

  @override
  String get noRoutes => 'No encontramos rutas para este viaje';

  @override
  String get routeError => 'Ocurrió un error al planear el viaje';

  @override
  String get locationUnavailable => 'Ubicación no disponible';

  @override
  String get startTrip => 'Comenzar viaje';

  @override
  String get recommended => 'Recomendada';

  @override
  String get fewestTransfers => 'Menos transbordos';

  @override
  String get leastWalking => 'Menos caminata';

  @override
  String get alternatives => 'Alternativas';

  @override
  String minutesShort(int minutes) {
    return '$minutes min';
  }

  @override
  String transfersCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count transbordos',
      one: '1 transbordo',
      zero: 'Directo',
    );
    return '$_temp0';
  }

  @override
  String walkDistance(int meters) {
    return '$meters m a pie';
  }

  @override
  String walkTo(String place) {
    return 'Camina hasta $place';
  }

  @override
  String boardTowards(String line, String terminal) {
    return 'Toma $line hacia $terminal';
  }

  @override
  String stopsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count paradas',
      one: '1 parada',
    );
    return '$_temp0';
  }

  @override
  String getOffAt(String station) {
    return 'Bájate en $station';
  }

  @override
  String waitAbout(int minutes) {
    return 'Espera ~$minutes min';
  }

  @override
  String get tripStarting => 'Comenzando tu viaje';

  @override
  String get nextStep => 'Siguiente paso';

  @override
  String get previousStep => 'Anterior';

  @override
  String stepOf(int current, int total) {
    return 'Paso $current de $total';
  }

  @override
  String get arrived => '¡Llegaste!';

  @override
  String get endTrip => 'Terminar viaje';

  @override
  String get approximateRoute => 'Ruta aproximada';

  @override
  String get modeMetro => 'Metro';

  @override
  String get modeTram => 'Tranvía';

  @override
  String get modeCable => 'Metrocable';

  @override
  String get modeBus => 'Bus';

  @override
  String get modeWalk => 'Caminar';

  @override
  String lineName(String id) {
    return 'Línea $id';
  }

  @override
  String metroplusLine(String number) {
    return 'Metroplús Línea $number';
  }

  @override
  String feederRoute(String code) {
    return 'Ruta integrada $code';
  }

  @override
  String get clear => 'Borrar';

  @override
  String get findBestRoute => 'Buscar mejor ruta';

  @override
  String placeNotFound(String query) {
    return 'No encontramos \"$query\"';
  }

  @override
  String get swapPlaces => 'Intercambiar origen y destino';

  @override
  String get centerOnMe => 'Centrar en mi ubicación';

  @override
  String get skip => 'Omitir';

  @override
  String get approximateLocation => 'Ubicación aproximada';

  @override
  String walkToBusStreet(String line) {
    return 'Camina hasta la vía por donde pasa la $line';
  }

  @override
  String get boardOnStreet => 'Súbete en la vía (para a pedido)';

  @override
  String getOffNear(String place) {
    return 'Bájate cerca de $place';
  }

  @override
  String get yourDestination => 'tu destino';

  @override
  String impreciseLocation(int meters) {
    return 'Tu ubicación es imprecisa (±$meters m). Ajústala en el mapa para una mejor ruta.';
  }

  @override
  String get adjust => 'Ajustar';

  @override
  String get movePinOrigin => 'Mueve el mapa para ubicar el punto A (salida)';

  @override
  String get movePinDestination =>
      'Mueve el mapa para ubicar el punto B (llegada)';

  @override
  String get confirmPoint => 'Confirmar punto';

  @override
  String get placeOnMap => 'Marcar el punto en el mapa';

  @override
  String get systemLanguage => 'Idioma del sistema';

  @override
  String get menuSubtitle => 'Muévete por el Valle de Aburrá';

  @override
  String get menuSectionTravel => 'Viaje';

  @override
  String get menuSectionLines => 'Líneas del sistema';

  @override
  String get goByCar => 'Ir en carro';

  @override
  String get walkInstead => 'Ir caminando';

  @override
  String rideHailTo(String service, String place) {
    return 'Toma $service hasta $place';
  }

  @override
  String rideHailRequest(String from, String to) {
    return 'Pídelo desde $from hasta $to';
  }

  @override
  String rideHailDetail(int minutes, int wait, String km) {
    return '$minutes min en carro (incluye ~$wait min de espera) · $km km';
  }

  @override
  String destinationCopied(String service) {
    return 'Destino copiado: pégalo en $service';
  }

  @override
  String appNotOpened(String service) {
    return 'No se pudo abrir $service';
  }

  @override
  String busStreetOf(String line) {
    return 'la vía de la $line';
  }

  @override
  String get yourStart => 'tu punto de partida';

  @override
  String get modeCar => 'Carro';

  @override
  String get appTagline => 'Tu ruta por la ciudad';

  @override
  String get onboardingTitle1 => 'Dinos a dónde vas';

  @override
  String get onboardingBody1 =>
      'Escribe una dirección, elige una estación o marca los puntos A y B en el mapa.';

  @override
  String get onboardingTitle2 => 'La mejor combinación';

  @override
  String get onboardingBody2 =>
      'Nicmo combina metro, tranvía, metrocable, buses y caminatas, y te muestra alternativas.';

  @override
  String get onboardingTitle3 => 'Viaja paso a paso';

  @override
  String get onboardingBody3 =>
      'Sigue cada paso en el mapa y cambia una caminata por Uber o inDrive cuando lo necesites.';

  @override
  String get next => 'Siguiente';

  @override
  String get getStarted => 'Comenzar';

  @override
  String get showAllLines => 'Mostrar todas las líneas';

  @override
  String get createdBy => 'Creada por';

  @override
  String get change => 'Cambiar';

  @override
  String get languageHint => 'Toca para elegir otro idioma';

  @override
  String destinationSent(String service) {
    return 'Destino enviado a $service';
  }

  @override
  String carTo(String place) {
    return 'Ve en carro hasta $place';
  }

  @override
  String get requestWith => 'Pide tu carro con';

  @override
  String get groupMetroplus => 'Metroplús';

  @override
  String get groupFeeder => 'Rutas integradas';

  @override
  String get allTransport => 'Todo el transporte';

  @override
  String get transportOnMap => 'Transporte en el mapa';

  @override
  String get linesTitle => 'Líneas y rutas';

  @override
  String get searchLines => 'Buscar línea, ruta o barrio';

  @override
  String linesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count líneas',
      one: '1 línea',
    );
    return '$_temp0';
  }

  @override
  String stopsOnRoute(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count paradas',
      one: '1 parada',
    );
    return '$_temp0';
  }

  @override
  String get noLinesFound => 'No hay líneas con ese nombre';

  @override
  String get feederRoutesNote =>
      'Buses que te llevan a las estaciones. Recorridos y paradas: datos abiertos del Metro de Medellín.';

  @override
  String get seeAllLines => 'Ver todas las líneas';

  @override
  String get shareLocation => 'Compartir mi ubicación';

  @override
  String get shareTripTitle => 'Compartir mi viaje';

  @override
  String get shareTripHint =>
      'Se envía un enlace de Google Maps con el punto donde estás ahora.';

  @override
  String get shareOtherApps => 'Otras apps';

  @override
  String shareMessage(String destination, int minutes, String link) {
    return 'Voy en camino a $destination con Nicmo, llego en unos $minutes min. Estoy aquí: $link';
  }

  @override
  String get whatsAppUnavailable => 'No pudimos abrir WhatsApp';

  @override
  String get groupBus => 'Buses urbanos';

  @override
  String get familyMetro => 'Sistema Metro';

  @override
  String get familyBuses => 'Buses';

  @override
  String busRoute(String code) {
    return 'Ruta $code';
  }

  @override
  String get busRoutesNote =>
      'Buses de transporte público colectivo; paran a la señal en la vía. Recorridos publicados por la Alcaldía de Medellín y el Municipio de Itagüí (rutas metropolitanas). Confirma el letrero de la ruta antes de subir.';

  @override
  String moveAround(String place) {
    return 'Muévete por $place';
  }

  @override
  String get citiesTitle => 'Ciudades';

  @override
  String get changeCity => 'Cambiar ciudad';

  @override
  String get cityPickTitle => '¿En qué ciudad te vas a mover?';

  @override
  String get cityPickBody =>
      'Solo guardamos en tu celular el mapa y las rutas de tu ciudad. Agrega otras cuando viajes.';

  @override
  String get cityChooseFirst => 'Elige una ciudad para continuar';

  @override
  String get cityCurrent => 'Estás en';

  @override
  String get cityActive => 'Tus ciudades';

  @override
  String get cityExplore => 'Más ciudades';

  @override
  String get citySearch => 'Buscar ciudad';

  @override
  String get cityNoMatch => 'Ninguna ciudad coincide';

  @override
  String get cityAvailable => 'Rutas disponibles';

  @override
  String get citySoon => 'Próximamente';

  @override
  String citySoonNote(String city) {
    return 'Estamos preparando las rutas de $city. Ya puedes usar el mapa y buscar lugares.';
  }

  @override
  String get cityGo => 'Ir';

  @override
  String get cityActivate => 'Agregar';

  @override
  String get cityRemove => 'Quitar';

  @override
  String cityRemoveTitle(String city) {
    return '¿Quitar $city?';
  }

  @override
  String cityRemoveBody(String city, String size) {
    return 'Se borrará el mapa sin conexión de esta ciudad ($size). Puedes agregarla de nuevo cuando quieras.';
  }

  @override
  String cityRemoved(String city) {
    return '$city quitada, espacio liberado';
  }

  @override
  String cityAdded(String city) {
    return '$city agregada: su mapa se guarda mientras lo usas';
  }

  @override
  String cityOfflineMap(String size) {
    return 'Mapa sin conexión: $size';
  }

  @override
  String get cityOfflineEmpty =>
      'Mapa sin conexión: se guarda mientras lo usas';

  @override
  String get cityHere => 'Estás aquí';

  @override
  String cityNowIn(String city) {
    return 'Ahora en $city';
  }

  @override
  String get cityKeepsOffline =>
      'Solo las ciudades activas guardan su mapa en el celular';

  @override
  String get termsTitle => 'Términos y condiciones';

  @override
  String get termsSummary => 'En resumen';

  @override
  String termsUpdated(String date) {
    return 'Actualizado: $date';
  }

  @override
  String get termsAcceptNotice => 'Al continuar aceptas los';

  @override
  String get termsUnderstood => 'Entendido';

  @override
  String get cityPickBodySingle =>
      'Por ahora Nicmo cubre Medellín y todo el Valle de Aburrá: metro, cables, tranvía y buses. Pronto llegarán más ciudades.';

  @override
  String get citySceneMedellin => 'La ciudad de la eterna primavera';

  @override
  String get citySceneBogota => '2.600 metros más cerca de las estrellas';

  @override
  String get citySceneCali => 'La capital mundial de la salsa';

  @override
  String get citySceneBarranquilla => 'Quien lo vive es quien lo goza';

  @override
  String get citySceneCartagena => 'La Ciudad Heroica, frente al Caribe';

  @override
  String get citySceneBucaramanga => 'La Ciudad Bonita, la de los parques';

  @override
  String get cityScenePereira => 'En el corazón del Eje Cafetero';

  @override
  String get citySceneColombia => 'Colombia, el país de la belleza';
}
