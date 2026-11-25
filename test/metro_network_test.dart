import 'package:flutter_test/flutter_test.dart';
import 'support/city_network.dart';
import 'package:latlong2/latlong.dart';
import 'package:nicmo/domain/transit/itinerary.dart';
import 'package:nicmo/domain/transit/transit_network.dart';
import 'package:nicmo/infrastructure/transit/multimodal_trip_planner.dart';

void main() {
  final network = loadCityNetwork('medellin');
  final planner = MultimodalTripPlanner();

  LatLng near(String stationId) {
    final p = network.stations[stationId]!.position;
    return LatLng(p.latitude + 0.0006, p.longitude + 0.0006);
  }

  List<Itinerary> plan(String from, String to) {
    final results = planner.plan(network, near(from), near(to));
    for (final it in results) {
      // ignore: avoid_print
      print(
        '$from -> $to: ${it.signature} ${it.totalMin.toStringAsFixed(1)} min '
        '${it.walkMeters.round()} m ${it.tags}',
      );
    }
    return results;
  }

  test('every line references known stations', () {
    expect(network.lines.length, greaterThan(10));
    expect(
      network.lines.keys,
      containsAll(['A', 'B', 'TA', 'K', 'J', 'L', 'H', 'M', 'P', 'MP1', 'MP2']),
    );
  });

  test('Niquía to El Poblado is a direct line A trip', () {
    final best = plan('niquia', 'poblado').first;
    expect(best.signature, 'A');
    expect(best.totalMin, inInclusiveRange(25, 50));
  });

  test('San Javier to Parque Arví chains B, A, K and L', () {
    final arvi = network.lines['L']!.stationIds.last;
    final best = plan('san_javier', arvi).first;
    expect(best.signature, 'B>A>K>L');
  });

  test('El Poblado to Oriente offers the tram', () {
    // The feeder C6-005 (San Antonio - El Vergel) also gets close to Oriente
    // and can come first; the tram must be among the options.
    final results = plan('poblado', 'oriente');
    expect(results.map((it) => it.signature), contains('A>TA'));
  });

  test('variants of one bus route are a single alternative', () {
    for (final (from, to) in [
      ('poblado', 'oriente'),
      ('san_javier', 'arvi'),
      ('niquia', 'poblado'),
    ]) {
      final keys = [
        for (final it in plan(from, to))
          it.rideLegs
              .map((l) => MultimodalTripPlanner.routeKey(l.line!))
              .join('>'),
      ];
      expect(keys.toSet().length, keys.length, reason: '$from -> $to');
    }
  });

  test('conventional buses are in the network, apart from the Metro', () {
    final buses = network.lines.values.where((l) => l.group == LineGroup.bus);
    expect(buses.length, greaterThan(150));
    expect(buses.every((l) => l.stopsOnRequest && l.code != null), isTrue);
    // Integrated routes got their official street path.
    expect(network.lines['AL-254I']?.shape, isNotEmpty);
  });

  test('offers alternatives for a cross-city trip', () {
    final results = plan('san_javier', 'oriente');
    expect(results.length, greaterThan(1));
  });

  test('combines walking, buses and metro for addresses away from stations', () {
    // Diagonal 54 # 17-100 (Niquía, Bello) -> Carrera 43B # 1A Sur (Patio Bonito).
    final best = planner
        .plan(
          network,
          const LatLng(6.33871, -75.55205),
          const LatLng(6.20184, -75.57040),
        )
        .first;
    final modes = best.legs.map((l) => l.mode).toList();
    expect(modes.first, TransitMode.walk);
    expect(modes.last, TransitMode.walk);
    expect(modes, contains(TransitMode.metro));
    expect(modes, contains(TransitMode.bus));
    // Buses are boarded / left on the street, close to the addresses.
    expect(best.walkMeters, lessThan(600));
    final bus = best.rideLegs.firstWhere((l) => l.mode == TransitMode.bus);
    expect(bus.headsign, isNotNull);
  });
}
