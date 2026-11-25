import 'package:flutter/material.dart';
import 'package:nicmo/theme/metro_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _darkBackground = 'assets/resources/imgs/background_metro.png';
const String _lightBackground =
    'assets/resources/imgs/background_metro_light.png';

final ThemeNotifier themeNotifier = ThemeNotifier();

String themeBackground(BuildContext context) {
  return Theme.of(context).brightness == Brightness.dark
      ? _darkBackground
      : _lightBackground;
}

/// App theme. Follows the device (light/dark) until the user picks one,
/// then that choice is stored and restored on the next launch.
class ThemeNotifier extends ValueNotifier<ThemeMode> {
  static const _key = 'themeMode';

  ThemeNotifier() : super(ThemeMode.system);

  Future<void> ensureLoaded() async {
    final prefs = await SharedPreferences.getInstance();
    value = switch (prefs.getString(_key)) {
      'dark' => ThemeMode.dark,
      'light' => ThemeMode.light,
      _ => ThemeMode.system,
    };
  }

  /// Brightness actually shown (resolves "system").
  Brightness get effectiveBrightness => switch (value) {
    ThemeMode.dark => Brightness.dark,
    ThemeMode.light => Brightness.light,
    ThemeMode.system =>
      WidgetsBinding.instance.platformDispatcher.platformBrightness,
  };

  Future<void> setDark(bool dark) async {
    value = dark ? ThemeMode.dark : ThemeMode.light;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, dark ? 'dark' : 'light');
  }
}

class LightDarkWidget extends StatelessWidget {
  const LightDarkWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, _, _) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isDark ? Icons.dark_mode : Icons.light_mode,
              color: isDark ? Colors.white : Colors.black87,
              size: 20,
            ),
            const SizedBox(width: 8),
            Switch(
              inactiveTrackColor: Colors.black26,
              inactiveThumbColor: Colors.white,
              activeTrackColor: MetroPalette.green,
              activeThumbColor: Colors.white,
              value: isDark,
              onChanged: themeNotifier.setDark,
            ),
          ],
        );
      },
    );
  }
}
