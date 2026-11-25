import 'package:flutter_test/flutter_test.dart';
import 'package:nicmo/infrastructure/geocoding/colombian_address.dart';

void main() {
  test('diagonal with barrio hints', () {
    final a = ColombianAddress.tryParse('diagonal 54 #17 100, poblado niquia')!;
    expect(a.primaryName, 'Diagonal 54');
    expect(a.crossNames, ['Carrera 17', 'Transversal 17']);
    expect(a.meters, 100);
    expect(a.hints, ['poblado', 'niquia']);
    expect(a.label, 'Diagonal 54 # 17 - 100');
  });

  test('abbreviated carrera with letters and Sur', () {
    final a = ColombianAddress.tryParse('Cra. 43B #1a Sur - 70')!;
    expect(a.primaryName, 'Carrera 43B');
    expect(a.crossNames, ['Calle 1A Sur', 'Diagonal 1A Sur']);
    expect(a.meters, 70);
    expect(a.hints, isEmpty);
  });

  test('common spellings', () {
    expect(
      ColombianAddress.tryParse('Cl 10 # 43A-20')!.label,
      'Calle 10 # 43A - 20',
    );
    expect(
      ColombianAddress.tryParse('Calle 10 No. 43-20 Sur')!.primaryName,
      'Calle 10 Sur',
    );
    expect(ColombianAddress.tryParse('Kr 80 N° 33-15, Medellín')!.hints, [
      'medellin',
    ]);
    expect(
      ColombianAddress.tryParse('Tv 39B # 74-58')!.crossNames.first,
      'Calle 74',
    );
    expect(
      ColombianAddress.tryParse('Carrera 43A #1 Sur-50')!.crossNames.first,
      'Calle 1 Sur',
    );
  });

  test('ignores places that are not addresses', () {
    expect(ColombianAddress.tryParse('Parque Arví'), isNull);
    expect(ColombianAddress.tryParse('San Antonio'), isNull);
    expect(ColombianAddress.tryParse('Carrera 43B'), isNull);
  });
}
