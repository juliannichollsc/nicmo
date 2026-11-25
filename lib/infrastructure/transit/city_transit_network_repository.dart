import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:nicmo/domain/city/city.dart';
import 'package:nicmo/domain/transit/transit_network.dart';
import 'package:nicmo/domain/transit/transit_services.dart';

/// The network of the city in use, built from its layer files (metro,
/// buses...). Only one city is kept in memory: changing city drops the
/// previous network.
class CityTransitNetworkRepository implements TransitNetworkRepository {
  final AssetBundle bundle;

  /// City whose network [load] returns.
  final City? Function() city;

  String? _cityId;
  Future<TransitNetwork>? _cache;

  CityTransitNetworkRepository({required this.city, AssetBundle? bundle})
    : bundle = bundle ?? rootBundle;

  @override
  Future<TransitNetwork> load() {
    final current = city();
    if (current?.id != _cityId) {
      _cityId = current?.id;
      _cache = null;
    }
    return _cache ??= _load(current);
  }

  Future<TransitNetwork> _load(City? city) async {
    if (city == null || city.layers.isEmpty) return TransitNetwork.empty;
    final raws = await Future.wait([
      for (final layer in city.layers)
        // A missing optional layer leaves the others usable.
        bundle.loadString(layer.asset).catchError((Object error) {
          debugPrint('Layer ${layer.asset} not loaded: $error');
          return '';
        }),
    ]);
    // Decoding a few MB of JSON takes a while: off the UI thread.
    return compute(_parse, raws);
  }

  static TransitNetwork _parse(List<String> raws) => TransitNetwork.fromLayers([
    for (final raw in raws)
      if (raw.isNotEmpty) jsonDecode(raw) as Map<String, dynamic>,
  ]);
}

/// The catalog of cities shipped with the app.
class AssetCityCatalogRepository {
  static const String assetPath = 'assets/cities/cities.json';

  final AssetBundle bundle;

  AssetCityCatalogRepository({AssetBundle? bundle})
    : bundle = bundle ?? rootBundle;

  Future<CityCatalog> load() async => CityCatalog.fromJson(
    jsonDecode(await bundle.loadString(assetPath)) as Map<String, dynamic>,
  );
}
