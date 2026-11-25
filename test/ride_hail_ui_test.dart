import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:nicmo/domain/transit/itinerary.dart';
import 'package:nicmo/domain/transit/transit_network.dart';
import 'package:nicmo/il8n/app_localizations.dart';
import 'package:nicmo/state/trip_state.dart';
import 'package:nicmo/widget/trip/itinerary_results.dart';

Future<void> _pump(WidgetTester tester, {required bool inTrip}) async {
  tester.view.physicalSize = const Size(1080, 2340);
  tester.view.devicePixelRatio = 3;
  final metroA = TransitLine.fromJson({
    'id': 'A',
    'name': 'Línea A',
    'mode': 'metro',
    'color': '#215CA0',
    'stations': ['s1', 's2'],
  });
  final s1 = TransitStation.fromJson({
    'id': 's1',
    'name': 'Poblado',
    'lat': 6.21,
    'lng': -75.57,
    'lines': ['A'],
  });
  final s2 = TransitStation.fromJson({
    'id': 's2',
    'name': 'Niquía',
    'lat': 6.33,
    'lng': -75.55,
    'lines': ['A'],
  });
  final network = TransitNetwork(
    lines: {'A': metroA},
    stations: {'s1': s1, 's2': s2},
  );
  final itinerary = Itinerary(
    legs: [
      const ItineraryLeg(
        mode: TransitMode.walk,
        fromName: 'My location',
        toName: 'Poblado',
        path: [LatLng(6.20, -75.57), LatLng(6.21, -75.57)],
        distanceMeters: 1330,
        durationMin: 18,
      ),
      ItineraryLeg(
        mode: TransitMode.metro,
        line: metroA,
        fromName: 'Poblado',
        toName: 'Niquía',
        stops: [s1, s2],
        path: const [LatLng(6.21, -75.57), LatLng(6.33, -75.55)],
        distanceMeters: 20000,
        durationMin: 39,
        waitMin: 2,
      ),
    ],
  );
  tripController.value = TripState(
    network: network,
    itineraries: [itinerary],
    status: TripStatus.results,
  );

  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('es'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: Scaffold(
        body: ValueListenableBuilder<TripState>(
          valueListenable: tripController,
          builder: (context, state, _) => SingleChildScrollView(
            padding: const EdgeInsets.all(30),
            child: LegTimeline(
              network: network,
              itinerary: state.selected!,
              inTrip: inTrip,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _choose(WidgetTester tester, String option) async {
  await tester.tap(find.byTooltip('Ir en carro'));
  await tester.pumpAndSettle();
  await tester.tap(find.text(option));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('while planning, car or walking only (no apps)', (tester) async {
    await _pump(tester, inTrip: false);
    await _choose(tester, 'Carro');
    expect(tripController.value.selected!.legs.first.isRideHail, isTrue);
    expect(find.text('Uber'), findsNothing);

    await _choose(tester, 'Ir caminando');
    expect(tripController.value.selected!.legs.first.isRideHail, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('during the trip a car step offers Uber and inDrive', (
    tester,
  ) async {
    await _pump(tester, inTrip: true);
    await _choose(tester, 'Carro');
    expect(find.text('Uber'), findsOneWidget);
    expect(find.text('inDrive'), findsOneWidget);

    await tester.tap(find.text('Uber'));
    await tester.pumpAndSettle();
    expect(
      tripController.value.selected!.legs.first.rideHail,
      RideHailService.uber,
    );

    // Changing their mind mid-trip: walking hides the apps, times update.
    await _choose(tester, 'Ir caminando');
    final leg = tripController.value.selected!.legs.first;
    expect(leg.isRideHail, isFalse);
    expect(leg.durationMin, closeTo(1330 / 75, 0.01));
    expect(find.text('Uber'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
