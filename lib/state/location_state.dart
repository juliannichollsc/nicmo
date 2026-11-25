import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class UserLocation {
  /// Fixes worse than this (typical of desktop browsers locating by IP or
  /// Wi-Fi) are shown but the user is asked to confirm them on the map.
  static const double preciseMeters = 100;

  final LatLng position;
  final double accuracyMeters;

  const UserLocation(this.position, this.accuracyMeters);

  bool get isPrecise => accuracyMeters <= preciseMeters;
}

/// Best accuracy on every platform; on the web, never reuse a cached fix.
LocationSettings _settings() {
  const accuracy = LocationAccuracy.bestForNavigation;
  if (kIsWeb) {
    return WebSettings(accuracy: accuracy, maximumAge: Duration.zero);
  }
  switch (defaultTargetPlatform) {
    case TargetPlatform.android:
      return AndroidSettings(
        accuracy: accuracy,
        distanceFilter: 3,
        intervalDuration: const Duration(seconds: 2),
      );
    case TargetPlatform.iOS:
    case TargetPlatform.macOS:
      return AppleSettings(
        accuracy: accuracy,
        distanceFilter: 3,
        activityType: ActivityType.otherNavigation,
        allowBackgroundLocationUpdates: false,
      );
    default:
      return const LocationSettings(accuracy: accuracy, distanceFilter: 3);
  }
}

/// Live device position (Android, iOS and web through geolocator).
class LocationController extends ValueNotifier<UserLocation?> {
  LocationController() : super(null);

  StreamSubscription<Position>? _subscription;
  bool _starting = false;

  bool get isTracking => _subscription != null;

  /// Asks for permission once and keeps the position updated.
  /// Returns false when location is unavailable or denied.
  Future<bool> start() async {
    if (_subscription != null) return true;
    if (_starting) return false;
    _starting = true;
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return false;
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return false;
      }
      // A quick first fix so the marker appears without waiting for movement.
      // (Not supported on web, where the stream answers quickly anyway.)
      if (!kIsWeb) {
        try {
          final last = await Geolocator.getLastKnownPosition();
          if (last != null) _update(last);
        } catch (_) {}
      }
      _subscription =
          Geolocator.getPositionStream(locationSettings: _settings()).listen(
            _update,
            onError: (Object error) {
              debugPrint('Location stream error: $error');
            },
          );
      return true;
    } catch (error) {
      debugPrint('Location unavailable: $error');
      return false;
    } finally {
      _starting = false;
    }
  }

  void _update(Position p) {
    final next = UserLocation(LatLng(p.latitude, p.longitude), p.accuracy);
    final current = value;
    // Ignore a worse reading that arrives right after a better one (e.g. a
    // network fix after GPS), unless the user really moved.
    if (current != null &&
        next.accuracyMeters > current.accuracyMeters * 2 &&
        const Distance().as(LengthUnit.Meter, current.position, next.position) <
            next.accuracyMeters) {
      return;
    }
    value = next;
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

final LocationController locationController = LocationController();
