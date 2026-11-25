import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'support/city_network.dart';
import 'package:go_router/go_router.dart';
import 'package:nicmo/domain/transit/transit_network.dart';
import 'package:nicmo/il8n/app_localizations.dart';
import 'package:nicmo/screens/lines/lines.dart';
import 'package:nicmo/state/map_filter_state.dart';
import 'package:nicmo/state/trip_state.dart';
import 'package:nicmo/widget/map/transport_filter.dart';

final TransitNetwork network = loadCityNetwork('medellin');

Widget _app(Widget child) => MaterialApp.router(
  locale: const Locale('es'),
  supportedLocales: AppLocalizations.supportedLocales,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  routerConfig: GoRouter(
    initialLocation: '/lines',
    routes: [
      GoRoute(path: '/lines', builder: (_, _) => child),
      GoRoute(path: '/home', builder: (_, _) => const Text('MAPA')),
    ],
  ),
);

void main() {
  setUp(() {
    lineFilter.value = null;
    groupFilter.value = null;
    tripController.value = TripState(network: network);
  });

  test('official feeder routes are loaded with their path and stops', () {
    final feeders = network.lines.values
        .where((l) => l.group == LineGroup.feeder && l.drawable)
        .toList();
    expect(feeders.length, greaterThanOrEqualTo(47));
    final c3001 = network.lines['AL-C3-001']!;
    expect(c3001.shape.length, greaterThan(10));
    expect(c3001.stops, isNotEmpty);
    expect(network.stationsOf(c3001).first.name, 'Aguacatala');
    // Line O now has its official path.
    expect(network.lines['O']!.shape, isNotEmpty);
  });

  testWidgets('the transport filter unfolds and filters by kind', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(Scaffold(body: TransportFilter(network: network))),
    );
    await tester.pumpAndSettle();
    expect(find.text('Todo el transporte'), findsOneWidget);
    expect(find.text('Metroplús'), findsNothing);

    await tester.tap(find.text('Todo el transporte'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rutas integradas'));
    await tester.pumpAndSettle();

    expect(groupFilter.value, LineGroup.feeder);
    // Folded again, showing the choice.
    expect(find.text('Rutas integradas'), findsOneWidget);
    expect(find.text('Metroplús'), findsNothing);
  });

  testWidgets('lines are grouped, searchable and open on the map', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_app(const LinesScreen()));
    await tester.pumpAndSettle();
    expect(find.text('Líneas y rutas'), findsOneWidget);
    expect(find.text('Metro'), findsOneWidget);
    expect(find.text('Rutas integradas'), findsOneWidget);

    // Search by neighbourhood: the feeder section opens with its routes.
    await tester.enterText(find.byType(TextField), 'santa gema');
    await tester.pumpAndSettle();
    expect(find.text('C3-001'), findsOneWidget);
    expect(find.text('Metro'), findsNothing);

    await tester.tap(find.text('C3-001'));
    await tester.pumpAndSettle();
    expect(lineFilter.value, 'AL-C3-001');
    expect(find.text('MAPA'), findsOneWidget);
  });
}
