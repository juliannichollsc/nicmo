import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nicmo/il8n/app_localizations.dart';
import 'package:nicmo/state/trip_state.dart';
import 'package:nicmo/widget/trip/trip_search_card.dart';

Widget _app() {
  return MaterialApp(
    locale: const Locale('es'),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    home: Scaffold(
      body: ValueListenableBuilder<TripState>(
        valueListenable: tripController,
        builder: (context, state, _) =>
            TripSearchCard(state: state, onUseMyLocation: () async {}),
      ),
    ),
  );
}

void main() {
  setUp(tripController.reset);

  testWidgets('typed text survives moving to the other field', (tester) async {
    await tester.pumpWidget(_app());
    final fields = find.byType(TextField);

    await tester.tap(fields.at(0));
    await tester.enterText(fields.at(0), 'Calle 10');
    await tester.tap(fields.at(1));
    await tester.enterText(fields.at(1), 'Parque Arví');
    await tester.tap(fields.at(0));
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Calle 10'), findsOneWidget);
    expect(find.text('Parque Arví'), findsOneWidget);
  });

  testWidgets('the X clears only its own field', (tester) async {
    await tester.pumpWidget(_app());
    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'Calle 10');
    await tester.enterText(fields.at(1), 'Poblado');
    // Let the clear button finish its entrance animation.
    await tester.pump(const Duration(milliseconds: 400));

    await tester.tap(find.byTooltip('Borrar').first);
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Calle 10'), findsNothing);
    expect(find.text('Poblado'), findsOneWidget);
  });

  testWidgets('route search waits for the button', (tester) async {
    await tester.pumpWidget(_app());
    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'Niquía');
    await tester.enterText(fields.at(1), 'Poblado');
    await tester.pump(const Duration(seconds: 1));

    expect(tripController.value.status, TripStatus.idle);
    expect(find.text('Buscar mejor ruta'), findsOneWidget);
  });
}
