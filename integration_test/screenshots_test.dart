import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:integration_test/integration_test.dart';
import 'package:nicmo/il8n/app_localizations.dart';
import 'package:nicmo/main.dart' as app;
import 'package:nicmo/routes/route.dart';
import 'package:nicmo/state/active_trip_state.dart';
import 'package:nicmo/state/locale_state.dart';
import 'package:nicmo/state/location_state.dart';
import 'package:nicmo/state/onboarding_state.dart';
import 'package:nicmo/state/trip_state.dart';
import 'package:nicmo/widget/shared/lightdark.dart';

/// README screenshots on a real phone, every language in [languages], light
/// and dark, in one run (each install has to be accepted on the phone):
///
///     flutter drive -d <device> \
///       --driver=test_driver/integration_test.dart \
///       --target=integration_test/screenshots_test.dart
///
/// On a fresh install the welcome steps are captured too, three candidates
/// per screen (`_a`, `_b`, `_c`): their illustrations loop and fade out, so
/// pick the one that shows the whole scene. Accept the location permission
/// on the phone when it is asked for. Origin is the phone's position;
/// destination is [destination] (looked up on Nominatim). PNGs land in
/// `docs/screenshots/<language>/`.
const destination = 'Diagonal 54 # 17 - 100';
const languages = ['en', 'es'];

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('README screenshots', (tester) async {
    app.main();
    // The map animates forever: wait by time, never pumpAndSettle.
    Future<void> wait(int ms) async {
      for (var t = 0; t < ms; t += 100) {
        await tester.pump(const Duration(milliseconds: 100));
      }
    }

    await wait(4000);
    await binding.convertFlutterSurfaceToImage();
    // Asked first, so there is time to accept it on the phone (2 min).
    var permission = await Geolocator.requestPermission();
    for (var t = 0; t < 120 && permission == LocationPermission.denied; t++) {
      await wait(1000);
      permission = await Geolocator.checkPermission();
    }
    await wait(1000);
    final savedMode = themeNotifier.value;
    final savedLocale = LocaleState.notifier.value;

    var lang = languages.first;
    Future<void> shot(String name) async {
      await wait(600);
      await binding.takeScreenshot('$lang/$name');
    }

    AppLocalizations l10n() =>
        AppLocalizations.of(tester.element(find.byType(Scaffold).first))!;

    if (!OnboardingState.seen) {
      // Four welcome steps, the last one picks the city.
      for (var step = 1; step <= 4; step++) {
        for (lang in languages) {
          await LocaleState.setLocale(Locale(lang));
          for (final dark in [false, true]) {
            await themeNotifier.setDark(dark);
            // A theme change restarts the step's illustration animation.
            await wait(3000);
            final name = '00_welcome_${step}_${dark ? 'dark' : 'light'}';
            for (final candidate in ['a', 'b', 'c']) {
              await shot('${name}_$candidate');
              await wait(700);
            }
          }
        }
        await tester.tap(find.byType(ElevatedButton).last);
        await wait(1500);
      }
      await wait(3000);
    }

    for (lang in languages) {
      await LocaleState.setLocale(Locale(lang));
      for (final dark in [false, true]) {
        final theme = dark ? 'dark' : 'light';
        await themeNotifier.setDark(dark);
        tripController.reset();
        await wait(3000);
        await shot('01_map_$theme');

        // Origin: my location, through the same button a rider uses.
        await tester.tap(find.byIcon(Icons.my_location_rounded).first);
        for (var t = 0; t < 60 && tripController.value.origin == null; t++) {
          await wait(1000);
        }
        expect(tripController.value.origin, isNotNull, reason: 'no location');
        await wait(2000);
        final places = await tripController.search(
          destination,
          lang,
          near: locationController.value?.position,
        );
        expect(places, isNotEmpty, reason: 'Nominatim found nothing');
        tripController.setPlace(PlaceSlot.destination, places.first);
        await wait(800);

        await tester.tap(find.text(l10n().findBestRoute));
        await wait(5000);
        // The recommended route on the map, its card below.
        await shot('02_routes_$theme');

        // Sheet pulled up: every alternative and its "Start trip".
        final handle = find.text(l10n().alternatives);
        await tester.drag(handle, const Offset(0, -500));
        await wait(1500);
        await shot('03_alternatives_$theme');
        await tester.drag(handle, const Offset(0, 500));
        await wait(1500);

        // Another alternative selected: its own path on the map.
        if (tripController.value.itineraries.length > 1) {
          tripController.select(1);
          await wait(2500);
          await shot('04_alternative_route_$theme');
          tripController.select(0);
          await wait(1000);
        }

        // "Start trip" sits below the fold of the results sheet.
        appRouter.push('/trip');
        await wait(4000);
        await shot('05_trip_$theme');
        appRouter.pop();
        await wait(1500);

        appRouter.push('/lines');
        await wait(3000);
        await shot('06_lines_$theme');
        appRouter.pop();
        await wait(1500);

        appRouter.go('/settings');
        await wait(2500);
        await shot('07_settings_$theme');
        appRouter.go('/home');
        await wait(1500);
      }
    }

    // Leave the phone as it was.
    tripController.reset();
    ActiveTripStore.pending = null;
    await ActiveTripStore.clear();
    await LocaleState.setLocale(savedLocale);
    await themeNotifier.setDark(savedMode == ThemeMode.dark);
    await wait(500);
  });
}
