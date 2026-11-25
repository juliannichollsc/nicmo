import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import 'package:nicmo/domain/transit/itinerary.dart';
import 'package:url_launcher/url_launcher.dart';

enum RideHailLaunch {
  /// The app opened with the drop-off already set.
  withDestination,

  /// The app opened; the rider has to enter the destination.
  appOnly,

  /// The app is not installed: its store page opened.
  store,
  failed,
}

/// Opens ride-hailing apps on Android and iOS with the leg's drop-off.
///
/// For each app, in order:
/// 1. Installed and able to take the destination: open it with the drop-off.
///    * Uber: official link m.uber.com/ul (developer.uber.com/docs/deep-linking),
///      sent straight to the Uber app (verified: it handles /ul/ links).
///    * inDrive (Android): its deep-link screen accepts the standard
///      `geo:lat,lng?q=lat,lng(name)` intent (verified with the package
///      manager); sent with the package set, so no app chooser appears.
/// 2. Installed but older / no destination support: just open the app.
/// 3. Not installed: its page in Google Play or the App Store.
class RideHailLauncher {
  static const _uberAndroidPackage = 'com.ubercab';
  static const _uberAppStoreId = '368677368';
  static const _indriveAndroidPackage = 'sinet.startup.inDriver';
  static const _indriveAppStoreId = '780125801';

  static Uri uberLink({
    required LatLng pickup,
    required String pickupName,
    required LatLng dropoff,
    required String dropoffName,
  }) {
    String coordinate(double value) => value.toStringAsFixed(6);
    return Uri.https('m.uber.com', '/ul/', {
      'action': 'setPickup',
      'pickup[latitude]': coordinate(pickup.latitude),
      'pickup[longitude]': coordinate(pickup.longitude),
      'pickup[nickname]': pickupName,
      'dropoff[latitude]': coordinate(dropoff.latitude),
      'dropoff[longitude]': coordinate(dropoff.longitude),
      'dropoff[nickname]': dropoffName,
    });
  }

  /// `geo:` URI understood by Android apps that take a destination.
  static String geoUri(LatLng point, String name) {
    final lat = point.latitude.toStringAsFixed(6);
    final lng = point.longitude.toStringAsFixed(6);
    final label = Uri.encodeComponent(name.replaceAll(RegExp('[()]'), ''));
    return 'geo:$lat,$lng?q=$lat,$lng($label)';
  }

  static Future<RideHailLaunch> open(
    RideHailService service, {
    required LatLng pickup,
    required String pickupName,
    required LatLng dropoff,
    required String dropoffName,
  }) async {
    final uber = uberLink(
      pickup: pickup,
      pickupName: pickupName,
      dropoff: dropoff,
      dropoffName: dropoffName,
    );
    switch (service) {
      case RideHailService.uber:
        if (_isAndroid) {
          if (await _androidView(uber.toString(), _uberAndroidPackage)) {
            return RideHailLaunch.withDestination;
          }
          return _store(_uberAndroidPackage, _uberAppStoreId);
        }
        if (_isIos) {
          // The universal link opens the app when it is installed.
          if (await _canOpen('uber://') && await _launch(uber)) {
            return RideHailLaunch.withDestination;
          }
          return _store(_uberAndroidPackage, _uberAppStoreId);
        }
        return await _launch(uber)
            ? RideHailLaunch.withDestination
            : RideHailLaunch.failed;

      case RideHailService.indrive:
        if (_isAndroid) {
          if (await _androidView(
            geoUri(dropoff, dropoffName),
            _indriveAndroidPackage,
          )) {
            return RideHailLaunch.withDestination;
          }
          // Older versions: open the app without the destination.
          for (final link in const ['indrive://open', 'indriver://open']) {
            if (await _androidView(link, _indriveAndroidPackage)) {
              return RideHailLaunch.appOnly;
            }
          }
          return _store(_indriveAndroidPackage, _indriveAppStoreId);
        }
        if (_isIos) {
          for (final link in const ['indrive://open', 'indriver://open']) {
            if (await _canOpen(link) && await _launch(Uri.parse(link))) {
              return RideHailLaunch.appOnly;
            }
          }
          return _store(_indriveAndroidPackage, _indriveAppStoreId);
        }
        return await _launch(Uri.https('indrive.com'))
            ? RideHailLaunch.appOnly
            : RideHailLaunch.failed;
    }
  }

  static bool get _isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  static bool get _isIos =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  /// Opens [data] in the app [package] only (no chooser, no browser).
  static Future<bool> _androidView(String data, String package) async {
    try {
      final intent = AndroidIntent(
        action: 'action_view',
        data: data,
        package: package,
        flags: const [Flag.FLAG_ACTIVITY_NEW_TASK],
      );
      if (await intent.canResolveActivity() != true) return false;
      await intent.launch();
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<RideHailLaunch> _store(String androidId, String iosId) async {
    final opened = await _launch(
      _isIos
          ? Uri.https('apps.apple.com', '/app/id$iosId')
          : Uri.https('play.google.com', '/store/apps/details', {
              'id': androidId,
            }),
    );
    return opened ? RideHailLaunch.store : RideHailLaunch.failed;
  }

  static Future<bool> _canOpen(String link) async {
    try {
      return await canLaunchUrl(Uri.parse(link));
    } catch (_) {
      return false;
    }
  }

  static Future<bool> _launch(Uri uri) async {
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }
}
