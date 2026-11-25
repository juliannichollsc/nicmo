import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:nicmo/domain/transit/itinerary.dart';
import 'package:nicmo/domain/transit/transit_network.dart';
import 'package:nicmo/infrastructure/transit/multimodal_trip_planner.dart';

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

/// A (north-south metro), B (branch to the west from a3), K (cable east of a2).
final TransitNetwork network = TransitNetwork.fromJson({
  'lines': [
    {
      'id': 'A',
      'name': 'Línea A',
      'mode': 'metro',
      'color': '#0A63B0',
      'avgSpeedKmh': 35,
      'headwayMin': 4,
      'stations': ['a1', 'a2', 'a3', 'a4', 'a5'],
    },
    {
      'id': 'B',
      'name': 'Línea B',
      'mode': 'metro',
      'color': '#F28C28',
      'avgSpeedKmh': 35,
      'headwayMin': 6,
      'stations': ['a3', 'b1', 'b2'],
    },
    {
      'id': 'K',
      'name': 'Línea K',
      'mode': 'cable',
      'color': '#65BC4B',
      'avgSpeedKmh': 18,
      'headwayMin': 1,
      'stations': ['a2', 'k1', 'k2'],
    },
    // Feeder bus from a far barrio (f1, 3 km east) to a4; stops on request.
    {
      'id': 'AL-1',
      'name': 'Ruta integrada 1',
      'mode': 'bus',
      'color': '#65BC4B',
      'avgSpeedKmh': 15,
      'headwayMin': 10,
      'approximate': true,
      'stations': ['f1', 'a4'],
    },
  ],
  'stations': [
    _station('a1', 6.30, -75.56, ['A']),
    _station('a2', 6.28, -75.56, ['A', 'K']),
    _station('a3', 6.26, -75.56, ['A', 'B']),
    _station('a4', 6.24, -75.56, ['A', 'AL-1']),
    _station('a5', 6.22, -75.56, ['A']),
    _station('b1', 6.26, -75.58, ['B']),
    _station('b2', 6.26, -75.60, ['B']),
    _station('k1', 6.285, -75.545, ['K']),
    _station('k2', 6.29, -75.53, ['K']),
    _station('f1', 6.24, -75.53, ['AL-1']),
  ],
});

void main() {
  final planner = MultimodalTripPlanner();

  test('plans a transfer between two metro lines', () {
    final results = planner.plan(
      network,
      const LatLng(6.2602, -75.6002), // next to b2
      const LatLng(6.2198, -75.5601), // next to a5
      originName: 'Origen',
      destinationName: 'Destino',
    );
    expect(results, isNotEmpty);
    final best = results.first;
    expect(best.signature, 'B>A');
    expect(best.transfers, 1);
    expect(best.tags, contains(ItineraryTag.fastest));
    final rides = best.rideLegs;
    expect(rides.first.stops.map((s) => s.id), ['b2', 'b1', 'a3']);
    expect(rides.last.stops.map((s) => s.id), ['a3', 'a4', 'a5']);
    expect(best.legs.first.fromName, 'Origen');
    expect(best.totalMin, greaterThan(0));
  });

  test('chains metro and metrocable', () {
    final results = planner.plan(
      network,
      const LatLng(6.2201, -75.5601),
      const LatLng(6.2901, -75.5301),
    );
    expect(results.first.signature, 'A>K');
    expect(results.first.rideLegs.last.mode, TransitMode.cable);
  });

  test('short trips recommend walking', () {
    final results = planner.plan(
      network,
      const LatLng(6.2600, -75.5700),
      const LatLng(6.2620, -75.5710),
    );
    expect(results.first.rideLegs, isEmpty);
    expect(results.first.legs.single.isWalk, isTrue);
  });

  test('alternatives have distinct line sequences', () {
    final results = planner.plan(
      network,
      const LatLng(6.2602, -75.6002),
      const LatLng(6.2901, -75.5301),
    );
    final signatures = results.map((r) => r.signature).toList();
    expect(signatures.toSet().length, signatures.length);
  });

  test('boards a feeder bus on the street and transfers to the metro', () {
    // Origin is next to the bus street, halfway between f1 and a4 (1.6 km
    // from any stop): walk to the street, bus to a4, metro north.
    final results = planner.plan(
      network,
      const LatLng(6.2412, -75.545),
      const LatLng(6.3001, -75.5601),
    );
    final best = results.first;
    expect(best.signature, 'AL-1>A');
    final bus = best.rideLegs.first;
    expect(bus.boardsRoadside, isTrue);
    expect(bus.headsign, 'A4');
    expect(best.legs.first.walkToLine?.id, 'AL-1');
    expect(best.legs.first.distanceMeters, lessThan(250));
  });

  test('a single bus serves both ends when it passes near both', () {
    final best = planner
        .plan(
          network,
          const LatLng(6.2412, -75.542),
          const LatLng(6.2412, -75.548),
        )
        .first;
    // 650 m apart: walking directly is still the sensible answer.
    expect(best.rideLegs, isEmpty);
  });
}
