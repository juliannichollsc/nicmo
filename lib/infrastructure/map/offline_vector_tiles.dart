import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import 'package:nicmo/domain/city/city.dart';
import 'package:vector_map_tiles/vector_map_tiles.dart';

import 'tile_bytes_store.dart';

/// Vector tiles kept on the device for offline use.
///
/// Every tile shown is saved, and [prefetchRoute] downloads the tiles along a
/// trip in advance, so the map of the route is there even without signal
/// (for example underground or with mobile data off).
///
/// Only the cities the user activated are kept ([areas]): a tile outside
/// them is shown but not saved, so the space used grows with the cities the
/// user travels to, not with every place the map was moved to.
///
/// Tiles come from OpenFreeMap, which allows offline use; the OpenStreetMap
/// raster tiles are not prefetched (their usage policy forbids bulk
/// downloads).
class OfflineVectorTiles {
  /// Saved tiles newer than this are used without asking the network.
  static const _freshFor = Duration(days: 60);

  /// Zoom levels prefetched along a route. Vector tiles stop at 14 and are
  /// over-zoomed beyond, so 14 covers the closest zooms too.
  static const _prefetchZooms = [10, 11, 12, 13, 14];

  static final TileBytesStore _store = TileBytesStore();
  static final Map<String, OfflineVectorTileProvider> _providers = {};
  static OfflineVectorTileProvider? _latest;
  static Map<String, CityBounds> _areas = const {};
  static bool _migrated = false;

  /// Cities whose tiles are saved on the device (id → area). A margin is
  /// added so the outskirts of the metropolitan area stay offline too.
  static set areas(Map<String, CityBounds> areas) {
    _areas = {
      for (final entry in areas.entries) entry.key: entry.value.expand(0.15),
    };
    if (!_migrated && _areas.isNotEmpty) {
      _migrated = true;
      _store.migrateLegacy(areaOf).ignore();
    }
  }

  /// Area (city id) a tile is saved under, or null when it is outside every
  /// active city.
  static String? areaOf(int z, int x, int y) {
    final tile = tileBounds(z, x, y);
    for (final entry in _areas.entries) {
      if (entry.value.intersects(tile)) return entry.key;
    }
    return null;
  }

  /// Frees the space used by the map of a city.
  static Future<void> clearArea(String id) => _store.clearArea(id);

  /// Space used by the map of a city, in bytes.
  static Future<int> areaBytes(String id) => _store.areaBytes(id);

  @visibleForTesting
  static CityBounds tileBounds(int z, int x, int y) {
    final n = 1 << z;
    double lat(int row) =>
        math.atan(
          (math.exp(math.pi * (1 - 2 * row / n)) -
                  math.exp(-math.pi * (1 - 2 * row / n))) /
              2,
        ) *
        180 /
        math.pi;
    return CityBounds(
      lat(y + 1),
      x / n * 360 - 180,
      lat(y),
      (x + 1) / n * 360 - 180,
    );
  }

  /// Provider for the tile URL of a style (shared by light and dark styles,
  /// which use the same tiles).
  static OfflineVectorTileProvider provider({
    required String urlTemplate,
    required int minimumZoom,
    required int maximumZoom,
  }) {
    return _latest = _providers[urlTemplate] ??= OfflineVectorTileProvider._(
      NetworkVectorTileProvider(
        urlTemplate: urlTemplate,
        minimumZoom: minimumZoom,
        maximumZoom: maximumZoom,
      ),
      _store,
    );
  }

  /// Downloads the tiles around [path] that are not saved yet. Runs in the
  /// background; returns how many were downloaded. Without a style (never
  /// online) or without network it does nothing.
  static Future<int> prefetchRoute(List<LatLng> path) async {
    final provider = _latest;
    if (provider == null || path.isEmpty) return 0;
    final tiles = routeTiles(path, _prefetchZooms);
    var downloaded = 0;
    var failures = 0;
    final queue = tiles.toList();
    Future<void> worker() async {
      while (queue.isNotEmpty && failures < 5) {
        final tile = queue.removeLast();
        final area = areaOf(tile.z, tile.x, tile.y);
        // Outside the active cities: nothing would be kept.
        if (area == null) continue;
        if (await _store.contains(area, tile.z, tile.x, tile.y)) continue;
        try {
          await provider.provide(tile);
          downloaded++;
        } catch (_) {
          failures++; // offline: stop soon instead of trying every tile
        }
      }
    }

    await Future.wait([for (var i = 0; i < 4; i++) worker()]);
    debugPrint('Route map: ${tiles.length} tiles, $downloaded downloaded');
    return downloaded;
  }

  /// Tiles covering [path] at each zoom, with a one-tile margin around it.
  @visibleForTesting
  static Set<TileIdentity> routeTiles(List<LatLng> path, List<int> zooms) {
    final result = <TileIdentity>{};
    for (final z in zooms) {
      final n = 1 << z;
      // Sample the path finely enough not to skip any tile.
      final step = 0.25 * 360 / n;
      for (var i = 0; i < path.length; i++) {
        final a = path[i];
        final b = i + 1 < path.length ? path[i + 1] : a;
        final span = math.max(
          (b.latitude - a.latitude).abs(),
          (b.longitude - a.longitude).abs(),
        );
        final samples = math.max(1, (span / step).ceil());
        for (var s = 0; s <= samples; s++) {
          final t = s / samples;
          final (x, y) = _tileOf(
            a.latitude + (b.latitude - a.latitude) * t,
            a.longitude + (b.longitude - a.longitude) * t,
            z,
          );
          for (var dx = -1; dx <= 1; dx++) {
            for (var dy = -1; dy <= 1; dy++) {
              final tile = TileIdentity(z, x + dx, y + dy);
              if (tile.isValid()) result.add(tile);
            }
          }
        }
      }
    }
    return result;
  }

  static (int, int) _tileOf(double lat, double lng, int z) {
    final n = 1 << z;
    final x = ((lng + 180) / 360 * n).floor();
    final rad = lat * math.pi / 180;
    final y =
        ((1 - math.log(math.tan(rad) + 1 / math.cos(rad)) / math.pi) / 2 * n)
            .floor();
    return (x.clamp(0, n - 1), y.clamp(0, n - 1));
  }
}

/// Saved tile first; network otherwise (and the result saved). An old saved
/// tile is refreshed from the network but still used when offline.
class OfflineVectorTileProvider extends VectorTileProvider {
  final NetworkVectorTileProvider _network;
  final TileBytesStore _store;
  final Map<TileIdentity, Future<Uint8List>> _pending = {};

  OfflineVectorTileProvider._(this._network, this._store);

  @override
  int get maximumZoom => _network.maximumZoom;

  @override
  int get minimumZoom => _network.minimumZoom;

  @override
  TileOffset get tileOffset => _network.tileOffset;

  @override
  Future<Uint8List> provide(TileIdentity tile) {
    return _pending[tile] ??= _provide(
      tile,
    ).whenComplete(() => _pending.remove(tile));
  }

  Future<Uint8List> _provide(TileIdentity tile) async {
    final area = OfflineVectorTiles.areaOf(tile.z, tile.x, tile.y);
    if (area == null) return _network.provide(tile);
    final saved = await _store.read(area, tile.z, tile.x, tile.y);
    if (saved != null && saved.age < OfflineVectorTiles._freshFor) {
      return saved.bytes;
    }
    try {
      final bytes = await _network.provide(tile);
      await _store.write(area, tile.z, tile.x, tile.y, bytes);
      return bytes;
    } catch (_) {
      if (saved != null) return saved.bytes;
      rethrow;
    }
  }
}
