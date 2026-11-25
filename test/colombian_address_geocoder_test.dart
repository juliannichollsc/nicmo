import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:nicmo/infrastructure/geocoding/colombian_address.dart';
import 'package:nicmo/infrastructure/geocoding/colombian_address_geocoder.dart';
import 'package:nicmo/infrastructure/geocoding/nominatim_client.dart';

Map<String, dynamic> _way(
  String name,
  String barrio,
  List<List<double>> lngLat,
) => {
  'name': name,
  'display_name':
      '$name, $barrio, Medellín, Valle de Aburrá, Antioquia, Colombia',
  'lat': '${lngLat.first[1]}',
  'lon': '${lngLat.first[0]}',
  'geojson': {'type': 'LineString', 'coordinates': lngLat},
};

ColombianAddressGeocoder _geocoder(
  Map<String, List<Map<String, dynamic>>> byQuery,
) {
  final client = MockClient((request) async {
    final q = request.url.queryParameters['q']!;
    return http.Response.bytes(
      utf8.encode(jsonEncode(byQuery[q] ?? const [])),
      200,
    );
  });
  return ColombianAddressGeocoder(NominatimClient(client: client));
}

void main() {
  test('uses the corner where both streets cross', () async {
    final geocoder = _geocoder({
      // Calle runs west-east, carrera runs south-north; they cross at
      // (6.2100, -75.5700).
      'Calle 10': [
        _way('Calle 10', 'El Poblado', [
          [-75.575, 6.21],
          [-75.565, 6.21],
        ]),
      ],
      'Carrera 43A': [
        _way('Carrera 43A', 'El Poblado', [
          [-75.57, 6.205],
          [-75.57, 6.215],
        ]),
      ],
    });
    final places = await geocoder.geocode(
      ColombianAddress.tryParse('Calle 10 # 43A - 20')!,
    );
    expect(places, hasLength(1));
    expect(places.single.approximate, isFalse);
    expect(places.single.position.latitude, closeTo(6.21, 1e-5));
    expect(places.single.position.longitude, closeTo(-75.57, 1e-5));
    expect(places.single.subtitle, 'El Poblado, Medellín');
  });

  test(
    'barrio hints pick the right stretch of a repeated street name',
    () async {
      final geocoder = _geocoder({
        'Diagonal 54': [
          _way('Diagonal 54', 'Niquía', [
            [-75.553, 6.3387],
            [-75.551, 6.3387],
          ]),
          _way('Diagonal 54', 'Navarra', [
            [-75.532, 6.345],
            [-75.530, 6.345],
          ]),
        ],
      });
      final places = await geocoder.geocode(
        ColombianAddress.tryParse('diagonal 54 #17 100, poblado niquia')!,
      );
      expect(places.first.subtitle, startsWith('Niquía'));
      expect(places.every((p) => p.subtitle!.startsWith('Niquía')), isTrue);
      // Carrera 17 is not in the map data there, so the point is approximate.
      expect(places.first.approximate, isTrue);
    },
  );

  test(
    'without a corner, uses the point closest to the crossing street',
    () async {
      final geocoder = _geocoder({
        'Carrera 43B': [
          _way('Carrera 43B', 'Colón', [
            [-75.566, 6.240],
            [-75.566, 6.246],
          ]),
          _way('Carrera 43B', 'Patio Bonito', [
            [-75.5704, 6.199],
            [-75.5704, 6.205],
          ]),
        ],
        // The mapped piece of Calle 1A Sur stops 300 m before the carrera.
        'Calle 1A Sur': [
          _way('Calle 1A Sur', 'Los Naranjos', [
            [-75.567, 6.2010],
            [-75.560, 6.2010],
          ]),
        ],
      });
      final places = await geocoder.geocode(
        ColombianAddress.tryParse('Cra. 43B #1a Sur - 70')!,
      );
      expect(places.first.approximate, isTrue);
      expect(places.first.subtitle, startsWith('Patio Bonito'));
      expect(places.first.position.latitude, closeTo(6.201, 1e-3));
    },
  );

  test(
    'interpolates by number when the crossing street is not mapped',
    () async {
      final geocoder = _geocoder({
        'Diagonal 54': [
          _way('Diagonal 54', 'Niquía', [
            [-75.560, 6.3387],
            [-75.540, 6.3387],
          ]),
        ],
        // Carreras 16 and 18 are mapped 200 m apart; Carrera 17 is missing.
        'Carrera 16': [
          _way('Carrera 16', 'Niquía', [
            [-75.551, 6.335],
            [-75.551, 6.342],
          ]),
        ],
        'Carrera 18': [
          _way('Carrera 18', 'Niquía', [
            [-75.549, 6.335],
            [-75.549, 6.342],
          ]),
        ],
      });
      final places = await geocoder.geocode(
        ColombianAddress.tryParse('Diagonal 54 # 17 - 100, Niquía')!,
      );
      expect(places.first.approximate, isFalse);
      expect(places.first.position.longitude, closeTo(-75.550, 1e-4));
      expect(places.first.position.latitude, closeTo(6.3387, 1e-4));
    },
  );
}
