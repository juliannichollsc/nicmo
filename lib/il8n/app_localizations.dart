import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'il8n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('zh'),
  ];

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @enterYourEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter your email'**
  String get enterYourEmail;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @enterYourPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get enterYourPassword;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgotPassword;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @dontHaveAccountSignUp.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? Sign up'**
  String get dontHaveAccountSignUp;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @enterYourName.
  ///
  /// In en, this message translates to:
  /// **'Enter your name'**
  String get enterYourName;

  /// No description provided for @lastName.
  ///
  /// In en, this message translates to:
  /// **'Last name'**
  String get lastName;

  /// No description provided for @enterYourLastName.
  ///
  /// In en, this message translates to:
  /// **'Enter your last name'**
  String get enterYourLastName;

  /// No description provided for @phone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phone;

  /// No description provided for @enterYourPhone.
  ///
  /// In en, this message translates to:
  /// **'Enter your phone'**
  String get enterYourPhone;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get confirmPassword;

  /// No description provided for @enterYourConfirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter your confirm password'**
  String get enterYourConfirmPassword;

  /// No description provided for @alreadyHaveAccountLogin.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Login'**
  String get alreadyHaveAccountLogin;

  /// No description provided for @register.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get register;

  /// No description provided for @verifyYourEmail.
  ///
  /// In en, this message translates to:
  /// **'Verify your email'**
  String get verifyYourEmail;

  /// No description provided for @verificationCodeSent.
  ///
  /// In en, this message translates to:
  /// **'We have sent a verification code to your email'**
  String get verificationCodeSent;

  /// No description provided for @verify.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get verify;

  /// No description provided for @resendCode.
  ///
  /// In en, this message translates to:
  /// **'Resend Code'**
  String get resendCode;

  /// No description provided for @notificationsEnabled.
  ///
  /// In en, this message translates to:
  /// **'Notifications enabled'**
  String get notificationsEnabled;

  /// No description provided for @notificationsDisabled.
  ///
  /// In en, this message translates to:
  /// **'Notifications disabled'**
  String get notificationsDisabled;

  /// No description provided for @couldNotOpenLink.
  ///
  /// In en, this message translates to:
  /// **'Could not open link'**
  String get couldNotOpenLink;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark mode'**
  String get darkMode;

  /// No description provided for @on.
  ///
  /// In en, this message translates to:
  /// **'On'**
  String get on;

  /// No description provided for @off.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get off;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @pushNotifications.
  ///
  /// In en, this message translates to:
  /// **'Push notifications'**
  String get pushNotifications;

  /// No description provided for @receiveAppAlerts.
  ///
  /// In en, this message translates to:
  /// **'Receive app alerts'**
  String get receiveAppAlerts;

  /// No description provided for @general.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get general;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @spanish.
  ///
  /// In en, this message translates to:
  /// **'Spanish'**
  String get spanish;

  /// No description provided for @german.
  ///
  /// In en, this message translates to:
  /// **'German'**
  String get german;

  /// No description provided for @mandarin.
  ///
  /// In en, this message translates to:
  /// **'Mandarin Chinese'**
  String get mandarin;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @aboutVersion.
  ///
  /// In en, this message translates to:
  /// **'Version 1.0.0'**
  String get aboutVersion;

  /// No description provided for @linkedIn.
  ///
  /// In en, this message translates to:
  /// **'LinkedIn'**
  String get linkedIn;

  /// No description provided for @julianNichollsC.
  ///
  /// In en, this message translates to:
  /// **'Julian Nicholls C'**
  String get julianNichollsC;

  /// No description provided for @menu.
  ///
  /// In en, this message translates to:
  /// **'Menu'**
  String get menu;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @map.
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get map;

  /// No description provided for @lightMode.
  ///
  /// In en, this message translates to:
  /// **'Light Mode'**
  String get lightMode;

  /// No description provided for @darkModeMenu.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get darkModeMenu;

  /// No description provided for @selectFromGallery.
  ///
  /// In en, this message translates to:
  /// **'Select from gallery'**
  String get selectFromGallery;

  /// No description provided for @takeAPhoto.
  ///
  /// In en, this message translates to:
  /// **'Take a photo'**
  String get takeAPhoto;

  /// No description provided for @route.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get route;

  /// No description provided for @start.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get start;

  /// No description provided for @travel.
  ///
  /// In en, this message translates to:
  /// **'Navigate'**
  String get travel;

  /// No description provided for @metroTitle.
  ///
  /// In en, this message translates to:
  /// **'Metro de Medellín'**
  String get metroTitle;

  /// No description provided for @whereTo.
  ///
  /// In en, this message translates to:
  /// **'Where are you going?'**
  String get whereTo;

  /// No description provided for @whereToHint.
  ///
  /// In en, this message translates to:
  /// **'Type an address, place or station'**
  String get whereToHint;

  /// No description provided for @originHint.
  ///
  /// In en, this message translates to:
  /// **'Starting point'**
  String get originHint;

  /// No description provided for @destinationHint.
  ///
  /// In en, this message translates to:
  /// **'Destination'**
  String get destinationHint;

  /// No description provided for @myLocation.
  ///
  /// In en, this message translates to:
  /// **'My location'**
  String get myLocation;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @findRoutes.
  ///
  /// In en, this message translates to:
  /// **'Find routes'**
  String get findRoutes;

  /// No description provided for @searchingRoutes.
  ///
  /// In en, this message translates to:
  /// **'Finding the best route…'**
  String get searchingRoutes;

  /// No description provided for @noRoutes.
  ///
  /// In en, this message translates to:
  /// **'No routes found for this trip'**
  String get noRoutes;

  /// No description provided for @routeError.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong while planning the trip'**
  String get routeError;

  /// No description provided for @locationUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Location unavailable'**
  String get locationUnavailable;

  /// No description provided for @startTrip.
  ///
  /// In en, this message translates to:
  /// **'Start trip'**
  String get startTrip;

  /// No description provided for @recommended.
  ///
  /// In en, this message translates to:
  /// **'Recommended'**
  String get recommended;

  /// No description provided for @fewestTransfers.
  ///
  /// In en, this message translates to:
  /// **'Fewest transfers'**
  String get fewestTransfers;

  /// No description provided for @leastWalking.
  ///
  /// In en, this message translates to:
  /// **'Least walking'**
  String get leastWalking;

  /// No description provided for @alternatives.
  ///
  /// In en, this message translates to:
  /// **'Alternatives'**
  String get alternatives;

  /// No description provided for @minutesShort.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min'**
  String minutesShort(int minutes);

  /// No description provided for @transfersCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Direct} =1{1 transfer} other{{count} transfers}}'**
  String transfersCount(int count);

  /// No description provided for @walkDistance.
  ///
  /// In en, this message translates to:
  /// **'{meters} m walking'**
  String walkDistance(int meters);

  /// No description provided for @walkTo.
  ///
  /// In en, this message translates to:
  /// **'Walk to {place}'**
  String walkTo(String place);

  /// No description provided for @boardTowards.
  ///
  /// In en, this message translates to:
  /// **'Take {line} towards {terminal}'**
  String boardTowards(String line, String terminal);

  /// No description provided for @stopsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 stop} other{{count} stops}}'**
  String stopsCount(int count);

  /// No description provided for @getOffAt.
  ///
  /// In en, this message translates to:
  /// **'Get off at {station}'**
  String getOffAt(String station);

  /// No description provided for @waitAbout.
  ///
  /// In en, this message translates to:
  /// **'Wait ~{minutes} min'**
  String waitAbout(int minutes);

  /// No description provided for @tripStarting.
  ///
  /// In en, this message translates to:
  /// **'Starting your trip'**
  String get tripStarting;

  /// No description provided for @nextStep.
  ///
  /// In en, this message translates to:
  /// **'Next step'**
  String get nextStep;

  /// No description provided for @previousStep.
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get previousStep;

  /// No description provided for @stepOf.
  ///
  /// In en, this message translates to:
  /// **'Step {current} of {total}'**
  String stepOf(int current, int total);

  /// No description provided for @arrived.
  ///
  /// In en, this message translates to:
  /// **'You\'ve arrived!'**
  String get arrived;

  /// No description provided for @endTrip.
  ///
  /// In en, this message translates to:
  /// **'End trip'**
  String get endTrip;

  /// No description provided for @approximateRoute.
  ///
  /// In en, this message translates to:
  /// **'Approximate route'**
  String get approximateRoute;

  /// No description provided for @modeMetro.
  ///
  /// In en, this message translates to:
  /// **'Metro'**
  String get modeMetro;

  /// No description provided for @modeTram.
  ///
  /// In en, this message translates to:
  /// **'Tram'**
  String get modeTram;

  /// No description provided for @modeCable.
  ///
  /// In en, this message translates to:
  /// **'Metrocable'**
  String get modeCable;

  /// No description provided for @modeBus.
  ///
  /// In en, this message translates to:
  /// **'Bus'**
  String get modeBus;

  /// No description provided for @modeWalk.
  ///
  /// In en, this message translates to:
  /// **'Walk'**
  String get modeWalk;

  /// No description provided for @lineName.
  ///
  /// In en, this message translates to:
  /// **'Line {id}'**
  String lineName(String id);

  /// No description provided for @metroplusLine.
  ///
  /// In en, this message translates to:
  /// **'Metroplús Line {number}'**
  String metroplusLine(String number);

  /// No description provided for @feederRoute.
  ///
  /// In en, this message translates to:
  /// **'Feeder route {code}'**
  String feederRoute(String code);

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @findBestRoute.
  ///
  /// In en, this message translates to:
  /// **'Find best route'**
  String get findBestRoute;

  /// No description provided for @placeNotFound.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t find \"{query}\"'**
  String placeNotFound(String query);

  /// No description provided for @swapPlaces.
  ///
  /// In en, this message translates to:
  /// **'Swap origin and destination'**
  String get swapPlaces;

  /// No description provided for @centerOnMe.
  ///
  /// In en, this message translates to:
  /// **'Center on my location'**
  String get centerOnMe;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @approximateLocation.
  ///
  /// In en, this message translates to:
  /// **'Approximate location'**
  String get approximateLocation;

  /// No description provided for @walkToBusStreet.
  ///
  /// In en, this message translates to:
  /// **'Walk to the street where {line} passes'**
  String walkToBusStreet(String line);

  /// No description provided for @boardOnStreet.
  ///
  /// In en, this message translates to:
  /// **'Board on the street (stops on request)'**
  String get boardOnStreet;

  /// No description provided for @getOffNear.
  ///
  /// In en, this message translates to:
  /// **'Get off near {place}'**
  String getOffNear(String place);

  /// No description provided for @yourDestination.
  ///
  /// In en, this message translates to:
  /// **'your destination'**
  String get yourDestination;

  /// No description provided for @impreciseLocation.
  ///
  /// In en, this message translates to:
  /// **'Your location is imprecise (±{meters} m). Adjust it on the map for a better route.'**
  String impreciseLocation(int meters);

  /// No description provided for @adjust.
  ///
  /// In en, this message translates to:
  /// **'Adjust'**
  String get adjust;

  /// No description provided for @movePinOrigin.
  ///
  /// In en, this message translates to:
  /// **'Move the map to place point A (start)'**
  String get movePinOrigin;

  /// No description provided for @movePinDestination.
  ///
  /// In en, this message translates to:
  /// **'Move the map to place point B (destination)'**
  String get movePinDestination;

  /// No description provided for @confirmPoint.
  ///
  /// In en, this message translates to:
  /// **'Confirm point'**
  String get confirmPoint;

  /// No description provided for @placeOnMap.
  ///
  /// In en, this message translates to:
  /// **'Place the point on the map'**
  String get placeOnMap;

  /// No description provided for @systemLanguage.
  ///
  /// In en, this message translates to:
  /// **'System language'**
  String get systemLanguage;

  /// No description provided for @menuSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Get around the Valle de Aburrá'**
  String get menuSubtitle;

  /// No description provided for @menuSectionTravel.
  ///
  /// In en, this message translates to:
  /// **'Travel'**
  String get menuSectionTravel;

  /// No description provided for @menuSectionLines.
  ///
  /// In en, this message translates to:
  /// **'System lines'**
  String get menuSectionLines;

  /// No description provided for @goByCar.
  ///
  /// In en, this message translates to:
  /// **'Go by car instead'**
  String get goByCar;

  /// No description provided for @walkInstead.
  ///
  /// In en, this message translates to:
  /// **'Walk'**
  String get walkInstead;

  /// No description provided for @rideHailTo.
  ///
  /// In en, this message translates to:
  /// **'Take {service} to {place}'**
  String rideHailTo(String service, String place);

  /// No description provided for @rideHailRequest.
  ///
  /// In en, this message translates to:
  /// **'Request it from {from} to {to}'**
  String rideHailRequest(String from, String to);

  /// No description provided for @rideHailDetail.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min by car (incl. ~{wait} min pickup) · {km} km'**
  String rideHailDetail(int minutes, int wait, String km);

  /// No description provided for @destinationCopied.
  ///
  /// In en, this message translates to:
  /// **'Destination copied: paste it in {service}'**
  String destinationCopied(String service);

  /// No description provided for @appNotOpened.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t open {service}'**
  String appNotOpened(String service);

  /// No description provided for @busStreetOf.
  ///
  /// In en, this message translates to:
  /// **'the street of {line}'**
  String busStreetOf(String line);

  /// No description provided for @yourStart.
  ///
  /// In en, this message translates to:
  /// **'your starting point'**
  String get yourStart;

  /// No description provided for @modeCar.
  ///
  /// In en, this message translates to:
  /// **'Car'**
  String get modeCar;

  /// No description provided for @appTagline.
  ///
  /// In en, this message translates to:
  /// **'Your route around the city'**
  String get appTagline;

  /// No description provided for @onboardingTitle1.
  ///
  /// In en, this message translates to:
  /// **'Tell us where you\'re going'**
  String get onboardingTitle1;

  /// No description provided for @onboardingBody1.
  ///
  /// In en, this message translates to:
  /// **'Type an address, choose a station or place points A and B on the map.'**
  String get onboardingBody1;

  /// No description provided for @onboardingTitle2.
  ///
  /// In en, this message translates to:
  /// **'The best combination'**
  String get onboardingTitle2;

  /// No description provided for @onboardingBody2.
  ///
  /// In en, this message translates to:
  /// **'Nicmo combines metro, tram, Metrocable, buses and walking, and shows you alternatives.'**
  String get onboardingBody2;

  /// No description provided for @onboardingTitle3.
  ///
  /// In en, this message translates to:
  /// **'Travel step by step'**
  String get onboardingTitle3;

  /// No description provided for @onboardingBody3.
  ///
  /// In en, this message translates to:
  /// **'Follow each step on the map and switch a walk to Uber or inDrive when you need it.'**
  String get onboardingBody3;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @getStarted.
  ///
  /// In en, this message translates to:
  /// **'Get started'**
  String get getStarted;

  /// No description provided for @showAllLines.
  ///
  /// In en, this message translates to:
  /// **'Show all lines'**
  String get showAllLines;

  /// No description provided for @createdBy.
  ///
  /// In en, this message translates to:
  /// **'Created by'**
  String get createdBy;

  /// No description provided for @change.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get change;

  /// No description provided for @languageHint.
  ///
  /// In en, this message translates to:
  /// **'Tap to choose another language'**
  String get languageHint;

  /// No description provided for @destinationSent.
  ///
  /// In en, this message translates to:
  /// **'Destination sent to {service}'**
  String destinationSent(String service);

  /// No description provided for @carTo.
  ///
  /// In en, this message translates to:
  /// **'Go by car to {place}'**
  String carTo(String place);

  /// No description provided for @requestWith.
  ///
  /// In en, this message translates to:
  /// **'Request your car with'**
  String get requestWith;

  /// No description provided for @groupMetroplus.
  ///
  /// In en, this message translates to:
  /// **'Metroplús'**
  String get groupMetroplus;

  /// No description provided for @groupFeeder.
  ///
  /// In en, this message translates to:
  /// **'Feeder buses'**
  String get groupFeeder;

  /// No description provided for @allTransport.
  ///
  /// In en, this message translates to:
  /// **'All transport'**
  String get allTransport;

  /// No description provided for @transportOnMap.
  ///
  /// In en, this message translates to:
  /// **'Transport on the map'**
  String get transportOnMap;

  /// No description provided for @linesTitle.
  ///
  /// In en, this message translates to:
  /// **'Lines and routes'**
  String get linesTitle;

  /// No description provided for @searchLines.
  ///
  /// In en, this message translates to:
  /// **'Search line, route or neighbourhood'**
  String get searchLines;

  /// No description provided for @linesCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 line} other{{count} lines}}'**
  String linesCount(int count);

  /// No description provided for @stopsOnRoute.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 stop} other{{count} stops}}'**
  String stopsOnRoute(int count);

  /// No description provided for @noLinesFound.
  ///
  /// In en, this message translates to:
  /// **'No lines match that name'**
  String get noLinesFound;

  /// No description provided for @feederRoutesNote.
  ///
  /// In en, this message translates to:
  /// **'Buses that take you to the stations. Paths and stops: Metro de Medellín open data.'**
  String get feederRoutesNote;

  /// No description provided for @seeAllLines.
  ///
  /// In en, this message translates to:
  /// **'See all lines'**
  String get seeAllLines;

  /// No description provided for @shareLocation.
  ///
  /// In en, this message translates to:
  /// **'Share my location'**
  String get shareLocation;

  /// No description provided for @shareTripTitle.
  ///
  /// In en, this message translates to:
  /// **'Share my trip'**
  String get shareTripTitle;

  /// No description provided for @shareTripHint.
  ///
  /// In en, this message translates to:
  /// **'A Google Maps link with the point where you are now is sent.'**
  String get shareTripHint;

  /// No description provided for @shareOtherApps.
  ///
  /// In en, this message translates to:
  /// **'Other apps'**
  String get shareOtherApps;

  /// No description provided for @shareMessage.
  ///
  /// In en, this message translates to:
  /// **'I\'m on my way to {destination} with Nicmo, arriving in about {minutes} min. I\'m here: {link}'**
  String shareMessage(String destination, int minutes, String link);

  /// No description provided for @whatsAppUnavailable.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t open WhatsApp'**
  String get whatsAppUnavailable;

  /// No description provided for @groupBus.
  ///
  /// In en, this message translates to:
  /// **'City buses'**
  String get groupBus;

  /// No description provided for @familyMetro.
  ///
  /// In en, this message translates to:
  /// **'Metro system'**
  String get familyMetro;

  /// No description provided for @familyBuses.
  ///
  /// In en, this message translates to:
  /// **'Buses'**
  String get familyBuses;

  /// No description provided for @busRoute.
  ///
  /// In en, this message translates to:
  /// **'Bus {code}'**
  String busRoute(String code);

  /// No description provided for @busRoutesNote.
  ///
  /// In en, this message translates to:
  /// **'Public transport buses; they stop on request along the street. Paths published by the Alcaldía de Medellín and the Municipio de Itagüí (metropolitan routes). Check the route sign before boarding.'**
  String get busRoutesNote;

  /// No description provided for @moveAround.
  ///
  /// In en, this message translates to:
  /// **'Get around {place}'**
  String moveAround(String place);

  /// No description provided for @citiesTitle.
  ///
  /// In en, this message translates to:
  /// **'Cities'**
  String get citiesTitle;

  /// No description provided for @changeCity.
  ///
  /// In en, this message translates to:
  /// **'Change city'**
  String get changeCity;

  /// No description provided for @cityPickTitle.
  ///
  /// In en, this message translates to:
  /// **'Where are you getting around?'**
  String get cityPickTitle;

  /// No description provided for @cityPickBody.
  ///
  /// In en, this message translates to:
  /// **'We only keep the map and routes of your city on the phone. Add other cities whenever you travel.'**
  String get cityPickBody;

  /// No description provided for @cityChooseFirst.
  ///
  /// In en, this message translates to:
  /// **'Choose a city to continue'**
  String get cityChooseFirst;

  /// No description provided for @cityCurrent.
  ///
  /// In en, this message translates to:
  /// **'You are in'**
  String get cityCurrent;

  /// No description provided for @cityActive.
  ///
  /// In en, this message translates to:
  /// **'Your cities'**
  String get cityActive;

  /// No description provided for @cityExplore.
  ///
  /// In en, this message translates to:
  /// **'More cities'**
  String get cityExplore;

  /// No description provided for @citySearch.
  ///
  /// In en, this message translates to:
  /// **'Search city'**
  String get citySearch;

  /// No description provided for @cityNoMatch.
  ///
  /// In en, this message translates to:
  /// **'No city matches'**
  String get cityNoMatch;

  /// No description provided for @cityAvailable.
  ///
  /// In en, this message translates to:
  /// **'Routes available'**
  String get cityAvailable;

  /// No description provided for @citySoon.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get citySoon;

  /// No description provided for @citySoonNote.
  ///
  /// In en, this message translates to:
  /// **'We are preparing the routes of {city}. You can already use the map and search places.'**
  String citySoonNote(String city);

  /// No description provided for @cityGo.
  ///
  /// In en, this message translates to:
  /// **'Go'**
  String get cityGo;

  /// No description provided for @cityActivate.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get cityActivate;

  /// No description provided for @cityRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get cityRemove;

  /// No description provided for @cityRemoveTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove {city}?'**
  String cityRemoveTitle(String city);

  /// No description provided for @cityRemoveBody.
  ///
  /// In en, this message translates to:
  /// **'The offline map of this city ({size}) will be deleted. You can add it again at any time.'**
  String cityRemoveBody(String city, String size);

  /// No description provided for @cityRemoved.
  ///
  /// In en, this message translates to:
  /// **'{city} removed, space freed'**
  String cityRemoved(String city);

  /// No description provided for @cityAdded.
  ///
  /// In en, this message translates to:
  /// **'{city} added: its map is kept as you use it'**
  String cityAdded(String city);

  /// No description provided for @cityOfflineMap.
  ///
  /// In en, this message translates to:
  /// **'Offline map: {size}'**
  String cityOfflineMap(String size);

  /// No description provided for @cityOfflineEmpty.
  ///
  /// In en, this message translates to:
  /// **'Offline map: saved as you use it'**
  String get cityOfflineEmpty;

  /// No description provided for @cityHere.
  ///
  /// In en, this message translates to:
  /// **'You are here'**
  String get cityHere;

  /// No description provided for @cityNowIn.
  ///
  /// In en, this message translates to:
  /// **'Now in {city}'**
  String cityNowIn(String city);

  /// No description provided for @cityKeepsOffline.
  ///
  /// In en, this message translates to:
  /// **'Only active cities keep their map on the phone'**
  String get cityKeepsOffline;

  /// No description provided for @termsTitle.
  ///
  /// In en, this message translates to:
  /// **'Terms and conditions'**
  String get termsTitle;

  /// No description provided for @termsSummary.
  ///
  /// In en, this message translates to:
  /// **'In short'**
  String get termsSummary;

  /// No description provided for @termsUpdated.
  ///
  /// In en, this message translates to:
  /// **'Updated {date}'**
  String termsUpdated(String date);

  /// No description provided for @termsAcceptNotice.
  ///
  /// In en, this message translates to:
  /// **'By continuing you accept the'**
  String get termsAcceptNotice;

  /// No description provided for @termsUnderstood.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get termsUnderstood;

  /// No description provided for @cityPickBodySingle.
  ///
  /// In en, this message translates to:
  /// **'For now Nicmo covers Medellín and the whole Valle de Aburrá: metro, cable cars, tram and buses. More cities are on the way.'**
  String get cityPickBodySingle;

  /// Caption of the animated scene of a city (its best-known nickname); the last one is shown when several cities are active.
  ///
  /// In en, this message translates to:
  /// **'The city of eternal spring'**
  String get citySceneMedellin;

  /// No description provided for @citySceneBogota.
  ///
  /// In en, this message translates to:
  /// **'8,600 feet closer to the stars'**
  String get citySceneBogota;

  /// No description provided for @citySceneCali.
  ///
  /// In en, this message translates to:
  /// **'The world capital of salsa'**
  String get citySceneCali;

  /// No description provided for @citySceneBarranquilla.
  ///
  /// In en, this message translates to:
  /// **'Carnival: those who live it, enjoy it'**
  String get citySceneBarranquilla;

  /// No description provided for @citySceneCartagena.
  ///
  /// In en, this message translates to:
  /// **'The Heroic City, by the Caribbean'**
  String get citySceneCartagena;

  /// No description provided for @citySceneBucaramanga.
  ///
  /// In en, this message translates to:
  /// **'The Beautiful City of parks'**
  String get citySceneBucaramanga;

  /// No description provided for @cityScenePereira.
  ///
  /// In en, this message translates to:
  /// **'In the heart of the Coffee Region'**
  String get cityScenePereira;

  /// No description provided for @citySceneColombia.
  ///
  /// In en, this message translates to:
  /// **'Colombia, the country of beauty'**
  String get citySceneColombia;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['de', 'en', 'es', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
