import 'package:flutter/material.dart';
import 'package:nicmo/app_info.dart';
import 'package:nicmo/il8n/app_localizations.dart';
import 'package:nicmo/infrastructure/ads/ads_service.dart';
import 'package:nicmo/state/active_trip_state.dart';
import 'package:nicmo/state/city_state.dart';
import 'package:nicmo/state/onboarding_state.dart';
import 'package:nicmo/state/locale_state.dart';
import 'package:nicmo/state/trip_state.dart';
import 'package:nicmo/theme/metro_theme.dart';
import 'package:nicmo/widget/map/base_map_layer.dart';
import 'package:nicmo/widget/shared/lightdark.dart';
import 'routes/route.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LocaleState.ensureLoaded();
  await OnboardingState.ensureLoaded();
  // The city is chosen at the end of the welcome slides; earlier installs
  // (Medellín only) keep Medellín.
  await cityController.ensureLoaded(migrateLegacy: OnboardingState.seen);
  bindTripToCity();
  await themeNotifier.ensureLoaded();
  // Saved map style (local, fast) so the map paints on its first frame,
  // also offline; downloaded in the background the first time.
  await BaseMapLayer.preload(themeNotifier.effectiveBrightness);
  themeNotifier.addListener(
    () => BaseMapLayer.preload(themeNotifier.effectiveBrightness).ignore(),
  );
  // A trip in progress when the app was closed is resumed (also offline).
  if (cityController.current == null) {
    // Nothing to load until a city is chosen.
  } else if (await ActiveTripStore.hasSaved()) {
    final active = await ActiveTripStore.load(
      await tripController.ensureNetwork(),
    );
    if (active != null) {
      tripController.resume(
        itinerary: active.itinerary,
        origin: active.origin,
        destination: active.destination,
      );
      ActiveTripStore.pending = active;
    }
  } else {
    tripController.ensureNetwork().ignore();
  }
  runApp(const MyApp());
  // After runApp and without awaiting: the consent form (EEA/UK only)
  // shows over the app, and ads must never delay the map.
  AdsService.start().ignore();
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, themeMode, _) {
        return ValueListenableBuilder<Locale?>(
          valueListenable: LocaleState.notifier,
          builder: (context, locale, _) {
            return MaterialApp.router(
              title: kAppName,
              debugShowCheckedModeBanner: false,
              // null follows the device language (see LocaleState).
              locale: locale,
              localeListResolutionCallback: LocaleState.resolve,
              supportedLocales: AppLocalizations.supportedLocales,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              // System theme until the user picks one (persisted).
              themeMode: themeMode,
              theme: MetroTheme.light(),
              darkTheme: MetroTheme.dark(),
              routerConfig: appRouter,
            );
          },
        );
      },
    );
  }
}
