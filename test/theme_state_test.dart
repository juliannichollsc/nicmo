import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nicmo/widget/shared/lightdark.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('follows the system until the user picks a theme', () async {
    SharedPreferences.setMockInitialValues({});
    final theme = ThemeNotifier();
    await theme.ensureLoaded();
    expect(theme.value, ThemeMode.system);
  });

  test('the chosen theme is restored on the next launch', () async {
    SharedPreferences.setMockInitialValues({});
    await ThemeNotifier().setDark(false);

    final reopened = ThemeNotifier();
    await reopened.ensureLoaded();
    expect(reopened.value, ThemeMode.light);
    expect(reopened.effectiveBrightness, Brightness.light);
  });
}
