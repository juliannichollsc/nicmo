import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lottie/lottie.dart';

void main() {
  for (final name in ['metro_train', 'metrocable', 'arrival']) {
    test('$name.json is a valid Lottie composition', () async {
      final bytes = await File('assets/animations/$name.json').readAsBytes();
      final composition = await LottieComposition.fromBytes(bytes);
      expect(composition.duration, const Duration(seconds: 3));
      expect(composition.layers, isNotEmpty);
    });
  }

  for (final name in ['metro_train', 'metrocable']) {
    test('$name.gif exists', () {
      expect(File('assets/animations/$name.gif').lengthSync(), greaterThan(0));
    });
  }
}
