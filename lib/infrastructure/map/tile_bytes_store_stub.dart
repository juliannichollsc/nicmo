import 'dart:typed_data';

import 'tile_bytes_store.dart';

TileBytesStore createTileBytesStore() => _NoStore();

class _NoStore implements TileBytesStore {
  @override
  Future<StoredTile?> read(String area, int z, int x, int y) async => null;

  @override
  Future<bool> contains(String area, int z, int x, int y) async => false;

  @override
  Future<void> write(String area, int z, int x, int y, Uint8List bytes) async {}

  @override
  Future<void> clearArea(String area) async {}

  @override
  Future<int> areaBytes(String area) async => 0;

  @override
  Future<void> migrateLegacy(
    String? Function(int z, int x, int y) areaOf,
  ) async {}
}
