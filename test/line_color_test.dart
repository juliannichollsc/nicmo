import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nicmo/widget/transit/transit_style.dart';

double _contrast(Color a, Color b) {
  final la = a.computeLuminance() + 0.05;
  final lb = b.computeLuminance() + 0.05;
  return la > lb ? la / lb : lb / la;
}

void main() {
  const map = Color(0xFFF2F3F0);

  test('light line colours are darkened on the light map only', () {
    const yellowJ = Color(0xFFF7C439);
    final onLight = lineColor(yellowJ, Brightness.light);
    expect(_contrast(onLight, map), greaterThanOrEqualTo(3));
    // Same hue: still the J yellow, only darker.
    expect(
      HSLColor.fromColor(onLight).hue,
      closeTo(HSLColor.fromColor(yellowJ).hue, 2),
    );
    expect(lineColor(yellowJ, Brightness.dark), yellowJ);
  });

  test('dark line colours are kept as they are', () {
    const blueA = Color(0xFF215CA0);
    expect(lineColor(blueA, Brightness.light), blueA);
  });
}
