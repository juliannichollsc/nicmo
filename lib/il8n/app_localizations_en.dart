// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get email => 'Email';

  @override
  String get enterYourEmail => 'Enter your email';

  @override
  String get password => 'Password';

  @override
  String get enterYourPassword => 'Enter your password';

  @override
  String get forgotPassword => 'Forgot password?';

  @override
  String get login => 'Login';

  @override
  String get dontHaveAccountSignUp => 'Don\'t have an account? Sign up';

  @override
  String get name => 'Name';

  @override
  String get enterYourName => 'Enter your name';

  @override
  String get lastName => 'Last name';

  @override
  String get enterYourLastName => 'Enter your last name';

  @override
  String get phone => 'Phone';

  @override
  String get enterYourPhone => 'Enter your phone';

  @override
  String get confirmPassword => 'Confirm password';

  @override
  String get enterYourConfirmPassword => 'Enter your confirm password';

  @override
  String get alreadyHaveAccountLogin => 'Already have an account? Login';

  @override
  String get register => 'Register';

  @override
  String get verifyYourEmail => 'Verify your email';

  @override
  String get verificationCodeSent =>
      'We have sent a verification code to your email';

  @override
  String get verify => 'Verify';

  @override
  String get resendCode => 'Resend Code';

  @override
  String get notificationsEnabled => 'Notifications enabled';

  @override
  String get notificationsDisabled => 'Notifications disabled';

  @override
  String get couldNotOpenLink => 'Could not open link';

  @override
  String get appearance => 'Appearance';

  @override
  String get darkMode => 'Dark mode';

  @override
  String get on => 'On';

  @override
  String get off => 'Off';

  @override
  String get notifications => 'Notifications';

  @override
  String get pushNotifications => 'Push notifications';

  @override
  String get receiveAppAlerts => 'Receive app alerts';

  @override
  String get general => 'General';

  @override
  String get language => 'Language';

  @override
  String get english => 'English';

  @override
  String get spanish => 'Spanish';

  @override
  String get german => 'German';

  @override
  String get mandarin => 'Mandarin Chinese';

  @override
  String get about => 'About';

  @override
  String get aboutVersion => 'Version 1.0.0';

  @override
  String get linkedIn => 'LinkedIn';

  @override
  String get julianNichollsC => 'Julian Nicholls C';

  @override
  String get menu => 'Menu';

  @override
  String get home => 'Home';

  @override
  String get settings => 'Settings';

  @override
  String get profile => 'Profile';

  @override
  String get map => 'Map';

  @override
  String get lightMode => 'Light Mode';

  @override
  String get darkModeMenu => 'Dark Mode';

  @override
  String get selectFromGallery => 'Select from gallery';

  @override
  String get takeAPhoto => 'Take a photo';

  @override
  String get route => 'To';

  @override
  String get start => 'From';

  @override
  String get travel => 'Navigate';

  @override
  String get metroTitle => 'Metro de Medellín';

  @override
  String get whereTo => 'Where are you going?';

  @override
  String get whereToHint => 'Type an address, place or station';

  @override
  String get originHint => 'Starting point';

  @override
  String get destinationHint => 'Destination';

  @override
  String get myLocation => 'My location';

  @override
  String get cancel => 'Cancel';

  @override
  String get findRoutes => 'Find routes';

  @override
  String get searchingRoutes => 'Finding the best route…';

  @override
  String get noRoutes => 'No routes found for this trip';

  @override
  String get routeError => 'Something went wrong while planning the trip';

  @override
  String get locationUnavailable => 'Location unavailable';

  @override
  String get startTrip => 'Start trip';

  @override
  String get recommended => 'Recommended';

  @override
  String get fewestTransfers => 'Fewest transfers';

  @override
  String get leastWalking => 'Least walking';

  @override
  String get alternatives => 'Alternatives';

  @override
  String minutesShort(int minutes) {
    return '$minutes min';
  }

  @override
  String transfersCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count transfers',
      one: '1 transfer',
      zero: 'Direct',
    );
    return '$_temp0';
  }

  @override
  String walkDistance(int meters) {
    return '$meters m walking';
  }

  @override
  String walkTo(String place) {
    return 'Walk to $place';
  }

  @override
  String boardTowards(String line, String terminal) {
    return 'Take $line towards $terminal';
  }

  @override
  String stopsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count stops',
      one: '1 stop',
    );
    return '$_temp0';
  }

  @override
  String getOffAt(String station) {
    return 'Get off at $station';
  }

  @override
  String waitAbout(int minutes) {
    return 'Wait ~$minutes min';
  }

  @override
  String get tripStarting => 'Starting your trip';

  @override
  String get nextStep => 'Next step';

  @override
  String get previousStep => 'Previous';

  @override
  String stepOf(int current, int total) {
    return 'Step $current of $total';
  }

  @override
  String get arrived => 'You\'ve arrived!';

  @override
  String get endTrip => 'End trip';

  @override
  String get approximateRoute => 'Approximate route';

  @override
  String get modeMetro => 'Metro';

  @override
  String get modeTram => 'Tram';

  @override
  String get modeCable => 'Metrocable';

  @override
  String get modeBus => 'Bus';

  @override
  String get modeWalk => 'Walk';

  @override
  String lineName(String id) {
    return 'Line $id';
  }

  @override
  String metroplusLine(String number) {
    return 'Metroplús Line $number';
  }

  @override
  String feederRoute(String code) {
    return 'Feeder route $code';
  }

  @override
  String get clear => 'Clear';

  @override
  String get findBestRoute => 'Find best route';

  @override
  String placeNotFound(String query) {
    return 'We couldn\'t find \"$query\"';
  }

  @override
  String get swapPlaces => 'Swap origin and destination';

  @override
  String get centerOnMe => 'Center on my location';

  @override
  String get skip => 'Skip';

  @override
  String get approximateLocation => 'Approximate location';

  @override
  String walkToBusStreet(String line) {
    return 'Walk to the street where $line passes';
  }

  @override
  String get boardOnStreet => 'Board on the street (stops on request)';

  @override
  String getOffNear(String place) {
    return 'Get off near $place';
  }

  @override
  String get yourDestination => 'your destination';

  @override
  String impreciseLocation(int meters) {
    return 'Your location is imprecise (±$meters m). Adjust it on the map for a better route.';
  }

  @override
  String get adjust => 'Adjust';

  @override
  String get movePinOrigin => 'Move the map to place point A (start)';

  @override
  String get movePinDestination =>
      'Move the map to place point B (destination)';

  @override
  String get confirmPoint => 'Confirm point';

  @override
  String get placeOnMap => 'Place the point on the map';

  @override
  String get systemLanguage => 'System language';

  @override
  String get menuSubtitle => 'Get around the Valle de Aburrá';

  @override
  String get menuSectionTravel => 'Travel';

  @override
  String get menuSectionLines => 'System lines';

  @override
  String get goByCar => 'Go by car instead';

  @override
  String get walkInstead => 'Walk';

  @override
  String rideHailTo(String service, String place) {
    return 'Take $service to $place';
  }

  @override
  String rideHailRequest(String from, String to) {
    return 'Request it from $from to $to';
  }

  @override
  String rideHailDetail(int minutes, int wait, String km) {
    return '$minutes min by car (incl. ~$wait min pickup) · $km km';
  }

  @override
  String destinationCopied(String service) {
    return 'Destination copied: paste it in $service';
  }

  @override
  String appNotOpened(String service) {
    return 'Couldn\'t open $service';
  }

  @override
  String busStreetOf(String line) {
    return 'the street of $line';
  }

  @override
  String get yourStart => 'your starting point';

  @override
  String get modeCar => 'Car';

  @override
  String get appTagline => 'Your route around the city';

  @override
  String get onboardingTitle1 => 'Tell us where you\'re going';

  @override
  String get onboardingBody1 =>
      'Type an address, choose a station or place points A and B on the map.';

  @override
  String get onboardingTitle2 => 'The best combination';

  @override
  String get onboardingBody2 =>
      'Nicmo combines metro, tram, Metrocable, buses and walking, and shows you alternatives.';

  @override
  String get onboardingTitle3 => 'Travel step by step';

  @override
  String get onboardingBody3 =>
      'Follow each step on the map and switch a walk to Uber or inDrive when you need it.';

  @override
  String get next => 'Next';

  @override
  String get getStarted => 'Get started';

  @override
  String get showAllLines => 'Show all lines';

  @override
  String get createdBy => 'Created by';

  @override
  String get change => 'Change';

  @override
  String get languageHint => 'Tap to choose another language';

  @override
  String destinationSent(String service) {
    return 'Destination sent to $service';
  }

  @override
  String carTo(String place) {
    return 'Go by car to $place';
  }

  @override
  String get requestWith => 'Request your car with';

  @override
  String get groupMetroplus => 'Metroplús';

  @override
  String get groupFeeder => 'Feeder buses';

  @override
  String get allTransport => 'All transport';

  @override
  String get transportOnMap => 'Transport on the map';

  @override
  String get linesTitle => 'Lines and routes';

  @override
  String get searchLines => 'Search line, route or neighbourhood';

  @override
  String linesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count lines',
      one: '1 line',
    );
    return '$_temp0';
  }

  @override
  String stopsOnRoute(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count stops',
      one: '1 stop',
    );
    return '$_temp0';
  }

  @override
  String get noLinesFound => 'No lines match that name';

  @override
  String get feederRoutesNote =>
      'Buses that take you to the stations. Paths and stops: Metro de Medellín open data.';

  @override
  String get seeAllLines => 'See all lines';

  @override
  String get shareLocation => 'Share my location';

  @override
  String get shareTripTitle => 'Share my trip';

  @override
  String get shareTripHint =>
      'A Google Maps link with the point where you are now is sent.';

  @override
  String get shareOtherApps => 'Other apps';

  @override
  String shareMessage(String destination, int minutes, String link) {
    return 'I\'m on my way to $destination with Nicmo, arriving in about $minutes min. I\'m here: $link';
  }

  @override
  String get whatsAppUnavailable => 'We couldn\'t open WhatsApp';

  @override
  String get groupBus => 'City buses';

  @override
  String get familyMetro => 'Metro system';

  @override
  String get familyBuses => 'Buses';

  @override
  String busRoute(String code) {
    return 'Bus $code';
  }

  @override
  String get busRoutesNote =>
      'Public transport buses; they stop on request along the street. Paths published by the Alcaldía de Medellín and the Municipio de Itagüí (metropolitan routes). Check the route sign before boarding.';

  @override
  String moveAround(String place) {
    return 'Get around $place';
  }

  @override
  String get citiesTitle => 'Cities';

  @override
  String get changeCity => 'Change city';

  @override
  String get cityPickTitle => 'Where are you getting around?';

  @override
  String get cityPickBody =>
      'We only keep the map and routes of your city on the phone. Add other cities whenever you travel.';

  @override
  String get cityChooseFirst => 'Choose a city to continue';

  @override
  String get cityCurrent => 'You are in';

  @override
  String get cityActive => 'Your cities';

  @override
  String get cityExplore => 'More cities';

  @override
  String get citySearch => 'Search city';

  @override
  String get cityNoMatch => 'No city matches';

  @override
  String get cityAvailable => 'Routes available';

  @override
  String get citySoon => 'Coming soon';

  @override
  String citySoonNote(String city) {
    return 'We are preparing the routes of $city. You can already use the map and search places.';
  }

  @override
  String get cityGo => 'Go';

  @override
  String get cityActivate => 'Add';

  @override
  String get cityRemove => 'Remove';

  @override
  String cityRemoveTitle(String city) {
    return 'Remove $city?';
  }

  @override
  String cityRemoveBody(String city, String size) {
    return 'The offline map of this city ($size) will be deleted. You can add it again at any time.';
  }

  @override
  String cityRemoved(String city) {
    return '$city removed, space freed';
  }

  @override
  String cityAdded(String city) {
    return '$city added: its map is kept as you use it';
  }

  @override
  String cityOfflineMap(String size) {
    return 'Offline map: $size';
  }

  @override
  String get cityOfflineEmpty => 'Offline map: saved as you use it';

  @override
  String get cityHere => 'You are here';

  @override
  String cityNowIn(String city) {
    return 'Now in $city';
  }

  @override
  String get cityKeepsOffline =>
      'Only active cities keep their map on the phone';

  @override
  String get termsTitle => 'Terms and conditions';

  @override
  String get termsSummary => 'In short';

  @override
  String termsUpdated(String date) {
    return 'Updated $date';
  }

  @override
  String get termsAcceptNotice => 'By continuing you accept the';

  @override
  String get termsUnderstood => 'Got it';

  @override
  String get cityPickBodySingle =>
      'For now Nicmo covers Medellín and the whole Valle de Aburrá: metro, cable cars, tram and buses. More cities are on the way.';

  @override
  String get citySceneMedellin => 'The city of eternal spring';

  @override
  String get citySceneBogota => '8,600 feet closer to the stars';

  @override
  String get citySceneCali => 'The world capital of salsa';

  @override
  String get citySceneBarranquilla => 'Carnival: those who live it, enjoy it';

  @override
  String get citySceneCartagena => 'The Heroic City, by the Caribbean';

  @override
  String get citySceneBucaramanga => 'The Beautiful City of parks';

  @override
  String get cityScenePereira => 'In the heart of the Coffee Region';

  @override
  String get citySceneColombia => 'Colombia, the country of beauty';
}
