import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:nicmo/il8n/app_localizations.dart';
import 'package:nicmo/screens/onboarding/onboarding.dart';
import 'package:nicmo/state/city_state.dart';
import 'package:nicmo/state/onboarding_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The slides loop their animations forever, so pumpAndSettle would never
/// finish: advance the page transition frame by frame instead.
Future<void> _advance(WidgetTester tester) async {
  for (var i = 0; i < 20; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  testWidgets('three slides, the city, then the map; shown only once', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await OnboardingState.ensureLoaded();
    await tester.runAsync(cityController.ensureLoaded);
    expect(cityController.current, isNull);
    expect(OnboardingState.seen, isFalse);

    tester.view.physicalSize = const Size(1080, 2340); // 360 x 780 dp
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final router = GoRouter(
      initialLocation: '/welcome',
      routes: [
        GoRoute(path: '/welcome', builder: (_, _) => const OnboardingScreen()),
        GoRoute(path: '/home', builder: (_, _) => const Text('MAPA')),
      ],
    );
    await tester.pumpWidget(
      MaterialApp.router(
        locale: const Locale('es'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        routerConfig: router,
      ),
    );
    await _advance(tester);

    expect(find.text('Dinos a dónde vas'), findsOneWidget);
    await tester.tap(find.text('Siguiente'));
    await _advance(tester);
    expect(find.text('La mejor combinación'), findsOneWidget);
    await tester.tap(find.text('Siguiente'));
    await _advance(tester);
    expect(find.text('Viaja paso a paso'), findsOneWidget);

    await tester.tap(find.text('Siguiente'));
    await _advance(tester);
    expect(find.text('¿En qué ciudad te vas a mover?'), findsOneWidget);

    // Only Medellín (the Valle de Aburrá) for now, already chosen.
    expect(find.text('Medellín'), findsOneWidget);
    expect(find.text('Bogotá'), findsNothing);
    await tester.tap(find.text('Comenzar'));
    await _advance(tester);
    expect(find.text('MAPA'), findsOneWidget);
    expect(OnboardingState.seen, isTrue);
    expect(cityController.current?.id, 'medellin');
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('city.current'), 'medellin');
    expect(tester.takeException(), isNull);
  });
}
