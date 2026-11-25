import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:nicmo/app_info.dart';

/// Where an ad may appear. Never while a trip is being navigated, never
/// full screen: only the arrival screen and a small slot in the side menu.
enum AdPlacement { endTrip, menu }

/// Google AdMob: consent (UMP) and SDK start-up, and the ad unit of each
/// placement. Ads are always requested non-personalised (see the terms).
abstract final class AdsService {
  /// True once the SDK is initialised and consent allows requesting ads.
  /// Stays false on the web, in tests and when ads are disabled, so the ad
  /// widgets render nothing.
  static final ready = ValueNotifier<bool>(false);

  static bool get _supported =>
      kAdsEnabled &&
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  /// Asks for consent where the law requires it (EEA/UK; elsewhere the form
  /// is not shown) and starts the SDK. Runs after the first frame and never
  /// blocks the app: any failure just leaves [ready] false.
  static Future<void> start() async {
    if (!_supported || ready.value) return;
    try {
      final updated = Completer<void>();
      ConsentInformation.instance.requestConsentInfoUpdate(
        ConsentRequestParameters(),
        updated.complete,
        (_) => updated.complete(),
      );
      await updated.future;
      await ConsentForm.loadAndShowConsentFormIfRequired((_) {});
      if (!await ConsentInformation.instance.canRequestAds()) return;
      await MobileAds.instance.initialize();
      ready.value = true;
    } catch (e) {
      debugPrint('Ads unavailable: $e');
    }
  }

  static const _units = {
    (TargetPlatform.android, AdPlacement.endTrip): String.fromEnvironment(
      'ADS_ANDROID_END_TRIP',
    ),
    (TargetPlatform.android, AdPlacement.menu): String.fromEnvironment(
      'ADS_ANDROID_MENU',
    ),
    (TargetPlatform.iOS, AdPlacement.endTrip): String.fromEnvironment(
      'ADS_IOS_END_TRIP',
    ),
    (TargetPlatform.iOS, AdPlacement.menu): String.fromEnvironment(
      'ADS_IOS_MENU',
    ),
  };

  // Google's sample native units. Debug builds always use them: tapping or
  // viewing our real ads during development counts as invalid traffic and
  // can get the AdMob account suspended.
  static const _testUnits = {
    TargetPlatform.android: 'ca-app-pub-3940256099942544/2247696110',
    TargetPlatform.iOS: 'ca-app-pub-3940256099942544/3986624511',
  };

  /// Ad unit for [placement] on this platform, or null when none is set
  /// (release build without `env/ads.json`): then no ad is requested.
  static String? unitId(AdPlacement placement) {
    final platform = defaultTargetPlatform;
    if (kDebugMode) return _testUnits[platform];
    final id = _units[(platform, placement)];
    return id == null || id.isEmpty ? null : id;
  }
}
