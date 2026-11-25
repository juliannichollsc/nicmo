import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import 'package:nicmo/domain/transit/itinerary.dart';
import 'package:nicmo/domain/transit/transit_network.dart';
import 'package:nicmo/domain/transit/transit_services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A trip in progress, as saved on the device.
class ActiveTrip {
  final Itinerary itinerary;
  final Place origin;
  final Place destination;
  final int step;

  const ActiveTrip({
    required this.itinerary,
    required this.origin,
    required this.destination,
    required this.step,
  });
}

/// Keeps the trip in progress across app restarts, so a trip started with
/// network carries on offline: everything it needs (route, lines, stops) is
/// saved locally and the planner data ships with the app.
class ActiveTripStore {
  static const _key = 'activeTrip';

  /// Older trips are dropped instead of resumed.
  static const maxAge = Duration(hours: 12);

  /// Trip restored at launch, to be resumed by the trip screen.
  static ActiveTrip? pending;

  static Future<void> save(ActiveTrip trip) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _key,
        jsonEncode({
          'savedAt': DateTime.now().toIso8601String(),
          'step': trip.step,
          'origin': _placeToJson(trip.origin),
          'destination': _placeToJson(trip.destination),
          'itinerary': itineraryToJson(trip.itinerary),
        }),
      );
    } catch (error) {
      debugPrint('Trip not saved: $error');
    }
  }

  static Future<bool> hasSaved() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.containsKey(_key);
    } catch (_) {
      return false;
    }
  }

  static Future<void> clear() async {
    pending = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_key);
    } catch (_) {}
  }

  /// Reads the saved trip (null when none, too old or unreadable).
  static Future<ActiveTrip?> load(TransitNetwork network) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_key);
      if (saved == null) return null;
      final json = jsonDecode(saved) as Map<String, dynamic>;
      final savedAt = DateTime.tryParse(json['savedAt'] as String? ?? '');
      if (savedAt == null || DateTime.now().difference(savedAt) > maxAge) {
        await clear();
        return null;
      }
      final itinerary = itineraryFromJson(
        json['itinerary'] as Map<String, dynamic>,
        network,
      );
      return ActiveTrip(
        itinerary: itinerary,
        origin: _placeFromJson(json['origin'] as Map<String, dynamic>),
        destination: _placeFromJson(
          json['destination'] as Map<String, dynamic>,
        ),
        step: (json['step'] as int).clamp(0, itinerary.legs.length - 1),
      );
    } catch (error) {
      debugPrint('Saved trip unreadable, dropped: $error');
      await clear();
      return null;
    }
  }

  static Map<String, dynamic> _placeToJson(Place place) => {
    'name': place.name,
    'subtitle': place.subtitle,
    ..._point(place.position),
  };

  static Place _placeFromJson(Map<String, dynamic> json) => Place(
    name: json['name'] as String,
    subtitle: json['subtitle'] as String?,
    position: _latLng(json),
  );
}

@visibleForTesting
Map<String, dynamic> itineraryToJson(Itinerary itinerary) => {
  'tags': [for (final tag in itinerary.tags) tag.name],
  'legs': [for (final leg in itinerary.legs) _legToJson(leg)],
};

/// Lines are looked up in [network]; stops are stored whole because roadside
/// bus stops are not part of the network.
@visibleForTesting
Itinerary itineraryFromJson(Map<String, dynamic> json, TransitNetwork network) {
  TransitLine? line(Object? id) {
    if (id == null) return null;
    final found = network.lines[id];
    if (found == null) throw FormatException('Unknown line $id');
    return found;
  }

  ItineraryLeg legFromJson(Map<String, dynamic> leg) => ItineraryLeg(
    mode: TransitMode.values.byName(leg['mode'] as String),
    line: line(leg['line']),
    fromName: leg['from'] as String,
    toName: leg['to'] as String,
    stops: [
      for (final stop in leg['stops'] as List)
        TransitStation(
          id: stop['id'] as String,
          name: stop['name'] as String,
          position: _latLng(stop as Map<String, dynamic>),
          lineIds: List<String>.from(stop['lines'] as List),
        ),
    ],
    path: [
      for (final point in leg['path'] as List)
        LatLng((point[0] as num).toDouble(), (point[1] as num).toDouble()),
    ],
    distanceMeters: (leg['distance'] as num).toDouble(),
    durationMin: (leg['duration'] as num).toDouble(),
    waitMin: (leg['wait'] as num).toDouble(),
    headsign: leg['headsign'] as String?,
    boardsRoadside: leg['boardsRoadside'] as bool,
    alightsRoadside: leg['alightsRoadside'] as bool,
    walkToLine: line(leg['walkToLine']),
    byCar: leg['byCar'] as bool,
    rideHail: leg['rideHail'] == null
        ? null
        : RideHailService.values.byName(leg['rideHail'] as String),
  );

  return Itinerary(
    tags: {
      for (final name in json['tags'] as List)
        ItineraryTag.values.byName(name as String),
    },
    legs: [
      for (final raw in json['legs'] as List)
        legFromJson(raw as Map<String, dynamic>),
    ],
  );
}

Map<String, dynamic> _legToJson(ItineraryLeg leg) => {
  'mode': leg.mode.name,
  'line': leg.line?.id,
  'from': leg.fromName,
  'to': leg.toName,
  'stops': [
    for (final stop in leg.stops)
      {
        'id': stop.id,
        'name': stop.name,
        'lines': stop.lineIds,
        ..._point(stop.position),
      },
  ],
  'path': [
    for (final point in leg.path) [point.latitude, point.longitude],
  ],
  'distance': leg.distanceMeters,
  'duration': leg.durationMin,
  'wait': leg.waitMin,
  'headsign': leg.headsign,
  'boardsRoadside': leg.boardsRoadside,
  'alightsRoadside': leg.alightsRoadside,
  'walkToLine': leg.walkToLine?.id,
  'byCar': leg.byCar,
  'rideHail': leg.rideHail?.name,
};

Map<String, dynamic> _point(LatLng point) => {
  'lat': point.latitude,
  'lng': point.longitude,
};

LatLng _latLng(Map<String, dynamic> json) =>
    LatLng((json['lat'] as num).toDouble(), (json['lng'] as num).toDouble());
