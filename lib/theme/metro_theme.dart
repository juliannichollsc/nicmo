import 'package:flutter/material.dart';
import 'package:nicmo/routes/transitions.dart';

/// Nicmo palette: one hue (~105°, the Metro de Medellín green #65BC4B) in
/// several tones, so light and dark modes stay monochromatic and calm.
///
/// Contrast (WCAG): white text on [green] 4.7:1; [green] as an icon on white
/// 4.7:1 and on [surface] 3.5:1; [greenBright] on [night] 10.3:1.
class MetroPalette {
  /// Corporate green. Decorative fills only (headers, badges, artwork).
  static const Color brand = Color(0xFF65BC4B);

  /// Actions: buttons with white text, selected states, icons.
  static const Color green = Color(0xFF41822B);

  /// Accent on dark surfaces (highlights, active text).
  static const Color greenBright = Color(0xFF8BD373);
  static const Color greenDeep = Color(0xFF2D5D1D);

  // Dark mode surfaces: low-saturation greens of the same hue.
  static const Color night = Color(0xFF10150F);
  static const Color surface = Color(0xFF1A2118);
  static const Color surfaceHigh = Color(0xFF262F23);

  // Light mode surfaces.
  static const Color paper = Color(0xFFF6FAF5);
  static const Color paperHigh = Color(0xFFE8F0E6);
  static const Color ink = Color(0xFF1C2518);

  /// Soft text on green / dark surfaces.
  static const Color mint = Color(0xFFC8E3BF);
  static const Color walk = Color(0xFF9AA696);

  /// Walking legs replaced by a ride-hailing car.
  static const Color car = Color(0xFF78909C);

  /// Walking / car route colours on the light theme: dark enough to read
  /// over the pale map.
  static const Color walkOnLight = Color(0xFF3B4636);
  static const Color carOnLight = Color(0xFF37474F);

  /// Nicmo logo badge (light blue).
  static const Color logoBlue = Color(0xFF6CC8F2);
  static const Color logoBlueDeep = Color(0xFF3FA9DE);
}

class MetroTheme {
  static const _font = 'Roboto';

  static ThemeData dark() {
    const scheme = ColorScheme.dark(
      primary: MetroPalette.greenBright,
      onPrimary: MetroPalette.night,
      primaryContainer: MetroPalette.greenDeep,
      onPrimaryContainer: MetroPalette.mint,
      secondary: MetroPalette.green,
      onSecondary: Colors.white,
      surface: MetroPalette.surface,
      onSurface: Color(0xFFE6EDE3),
      surfaceContainerHighest: MetroPalette.surfaceHigh,
      outline: Color(0xFF3E4A3A),
    );
    return _base(scheme).copyWith(
      scaffoldBackgroundColor: MetroPalette.night,
      appBarTheme: const AppBarTheme(
        backgroundColor: MetroPalette.surface,
        foregroundColor: Color(0xFFE6EDE3),
        iconTheme: IconThemeData(color: Color(0xFFE6EDE3)),
      ),
      drawerTheme: const DrawerThemeData(backgroundColor: MetroPalette.surface),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: MetroPalette.surface,
        selectedItemColor: MetroPalette.greenBright,
        unselectedItemColor: Colors.white70,
      ),
      inputDecorationTheme: InputDecorationTheme(
        contentPadding: const EdgeInsets.all(10),
        border: const OutlineInputBorder(),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: MetroPalette.greenBright, width: 1.5),
        ),
        hintStyle: TextStyle(color: Colors.grey.shade400, fontFamily: _font),
        labelStyle: const TextStyle(color: Colors.white),
      ),
      textTheme: _text(const Color(0xFFE6EDE3)),
      elevatedButtonTheme: _button(MetroPalette.green, Colors.white),
      switchTheme: SwitchThemeData(
        thumbColor: const WidgetStatePropertyAll(Colors.white),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? MetroPalette.green
              : Colors.white24,
        ),
      ),
    );
  }

  static ThemeData light() {
    const scheme = ColorScheme.light(
      primary: MetroPalette.green,
      onPrimary: Colors.white,
      primaryContainer: MetroPalette.paperHigh,
      onPrimaryContainer: MetroPalette.greenDeep,
      secondary: MetroPalette.greenDeep,
      onSecondary: Colors.white,
      surface: Colors.white,
      onSurface: MetroPalette.ink,
      surfaceContainerHighest: MetroPalette.paperHigh,
      outline: Color(0xFFC5D2C0),
    );
    return _base(scheme).copyWith(
      scaffoldBackgroundColor: MetroPalette.paper,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: MetroPalette.ink,
        elevation: 1,
        iconTheme: IconThemeData(color: MetroPalette.ink),
      ),
      drawerTheme: const DrawerThemeData(backgroundColor: Colors.white),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: MetroPalette.green,
        unselectedItemColor: Colors.black54,
      ),
      inputDecorationTheme: InputDecorationTheme(
        contentPadding: const EdgeInsets.all(10),
        border: const OutlineInputBorder(),
        hintStyle: TextStyle(color: Colors.grey.shade600, fontFamily: _font),
        labelStyle: const TextStyle(color: Colors.black87),
      ),
      textTheme: _text(MetroPalette.ink),
      elevatedButtonTheme: _button(MetroPalette.green, Colors.white),
      switchTheme: SwitchThemeData(
        thumbColor: const WidgetStatePropertyAll(Colors.white),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? MetroPalette.green
              : Colors.black26,
        ),
      ),
    );
  }

  static ThemeData _base(ColorScheme scheme) {
    return ThemeData(
      colorScheme: scheme,
      pageTransitionsTheme: metroPageTransitionsTheme,
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static TextTheme _text(Color color) {
    return TextTheme(
      bodyLarge: TextStyle(color: color, fontFamily: _font),
      bodyMedium: TextStyle(color: color, fontFamily: _font),
      labelLarge: TextStyle(color: color, fontFamily: _font),
    );
  }

  static ElevatedButtonThemeData _button(Color background, Color foreground) {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: background,
        foregroundColor: foreground,
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 10),
        textStyle: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          fontFamily: _font,
        ),
      ),
    );
  }
}
