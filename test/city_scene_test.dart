import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nicmo/il8n/app_localizations.dart';
import 'package:nicmo/state/city_state.dart';
import 'package:nicmo/widget/city/city_scene.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('one city shows its scene, several show Colombia', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await tester.runAsync(cityController.ensureLoaded);
    final catalog = cityController.catalog;
    final medellin = catalog.byId('medellin')!;
    final bogota = catalog.byId('bogota')!;

    expect(citySceneId([medellin]), 'medellin');
    expect(citySceneId([medellin, bogota]), 'colombia');
    expect(citySceneId([]), 'colombia');

    tester.view.physicalSize = const Size(1080, 2340); // 360 x 780 dp
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    // Every scene paints through its loop at large text without errors.
    for (final cities in [
      for (final c in catalog.cities) [c],
      [medellin, bogota],
    ]) {
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('es'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(360, 780),
              textScaler: TextScaler.linear(1.6),
            ),
            child: Scaffold(
              body: CityScene(key: UniqueKey(), cities: cities, loops: 1),
            ),
          ),
        ),
      );
      for (var i = 0; i < 12; i++) {
        await tester.pump(const Duration(milliseconds: 700));
      }
      expect(tester.takeException(), isNull, reason: citySceneId(cities));
    }
    expect(find.text('Colombia, el país de la belleza'), findsOneWidget);
  });

  testWidgets('Medellín is the city of eternal spring', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.runAsync(cityController.ensureLoaded);
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('es'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: Scaffold(
          body: CityScene(
            cities: [cityController.catalog.byId('medellin')!],
            loops: 1,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('La ciudad de la eterna primavera'), findsOneWidget);
  });
}
