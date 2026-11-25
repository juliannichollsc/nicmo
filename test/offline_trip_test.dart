import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:nicmo/domain/transit/itinerary.dart';
import 'package:nicmo/domain/transit/transit_network.dart';
import 'package:nicmo/domain/transit/transit_services.dart';
import 'package:nicmo/infrastructure/map/offline_vector_tiles.dart';
import 'package:nicmo/infrastructure/transit/multimodal_trip_planner.dart';
import 'package:nicmo/state/active_trip_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

Map<String, dynamic> _station(
  String id,
  double lat,
  double lng,
  List<String> lines,
) => {
  'id': id,
  'name': id.toUpperCase(),
  'lat': lat,
  'lng': lng,
  'lines': lines,
};

final TransitNetwork network = TransitNetwork.fromJson({
  'lines': [
    {
      'id': 'A',
      'name': 'Línea A',
      'mode': 'metro',
      'color': '#0A63B0',
      'avgSpeedKmh': 35,
      'headwayMin': 4,
      'stations': ['a1', 'a2', 'a3'],
    },
    {
      'id': 'AL-1',
      'name': 'Ruta integrada 1',
      'mode': 'bus',
      'color': '#65BC4B',
      'avgSpeedKmh': 15,
      'headwayMin': 10,
      'approximate': true,
      'stations': ['f1', 'a3'],
    },
  ],
  'stations': [
    _station('a1', 6.30, -75.56, ['A']),
    _station('a2', 6.27, -75.56, ['A']),
    _station('a3', 6.24, -75.56, ['A', 'AL-1']),
    _station('f1', 6.24, -75.53, ['AL-1']),
  ],
});

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final itinerary = MultimodalTripPlanner()
      .plan(
        network,
        const LatLng(6.301, -75.561),
        const LatLng(6.241, -75.531),
        originName: 'Casa',
        destinationName: 'Trabajo',
      )
      .first
      .withCar(0, true)
      .withRideHailApp(0, RideHailService.uber);

  test('an itinerary survives a save / restore round trip', () {
    final json = jsonDecode(jsonEncode(itineraryToJson(itinerary)));
    final restored = itineraryFromJson(json as Map<String, dynamic>, network);

    expect(restored.legs.length, itinerary.legs.length);
    expect(restored.signature, itinerary.signature);
    expect(restored.totalMin, closeTo(itinerary.totalMin, 1e-9));
    expect(restored.tags, itinerary.tags);
    for (var i = 0; i < itinerary.legs.length; i++) {
      final a = itinerary.legs[i];
      final b = restored.legs[i];
      expect(b.mode, a.mode);
      expect(identical(b.line, a.line), isTrue);
      expect(b.path, a.path);
      expect([for (final s in b.stops) s.id], [for (final s in a.stops) s.id]);
      expect(b.byCar, a.byCar);
      expect(b.rideHail, a.rideHail);
      expect(b.headsign, a.headsign);
      expect(b.boardsRoadside, a.boardsRoadside);
    }
    expect(restored.legs.first.rideHail, RideHailService.uber);
  });

  test('the trip in progress is resumed at its step, then cleared', () async {
    SharedPreferences.setMockInitialValues({});
    const origin = Place(name: 'Casa', position: LatLng(6.301, -75.561));
    const destination = Place(
      name: 'Trabajo',
      subtitle: 'Barrio',
      position: LatLng(6.241, -75.531),
    );
    await ActiveTripStore.save(
      ActiveTrip(
        itinerary: itinerary,
        origin: origin,
        destination: destination,
        step: 1,
      ),
    );

    expect(await ActiveTripStore.hasSaved(), isTrue);
    final active = await ActiveTripStore.load(network);
    expect(active, isNotNull);
    expect(active!.step, 1);
    expect(active.destination.subtitle, 'Barrio');
    expect(active.itinerary.signature, itinerary.signature);

    await ActiveTripStore.clear();
    expect(await ActiveTripStore.load(network), isNull);
  });

  test('a corrupt saved trip is dropped', () async {
    SharedPreferences.setMockInitialValues({'activeTrip': '{"broken": true'});
    expect(await ActiveTripStore.load(network), isNull);
    expect(await ActiveTripStore.hasSaved(), isFalse);
  });

  test('route tiles cover the whole path with a margin', () {
    // Poblado -> Niquía, about 18 km along the metro.
    const path = [LatLng(6.2125, -75.5776), LatLng(6.3375, -75.5443)];
    final tiles = OfflineVectorTiles.routeTiles(path, const [14]);
    // No gaps: every row the path crosses is covered.
    final rows = {for (final t in tiles) t.y};
    final minY = rows.reduce((a, b) => a < b ? a : b);
    final maxY = rows.reduce((a, b) => a > b ? a : b);
    expect(rows.length, maxY - minY + 1);
    // Small enough to download in a few seconds (~15 KB each).
    expect(tiles.length, lessThan(120));
    // Whole route at low zoom: a 3x3 block, or 3x4 when it crosses a row.
    expect(OfflineVectorTiles.routeTiles(path, const [10]).length, 12);
  });
}
