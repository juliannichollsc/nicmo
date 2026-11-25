import 'package:shared_preferences/shared_preferences.dart';

/// Whether the welcome slides were already shown on this device.
class OnboardingState {
  static const _key = 'onboardingSeen';
  static bool seen = false;

  static Future<void> ensureLoaded() async {
    final prefs = await SharedPreferences.getInstance();
    seen = prefs.getBool(_key) ?? false;
  }

  static Future<void> markSeen() async {
    seen = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, true);
  }
}
