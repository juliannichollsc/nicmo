import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:nicmo/state/locale_state.dart';

void main() {
  const supported = [Locale('en'), Locale('es'), Locale('de'), Locale('zh')];

  test('follows the device language when it is supported', () {
    expect(
      LocaleState.resolve([const Locale('es', 'CO')], supported),
      const Locale('es'),
    );
    expect(
      LocaleState.resolve([const Locale('zh', 'CN')], supported),
      const Locale('zh'),
    );
  });

  test('uses the next device preference, then English', () {
    expect(
      LocaleState.resolve([const Locale('fr'), const Locale('de')], supported),
      const Locale('de'),
    );
    expect(
      LocaleState.resolve([const Locale('pt', 'BR')], supported),
      const Locale('en'),
    );
  });
}
