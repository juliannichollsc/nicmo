import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import 'tile_bytes_store.dart';

TileBytesStore createTileBytesStore() => _DiskStore();

/// Tiles under the app support folder (not the cache folder, which the OS
/// may empty): they must survive for offline trips. One sub-folder per
/// area: `vector_tiles/<city>/<z>_<x>_<y>.pbf`.
class _DiskStore implements TileBytesStore {
  /// Oldest tiles of an area are removed beyond this many (~15 KB each:
  /// ~120 MB per city).
  static const _maxTiles = 8000;

  static final RegExp _tileName = RegExp(r'^(\d+)_(\d+)_(\d+)\.pbf$');

  Future<Directory>? _root;
  final Map<String, Future<Directory>> _areas = {};

  Future<Directory> get _base {
    final cached = _root;
    if (cached != null) return cached;
    final created = _root = () async {
      final base = await getApplicationSupportDirectory();
      final dir = Directory('${base.path}/vector_tiles');
      await dir.create(recursive: true);
      return dir;
    }();
    // A failed lookup is retried next time instead of being kept.
    created.then((_) {}, onError: (_) => _root = null);
    return created;
  }

  Future<Directory> _dir(String area) => _areas[area] ??= () async {
    final dir = Directory('${(await _base).path}/$area');
    await dir.create(recursive: true);
    _trim(dir).ignore();
    return dir;
  }();

  Future<File> _file(String area, int z, int x, int y) async =>
      File('${(await _dir(area)).path}/${z}_${x}_$y.pbf');

  @override
  Future<StoredTile?> read(String area, int z, int x, int y) async {
    try {
      final file = await _file(area, z, x, y);
      if (!await file.exists()) return null;
      final modified = await file.lastModified();
      return (
        bytes: await file.readAsBytes(),
        age: DateTime.now().difference(modified),
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<bool> contains(String area, int z, int x, int y) async {
    try {
      return (await _file(area, z, x, y)).exists();
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> write(String area, int z, int x, int y, Uint8List bytes) async {
    try {
      final file = await _file(area, z, x, y);
      // Write then rename: never leaves a half-written tile behind.
      final temp = File('${file.path}.part');
      await temp.writeAsBytes(bytes, flush: true);
      await temp.rename(file.path);
    } catch (error) {
      debugPrint('Tile not saved: $error');
    }
  }

  @override
  Future<void> clearArea(String area) async {
    try {
      final dir = Directory('${(await _base).path}/$area');
      _areas.remove(area);
      if (await dir.exists()) await dir.delete(recursive: true);
    } catch (error) {
      debugPrint('Tiles of $area not removed: $error');
    }
  }

  @override
  Future<int> areaBytes(String area) async {
    try {
      final dir = Directory('${(await _base).path}/$area');
      if (!await dir.exists()) return 0;
      var total = 0;
      await for (final entity in dir.list()) {
        if (entity is File) total += await entity.length();
      }
      return total;
    } catch (_) {
      return 0;
    }
  }

  @override
  Future<void> migrateLegacy(
    String? Function(int z, int x, int y) areaOf,
  ) async {
    try {
      final base = await _base;
      await for (final entity in base.list()) {
        if (entity is! File) continue;
        final name = entity.uri.pathSegments.last;
        final match = _tileName.firstMatch(name);
        final area = match == null
            ? null
            : areaOf(
                int.parse(match[1]!),
                int.parse(match[2]!),
                int.parse(match[3]!),
              );
        if (area == null) {
          await entity.delete();
        } else {
          await entity.rename('${(await _dir(area)).path}/$name');
        }
      }
    } catch (error) {
      debugPrint('Old tiles not migrated: $error');
    }
  }

  Future<void> _trim(Directory dir) async {
    try {
      final files = (await dir.list().toList()).whereType<File>().toList();
      if (files.length <= _maxTiles) return;
      final dated = [for (final file in files) (file, file.statSync().modified)]
        ..sort((a, b) => a.$2.compareTo(b.$2));
      for (final (file, _) in dated.take(files.length - _maxTiles ~/ 2)) {
        await file.delete();
      }
    } catch (_) {}
  }
}
