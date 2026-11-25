import 'dart:convert';
import 'dart:io';

import 'package:nicmo/domain/city/city.dart';
import 'package:nicmo/domain/transit/transit_network.dart';

/// The cities shipped with the app (assets/cities/cities.json).
CityCatalog loadCatalog() => CityCatalog.fromJson(
  jsonDecode(File('assets/cities/cities.json').readAsStringSync())
      as Map<String, dynamic>,
);

/// The network of [cityId] merged from its layer files, as the app does.
TransitNetwork loadCityNetwork(String cityId) {
  final city = loadCatalog().byId(cityId)!;
  return TransitNetwork.fromLayers([
    for (final layer in city.layers)
      if (File(layer.asset).existsSync())
        jsonDecode(File(layer.asset).readAsStringSync())
            as Map<String, dynamic>,
  ]);
}
