// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get email => 'E-Mail';

  @override
  String get enterYourEmail => 'Geben Sie Ihre E-Mail-Adresse ein';

  @override
  String get password => 'Passwort';

  @override
  String get enterYourPassword => 'Geben Sie Ihr Passwort ein';

  @override
  String get forgotPassword => 'Passwort vergessen?';

  @override
  String get login => 'Anmelden';

  @override
  String get dontHaveAccountSignUp =>
      'Sie haben noch kein Konto? Registrieren Sie sich';

  @override
  String get name => 'Name';

  @override
  String get enterYourName => 'Geben Sie Ihren Namen ein';

  @override
  String get lastName => 'Nachname';

  @override
  String get enterYourLastName => 'Geben Sie Ihren Nachnamen ein';

  @override
  String get phone => 'Telefon';

  @override
  String get enterYourPhone => 'Geben Sie Ihre Telefonnummer ein';

  @override
  String get confirmPassword => 'Passwort bestätigen';

  @override
  String get enterYourConfirmPassword => 'Bestätigen Sie Ihr Passwort';

  @override
  String get alreadyHaveAccountLogin => 'Sie haben bereits ein Konto? Anmelden';

  @override
  String get register => 'Registrieren';

  @override
  String get verifyYourEmail => 'Bestätigen Sie Ihre E-Mail-Adresse';

  @override
  String get verificationCodeSent =>
      'Wir haben einen Bestätigungscode an Ihre E-Mail-Adresse gesendet';

  @override
  String get verify => 'Bestätigen';

  @override
  String get resendCode => 'Code erneut senden';

  @override
  String get notificationsEnabled => 'Benachrichtigungen aktiviert';

  @override
  String get notificationsDisabled => 'Benachrichtigungen deaktiviert';

  @override
  String get couldNotOpenLink => 'Link konnte nicht geöffnet werden';

  @override
  String get appearance => 'Darstellung';

  @override
  String get darkMode => 'Dunkelmodus';

  @override
  String get on => 'Ein';

  @override
  String get off => 'Aus';

  @override
  String get notifications => 'Benachrichtigungen';

  @override
  String get pushNotifications => 'Push-Benachrichtigungen';

  @override
  String get receiveAppAlerts => 'App-Benachrichtigungen erhalten';

  @override
  String get general => 'Allgemein';

  @override
  String get language => 'Sprache';

  @override
  String get english => 'Englisch';

  @override
  String get spanish => 'Spanisch';

  @override
  String get german => 'Deutsch';

  @override
  String get mandarin => 'Mandarin-Chinesisch';

  @override
  String get about => 'Info';

  @override
  String get aboutVersion => 'Version 1.0.0';

  @override
  String get linkedIn => 'LinkedIn';

  @override
  String get julianNichollsC => 'Julian Nicholls C';

  @override
  String get menu => 'Menü';

  @override
  String get home => 'Startseite';

  @override
  String get settings => 'Einstellungen';

  @override
  String get profile => 'Profil';

  @override
  String get map => 'Karte';

  @override
  String get lightMode => 'Hellmodus';

  @override
  String get darkModeMenu => 'Dunkelmodus';

  @override
  String get selectFromGallery => 'Aus Galerie auswählen';

  @override
  String get takeAPhoto => 'Foto machen';

  @override
  String get route => 'Nach';

  @override
  String get start => 'Von';

  @override
  String get travel => 'Navigieren';

  @override
  String get metroTitle => 'Metro de Medellín';

  @override
  String get whereTo => 'Wohin möchtest du?';

  @override
  String get whereToHint => 'Adresse, Ort oder Station eingeben';

  @override
  String get originHint => 'Startpunkt';

  @override
  String get destinationHint => 'Ziel';

  @override
  String get myLocation => 'Mein Standort';

  @override
  String get cancel => 'Abbrechen';

  @override
  String get findRoutes => 'Routen suchen';

  @override
  String get searchingRoutes => 'Beste Route wird gesucht…';

  @override
  String get noRoutes => 'Keine Routen für diese Fahrt gefunden';

  @override
  String get routeError => 'Beim Planen der Fahrt ist ein Fehler aufgetreten';

  @override
  String get locationUnavailable => 'Standort nicht verfügbar';

  @override
  String get startTrip => 'Fahrt starten';

  @override
  String get recommended => 'Empfohlen';

  @override
  String get fewestTransfers => 'Wenigste Umstiege';

  @override
  String get leastWalking => 'Wenigster Fußweg';

  @override
  String get alternatives => 'Alternativen';

  @override
  String minutesShort(int minutes) {
    return '$minutes Min.';
  }

  @override
  String transfersCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Umstiege',
      one: '1 Umstieg',
      zero: 'Direkt',
    );
    return '$_temp0';
  }

  @override
  String walkDistance(int meters) {
    return '$meters m zu Fuß';
  }

  @override
  String walkTo(String place) {
    return 'Gehe zu $place';
  }

  @override
  String boardTowards(String line, String terminal) {
    return 'Nimm $line Richtung $terminal';
  }

  @override
  String stopsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Halte',
      one: '1 Halt',
    );
    return '$_temp0';
  }

  @override
  String getOffAt(String station) {
    return 'Steige in $station aus';
  }

  @override
  String waitAbout(int minutes) {
    return 'Warte ~$minutes Min.';
  }

  @override
  String get tripStarting => 'Deine Fahrt beginnt';

  @override
  String get nextStep => 'Nächster Schritt';

  @override
  String get previousStep => 'Zurück';

  @override
  String stepOf(int current, int total) {
    return 'Schritt $current von $total';
  }

  @override
  String get arrived => 'Du bist angekommen!';

  @override
  String get endTrip => 'Fahrt beenden';

  @override
  String get approximateRoute => 'Ungefähre Route';

  @override
  String get modeMetro => 'Metro';

  @override
  String get modeTram => 'Straßenbahn';

  @override
  String get modeCable => 'Metrocable';

  @override
  String get modeBus => 'Bus';

  @override
  String get modeWalk => 'Zu Fuß';

  @override
  String lineName(String id) {
    return 'Linie $id';
  }

  @override
  String metroplusLine(String number) {
    return 'Metroplús Linie $number';
  }

  @override
  String feederRoute(String code) {
    return 'Zubringerlinie $code';
  }

  @override
  String get clear => 'Löschen';

  @override
  String get findBestRoute => 'Beste Route suchen';

  @override
  String placeNotFound(String query) {
    return '\"$query\" wurde nicht gefunden';
  }

  @override
  String get swapPlaces => 'Start und Ziel tauschen';

  @override
  String get centerOnMe => 'Auf meinen Standort zentrieren';

  @override
  String get skip => 'Überspringen';

  @override
  String get approximateLocation => 'Ungefährer Standort';

  @override
  String walkToBusStreet(String line) {
    return 'Gehe zur Straße, auf der $line fährt';
  }

  @override
  String get boardOnStreet => 'Steige an der Straße ein (Halt auf Wunsch)';

  @override
  String getOffNear(String place) {
    return 'Steige in der Nähe von $place aus';
  }

  @override
  String get yourDestination => 'deinem Ziel';

  @override
  String impreciseLocation(int meters) {
    return 'Dein Standort ist ungenau (±$meters m). Passe ihn auf der Karte an.';
  }

  @override
  String get adjust => 'Anpassen';

  @override
  String get movePinOrigin => 'Bewege die Karte, um Punkt A (Start) zu setzen';

  @override
  String get movePinDestination =>
      'Bewege die Karte, um Punkt B (Ziel) zu setzen';

  @override
  String get confirmPoint => 'Punkt bestätigen';

  @override
  String get placeOnMap => 'Punkt auf der Karte setzen';

  @override
  String get systemLanguage => 'Systemsprache';

  @override
  String get menuSubtitle => 'Unterwegs im Valle de Aburrá';

  @override
  String get menuSectionTravel => 'Reise';

  @override
  String get menuSectionLines => 'Linien des Systems';

  @override
  String get goByCar => 'Stattdessen mit dem Auto';

  @override
  String get walkInstead => 'Zu Fuß gehen';

  @override
  String rideHailTo(String service, String place) {
    return 'Nimm $service nach $place';
  }

  @override
  String rideHailRequest(String from, String to) {
    return 'Bestelle von $from nach $to';
  }

  @override
  String rideHailDetail(int minutes, int wait, String km) {
    return '$minutes Min. mit dem Auto (inkl. ~$wait Min. Abholung) · $km km';
  }

  @override
  String destinationCopied(String service) {
    return 'Ziel kopiert: füge es in $service ein';
  }

  @override
  String appNotOpened(String service) {
    return '$service konnte nicht geöffnet werden';
  }

  @override
  String busStreetOf(String line) {
    return 'die Straße von $line';
  }

  @override
  String get yourStart => 'deinem Startpunkt';

  @override
  String get modeCar => 'Auto';

  @override
  String get appTagline => 'Deine Route durch die Stadt';

  @override
  String get onboardingTitle1 => 'Sag uns, wohin du willst';

  @override
  String get onboardingBody1 =>
      'Gib eine Adresse ein, wähle eine Station oder setze die Punkte A und B auf der Karte.';

  @override
  String get onboardingTitle2 => 'Die beste Kombination';

  @override
  String get onboardingBody2 =>
      'Nicmo kombiniert Metro, Straßenbahn, Metrocable, Busse und Fußwege und zeigt dir Alternativen.';

  @override
  String get onboardingTitle3 => 'Reise Schritt für Schritt';

  @override
  String get onboardingBody3 =>
      'Folge jedem Schritt auf der Karte und ersetze einen Fußweg bei Bedarf durch Uber oder inDrive.';

  @override
  String get next => 'Weiter';

  @override
  String get getStarted => 'Los geht\'s';

  @override
  String get showAllLines => 'Alle Linien anzeigen';

  @override
  String get createdBy => 'Erstellt von';

  @override
  String get change => 'Ändern';

  @override
  String get languageHint => 'Tippe, um eine andere Sprache zu wählen';

  @override
  String destinationSent(String service) {
    return 'Ziel an $service gesendet';
  }

  @override
  String carTo(String place) {
    return 'Fahre mit dem Auto nach $place';
  }

  @override
  String get requestWith => 'Bestelle dein Auto mit';

  @override
  String get groupMetroplus => 'Metroplús';

  @override
  String get groupFeeder => 'Zubringerbusse';

  @override
  String get allTransport => 'Alle Verkehrsmittel';

  @override
  String get transportOnMap => 'Verkehrsmittel auf der Karte';

  @override
  String get linesTitle => 'Linien und Routen';

  @override
  String get searchLines => 'Linie, Route oder Viertel suchen';

  @override
  String linesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Linien',
      one: '1 Linie',
    );
    return '$_temp0';
  }

  @override
  String stopsOnRoute(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Haltestellen',
      one: '1 Haltestelle',
    );
    return '$_temp0';
  }

  @override
  String get noLinesFound => 'Keine Linie mit diesem Namen';

  @override
  String get feederRoutesNote =>
      'Busse, die dich zu den Stationen bringen. Strecken und Haltestellen: offene Daten der Metro de Medellín.';

  @override
  String get seeAllLines => 'Alle Linien ansehen';

  @override
  String get shareLocation => 'Meinen Standort teilen';

  @override
  String get shareTripTitle => 'Meine Fahrt teilen';

  @override
  String get shareTripHint =>
      'Es wird ein Google-Maps-Link mit deinem aktuellen Standort gesendet.';

  @override
  String get shareOtherApps => 'Andere Apps';

  @override
  String shareMessage(String destination, int minutes, String link) {
    return 'Ich bin mit Nicmo unterwegs nach $destination, Ankunft in etwa $minutes Min. Ich bin hier: $link';
  }

  @override
  String get whatsAppUnavailable => 'WhatsApp konnte nicht geöffnet werden';

  @override
  String get groupBus => 'Stadtbusse';

  @override
  String get familyMetro => 'Metro-System';

  @override
  String get familyBuses => 'Busse';

  @override
  String busRoute(String code) {
    return 'Bus $code';
  }

  @override
  String get busRoutesNote =>
      'Linienbusse; sie halten auf Handzeichen an der Straße. Strecken veröffentlicht von der Alcaldía de Medellín und dem Municipio de Itagüí (Regionallinien). Prüfe vor dem Einsteigen das Linienschild.';

  @override
  String moveAround(String place) {
    return 'Unterwegs in $place';
  }

  @override
  String get citiesTitle => 'Städte';

  @override
  String get changeCity => 'Stadt wechseln';

  @override
  String get cityPickTitle => 'Wo bist du unterwegs?';

  @override
  String get cityPickBody =>
      'Wir speichern nur Karte und Linien deiner Stadt auf dem Handy. Weitere Städte kannst du jederzeit hinzufügen.';

  @override
  String get cityChooseFirst => 'Wähle eine Stadt, um fortzufahren';

  @override
  String get cityCurrent => 'Du bist in';

  @override
  String get cityActive => 'Deine Städte';

  @override
  String get cityExplore => 'Weitere Städte';

  @override
  String get citySearch => 'Stadt suchen';

  @override
  String get cityNoMatch => 'Keine Stadt gefunden';

  @override
  String get cityAvailable => 'Linien verfügbar';

  @override
  String get citySoon => 'Demnächst';

  @override
  String citySoonNote(String city) {
    return 'Wir bereiten die Linien von $city vor. Karte und Ortssuche kannst du schon nutzen.';
  }

  @override
  String get cityGo => 'Los';

  @override
  String get cityActivate => 'Hinzufügen';

  @override
  String get cityRemove => 'Entfernen';

  @override
  String cityRemoveTitle(String city) {
    return '$city entfernen?';
  }

  @override
  String cityRemoveBody(String city, String size) {
    return 'Die Offline-Karte dieser Stadt ($size) wird gelöscht. Du kannst sie jederzeit wieder hinzufügen.';
  }

  @override
  String cityRemoved(String city) {
    return '$city entfernt, Speicher freigegeben';
  }

  @override
  String cityAdded(String city) {
    return '$city hinzugefügt: die Karte wird beim Benutzen gespeichert';
  }

  @override
  String cityOfflineMap(String size) {
    return 'Offline-Karte: $size';
  }

  @override
  String get cityOfflineEmpty =>
      'Offline-Karte: wird beim Benutzen gespeichert';

  @override
  String get cityHere => 'Du bist hier';

  @override
  String cityNowIn(String city) {
    return 'Jetzt in $city';
  }

  @override
  String get cityKeepsOffline =>
      'Nur aktive Städte speichern ihre Karte auf dem Handy';

  @override
  String get termsTitle => 'Nutzungsbedingungen';

  @override
  String get termsSummary => 'Kurz gesagt';

  @override
  String termsUpdated(String date) {
    return 'Aktualisiert: $date';
  }

  @override
  String get termsAcceptNotice => 'Wenn du fortfährst, akzeptierst du die';

  @override
  String get termsUnderstood => 'Verstanden';

  @override
  String get cityPickBodySingle =>
      'Derzeit deckt Nicmo Medellín und das ganze Valle de Aburrá ab: Metro, Seilbahnen, Straßenbahn und Busse. Weitere Städte folgen.';

  @override
  String get citySceneMedellin => 'Die Stadt des ewigen Frühlings';

  @override
  String get citySceneBogota => '2.600 Meter näher an den Sternen';

  @override
  String get citySceneCali => 'Die Welthauptstadt des Salsa';

  @override
  String get citySceneBarranquilla => 'Karneval: Wer ihn erlebt, genießt ihn';

  @override
  String get citySceneCartagena => 'Die Heldenstadt an der Karibik';

  @override
  String get citySceneBucaramanga => 'Die schöne Stadt der Parks';

  @override
  String get cityScenePereira => 'Im Herzen der Kaffeeregion';

  @override
  String get citySceneColombia => 'Kolumbien, das Land der Schönheit';
}
