import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nicmo/infrastructure/map/map_style_store.dart';
import 'package:nicmo/infrastructure/map/offline_vector_tiles.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('restores the saved style without network', () async {
    final style = jsonDecode(
      File('test/fixtures/positron_style.json').readAsStringSync(),
    );
    SharedPreferences.setMockInitialValues({
      'mapStyle.light': jsonEncode({
        'savedAt': DateTime.now().toIso8601String(),
        'style': style,
        'tiles': 'https://tiles.openfreemap.org/planet/x/{z}/{x}/{y}.pbf',
        'minzoom': 0,
        'maxzoom': 14,
      }),
    });

    expect(MapStyleStore.ready(Brightness.light), isNull);
    await MapStyleStore.restore();

    final restored = MapStyleStore.ready(Brightness.light);
    expect(restored, isNotNull);
    expect(restored!.theme.layers, isNotEmpty);
    expect(restored.providers.tileProviderBySource.keys, ['openmaptiles']);
    expect(
      restored.providers.tileProviderBySource['openmaptiles'],
      isA<OfflineVectorTileProvider>(),
    );
    // Same object on load: no download when a saved copy exists.
    expect(await MapStyleStore.load(Brightness.light), same(restored));
    expect(MapStyleStore.ready(Brightness.dark), isNull);
  });
}
