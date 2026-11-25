import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:nicmo/infrastructure/map/offline_vector_tiles.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vector_map_tiles/vector_map_tiles.dart';
import 'package:vector_tile_renderer/vector_tile_renderer.dart' as vtr;

/// Vector base-map styles (OpenFreeMap) kept on the device.
///
/// The style and its tile URL are downloaded once and saved, so the map is
/// painted straight away on the next launches, also without network. They
/// are refreshed in the background every [_refreshAfter]; the refreshed copy
/// is used from the next launch, so the tiles already rendered and cached on
/// disk keep matching the style in use.
class MapStyleStore {
  static const _urls = {
    Brightness.light: 'https://tiles.openfreemap.org/styles/positron',
    Brightness.dark: 'https://tiles.openfreemap.org/styles/dark',
  };
  static const _vectorSource = 'openmaptiles';
  static const _refreshAfter = Duration(days: 30);
  static const _timeout = Duration(seconds: 20);

  static final Map<Brightness, Style> _ready = {};
  static final Map<Brightness, Future<Style>> _loading = {};
  static bool _restored = false;

  /// Style available right now (saved or already downloaded), if any.
  static Style? ready(Brightness brightness) => _ready[brightness];

  /// Restores the saved styles. Fast (local); call before the first frame.
  static Future<void> restore() async {
    if (_restored) return;
    _restored = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      for (final brightness in Brightness.values) {
        final saved = prefs.getString(_key(brightness));
        if (saved == null) continue;
        final data = jsonDecode(saved) as Map<String, dynamic>;
        _ready[brightness] = _build(data);
        final savedAt = DateTime.tryParse(data['savedAt'] as String? ?? '');
        if (savedAt == null ||
            DateTime.now().difference(savedAt) > _refreshAfter) {
          _download(brightness, prefs).ignore();
        }
      }
    } catch (error) {
      debugPrint('Saved map style unreadable: $error');
    }
  }

  /// The style for [brightness]: saved copy, or downloaded (and saved).
  static Future<Style> load(Brightness brightness) async {
    final ready = _ready[brightness];
    if (ready != null) return ready;
    final style = await (_loading[brightness] ??= _download(
      brightness,
      await SharedPreferences.getInstance(),
    ).whenComplete(() => _loading.remove(brightness)));
    return _ready[brightness] ??= style;
  }

  static Future<Style> _download(
    Brightness brightness,
    SharedPreferences prefs,
  ) async {
    final styleText = await _get(_urls[brightness]!);
    final style = jsonDecode(styleText) as Map<String, dynamic>;
    final source = (style['sources'] as Map)[_vectorSource] as Map;
    Map tileJson = source;
    if (source['url'] is String) {
      tileJson = jsonDecode(await _get(source['url'] as String)) as Map;
    }
    final data = <String, dynamic>{
      'savedAt': DateTime.now().toIso8601String(),
      'style': style,
      'tiles': (tileJson['tiles'] as List).first as String,
      'minzoom': tileJson['minzoom'] as int? ?? 0,
      'maxzoom': tileJson['maxzoom'] as int? ?? 14,
    };
    final built = _build(data);
    await prefs.setString(_key(brightness), jsonEncode(data));
    return built;
  }

  static Style _build(Map<String, dynamic> data) {
    return Style(
      theme: vtr.ThemeReader().read(data['style'] as Map<String, dynamic>),
      providers: TileProviders({
        // Tiles saved on the device for offline use.
        _vectorSource: OfflineVectorTiles.provider(
          urlTemplate: data['tiles'] as String,
          minimumZoom: data['minzoom'] as int,
          maximumZoom: data['maxzoom'] as int,
        ),
      }),
    );
  }

  static Future<String> _get(String url) async {
    final response = await http.get(Uri.parse(url)).timeout(_timeout);
    if (response.statusCode != 200) {
      throw http.ClientException('HTTP ${response.statusCode}', Uri.parse(url));
    }
    return utf8.decode(response.bodyBytes);
  }

  static String _key(Brightness brightness) => 'mapStyle.${brightness.name}';
}
