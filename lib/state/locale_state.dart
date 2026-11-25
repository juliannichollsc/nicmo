import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _localeKey = 'locale';

/// App language. `null` means "follow the device language"; a value is the
/// language the user picked in Settings, persisted across launches.
class LocaleState {
  static const List<String> supportedLanguageCodes = ['en', 'es', 'de', 'zh'];
  static const String fallbackLanguageCode = 'en';

  static final ValueNotifier<Locale?> notifier = ValueNotifier<Locale?>(null);
  static SharedPreferences? _prefs;

  static Future<void> ensureLoaded() async {
    _prefs ??= await SharedPreferences.getInstance();
    final code = _prefs!.getString(_localeKey);
    notifier.value = code != null && supportedLanguageCodes.contains(code)
        ? Locale(code)
        : null;
  }

  /// Picks a language, or `null` to go back to the device language.
  static Future<void> setLocale(Locale? locale) async {
    _prefs ??= await SharedPreferences.getInstance();
    if (locale == null ||
        !supportedLanguageCodes.contains(locale.languageCode)) {
      await _prefs!.remove(_localeKey);
      notifier.value = null;
      return;
    }
    await _prefs!.setString(_localeKey, locale.languageCode);
    notifier.value = Locale(locale.languageCode);
  }

  /// Chooses the supported language closest to the device preferences.
  static Locale resolve(List<Locale>? deviceLocales, Iterable<Locale> _) {
    for (final locale in deviceLocales ?? const <Locale>[]) {
      if (supportedLanguageCodes.contains(locale.languageCode)) {
        return Locale(locale.languageCode);
      }
    }
    return const Locale(fallbackLanguageCode);
  }
}
