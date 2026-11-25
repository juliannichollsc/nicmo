import 'dart:typed_data';

import 'tile_bytes_store_stub.dart'
    if (dart.library.io) 'tile_bytes_store_io.dart'
    as impl;

/// A stored tile and how long ago it was saved.
typedef StoredTile = ({Uint8List bytes, Duration age});

/// Persistent store of map tile bytes, keyed by area (a city id) and z/x/y.
///
/// Tiles are kept per city so that the map of a city the user no longer
/// travels to can be removed at once ([clearArea]).
abstract class TileBytesStore {
  Future<StoredTile?> read(String area, int z, int x, int y);
  Future<bool> contains(String area, int z, int x, int y);
  Future<void> write(String area, int z, int x, int y, Uint8List bytes);

  /// Removes every tile of [area].
  Future<void> clearArea(String area);

  /// Disk space used by the tiles of [area], in bytes.
  Future<int> areaBytes(String area);

  /// Moves tiles saved before the per-city folders into the area [areaOf]
  /// returns for them; tiles outside every area are deleted.
  Future<void> migrateLegacy(String? Function(int z, int x, int y) areaOf);

  /// On disk on Android / iOS; a no-op on the web (the browser caches).
  factory TileBytesStore() => impl.createTileBytesStore();
}
