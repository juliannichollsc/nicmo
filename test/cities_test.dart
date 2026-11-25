import 'dart:math' as math;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:nicmo/domain/city/city.dart';
import 'package:nicmo/domain/transit/transit_network.dart';
import 'package:nicmo/il8n/app_localizations.dart';
import 'package:nicmo/infrastructure/geocoding/search_area.dart';
import 'package:nicmo/infrastructure/map/offline_vector_tiles.dart';
import 'package:nicmo/screens/cities/cities.dart';
import 'package:nicmo/state/city_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/city_network.dart';

const _medellinCentre = LatLng(6.2476, -75.5658);
const _bogotaCentre = LatLng(4.6533, -74.0836);

(int, int) _tile(LatLng p, int z) {
  final n = 1 << z;
  final rad = p.latitude * math.pi / 180;
  final x = ((p.longitude + 180) / 360 * n).floor();
  final y =
      ((1 - math.log(math.tan(rad) + 1 / math.cos(rad)) / math.pi) / 2 * n)
          .floor();
  return (x, y);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  // Offline map tiles live in a temporary folder during the tests.
  final tiles = Directory.systemTemp.createTempSync('nicmo_tiles');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/path_provider'),
        (call) async => tiles.path,
      );
  tearDownAll(() => tiles.deleteSync(recursive: true));

  group('network layers', () {
    test('Medellín merges metro and bus layers sharing stations', () {
      final network = loadCityNetwork('medellin');
      // Rail and cable in the metro layer, buses in theirs.
      expect(network.lines['A']!.group, LineGroup.metro);
      expect(network.lines['MP1']!.group, LineGroup.metroplus);
      expect(
        network.lines.values.where((l) => l.group == LineGroup.feeder),
        isNotEmpty,
      );
      // Station lines are derived across layers: Acevedo (metro layer)
      // knows the feeder buses that end there (bus layer).
      final acevedo = network.stations['acevedo']!;
      expect(acevedo.lineIds, containsAll(['A', 'K', 'P']));
      expect(acevedo.lineIds.any((id) => id.startsWith('AL-')), isTrue);
      // Geometry comes from encoded polylines.
      expect(network.lines['A']!.shape.length, greaterThan(100));
    });

    test('a layer may use stations of an earlier layer', () {
      final network = TransitNetwork.fromLayers([
        {
          'lines': [
            {
              'id': 'A',
              'name': 'Línea A',
              'mode': 'metro',
              'stations': ['x', 'y'],
            },
          ],
          'stations': [
            {'id': 'x', 'name': 'X', 'lat': 6.0, 'lng': -75.0},
            {'id': 'y', 'name': 'Y', 'lat': 6.1, 'lng': -75.0},
          ],
        },
        {
          'lines': [
            {
              'id': 'BU-1',
              'name': 'Ruta 1',
              'code': '1',
              'mode': 'bus',
              'stations': ['y', 'z'],
              'path': '_p~iF~ps|U_ulLnnqC_mqNvxq`@',
            },
          ],
          'stations': [
            {'id': 'z', 'name': 'Z', 'lat': 6.2, 'lng': -75.0},
          ],
        },
      ]);
      final bus = network.lines['BU-1']!;
      expect(bus.group, LineGroup.bus);
      expect(bus.stopsOnRequest, isTrue);
      expect(bus.code, '1');
      expect(network.stations['y']!.lineIds, ['A', 'BU-1']);
      expect(network.lines['A']!.stopsOnRequest, isFalse);
    });

    test('decodes the reference encoded polyline', () {
      // Example of the Google polyline documentation.
      final points = decodePolyline('_p~iF~ps|U_ulLnnqC_mqNvxq`@');
      expect(points, [
        const LatLng(38.5, -120.2),
        const LatLng(40.7, -120.95),
        const LatLng(43.252, -126.453),
      ]);
    });

    test('groups split into Metro and buses', () {
      expect(LineGroup.metroGroups.every((g) => !g.isBus), isTrue);
      expect(LineGroup.busGroups.every((g) => g.isBus), isTrue);
      expect(LineGroup.bus.isStreetBus, isTrue);
      expect(LineGroup.metroplus.isStreetBus, isFalse);
    });
  });

  group('catalog', () {
    test('every available city has its layer files; others have none', () {
      final catalog = loadCatalog();
      final medellin = catalog.byId('medellin')!;
      expect(medellin.available, isTrue);
      expect(medellin.layers.map((l) => l.id), containsAll(['metro', 'buses']));
      for (final city in catalog.cities.where((c) => !c.available)) {
        expect(city.layers, isEmpty, reason: city.id);
      }
    });

    test('finds the city at a position', () {
      final catalog = loadCatalog();
      expect(catalog.at(_medellinCentre)?.id, 'medellin');
      expect(catalog.at(_bogotaCentre)?.id, 'bogota');
      expect(catalog.at(const LatLng(0, 0)), isNull);
    });
  });

  group('city selection', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('nothing chosen on a new install', () async {
      final controller = CityController();
      await controller.ensureLoaded();
      expect(controller.current, isNull);
    });

    test('users from before cities keep Medellín', () async {
      final controller = CityController();
      await controller.ensureLoaded(migrateLegacy: true);
      expect(controller.current?.id, 'medellin');
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('city.current'), 'medellin');
    });

    test('choosing, adding and removing cities is saved', () async {
      final controller = CityController();
      await controller.ensureLoaded();
      final medellin = controller.catalog.byId('medellin')!;
      final bogota = controller.catalog.byId('bogota')!;
      final cali = controller.catalog.byId('cali')!;

      await controller.choose(medellin);
      await controller.activate(cali);
      await controller.choose(bogota);
      expect(controller.current?.id, 'bogota');
      expect(controller.value.active.map((c) => c.id), [
        'medellin',
        'cali',
        'bogota',
      ]);
      // Searches follow the city in use.
      expect(SearchArea.current.municipalities, contains('Soacha'));

      // The current city cannot be removed.
      await controller.deactivate(bogota);
      expect(controller.value.isActive(bogota), isTrue);
      await controller.deactivate(cali);

      final reloaded = CityController();
      await reloaded.ensureLoaded();
      expect(reloaded.current?.id, 'bogota');
      expect(reloaded.value.active.map((c) => c.id), ['medellin', 'bogota']);
    });

    test('only tiles of active cities are kept on the device', () async {
      final controller = CityController();
      await controller.ensureLoaded();
      await controller.choose(controller.catalog.byId('medellin')!);

      final (mx, my) = _tile(_medellinCentre, 14);
      final (bx, by) = _tile(_bogotaCentre, 14);
      expect(OfflineVectorTiles.areaOf(14, mx, my), 'medellin');
      expect(OfflineVectorTiles.areaOf(14, bx, by), isNull);

      await controller.activate(controller.catalog.byId('bogota')!);
      expect(OfflineVectorTiles.areaOf(14, bx, by), 'bogota');
    });
  });

  testWidgets('cities screen: current city, add another, search', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await tester.runAsync(cityController.ensureLoaded);
    await tester.runAsync(
      () => cityController.choose(cityController.catalog.byId('medellin')!),
    );
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp.router(
        locale: const Locale('es'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        routerConfig: GoRouter(
          initialLocation: '/cities',
          routes: [
            GoRoute(path: '/cities', builder: (_, _) => const CitiesScreen()),
            GoRoute(path: '/home', builder: (_, _) => const Text('MAPA')),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('ESTÁS EN'), findsOneWidget);
    expect(find.text('Medellín'), findsOneWidget);
    expect(find.text('Agregar'), findsWidgets);

    // Search narrows the catalog.
    await tester.enterText(find.byType(TextField), 'transmilenio');
    await tester.pumpAndSettle();
    expect(find.text('Bogotá'), findsOneWidget);
    expect(find.text('Cali'), findsNothing);

    await tester.tap(find.text('Agregar'));
    await tester.pumpAndSettle();
    expect(find.text('TUS CIUDADES'), findsOneWidget);
    expect(
      cityController.value.active.map((c) => c.id),
      containsAll(['medellin', 'bogota']),
    );
    // Adding does not move the map.
    expect(cityController.current?.id, 'medellin');

    // Going to a city makes it current and opens the map.
    await tester.tap(find.text('Ir'));
    await tester.pumpAndSettle();
    expect(find.text('MAPA'), findsOneWidget);
    expect(cityController.current?.id, 'bogota');
    expect(tester.takeException(), isNull);
  });

  test('bounds helpers', () {
    const b = CityBounds(6, -76, 7, -75);
    expect(b.viewBox, '-76.0,7.0,-75.0,6.0');
    expect(b.contains(const LatLng(6.5, -75.5)), isTrue);
    expect(b.expand(0.1).contains(const LatLng(7.05, -75.5)), isTrue);
    expect(formatBytes(1536), '2 KB');
    expect(formatBytes(5 * 1024 * 1024), '5.0 MB');
  });
}
