import 'package:flutter/foundation.dart';
import 'package:nicmo/domain/city/city.dart';
import 'package:nicmo/infrastructure/geocoding/search_area.dart';
import 'package:nicmo/infrastructure/map/offline_vector_tiles.dart';
import 'package:nicmo/infrastructure/transit/city_transit_network_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The city on the map ([current]) and the cities the user activated
/// ([active]: the current one plus others they travel to). Only active
/// cities keep their map on the device.
@immutable
class CitySelection {
  final City? current;
  final List<City> active;

  const CitySelection({this.current, this.active = const []});

  bool isActive(City city) => active.any((c) => c.id == city.id);
}

class CityController extends ValueNotifier<CitySelection> {
  static const _currentKey = 'city.current';
  static const _activeKey = 'city.active';

  /// City of users who installed the app when it covered only Medellín.
  static const legacyCity = 'medellin';

  final AssetCityCatalogRepository catalogRepository;
  CityCatalog catalog = const CityCatalog([]);

  CityController({AssetCityCatalogRepository? catalogRepository})
    : catalogRepository = catalogRepository ?? AssetCityCatalogRepository(),
      super(const CitySelection());

  City? get current => value.current;

  /// Loads the catalog and the saved choice. [migrateLegacy]: a user who
  /// already went through the welcome slides before cities existed keeps
  /// Medellín instead of being asked again.
  Future<void> ensureLoaded({bool migrateLegacy = false}) async {
    catalog = await catalogRepository.load();
    final prefs = await SharedPreferences.getInstance();
    var currentId = prefs.getString(_currentKey);
    var activeIds = prefs.getStringList(_activeKey) ?? const <String>[];
    final migrate = currentId == null && migrateLegacy;
    if (migrate) {
      currentId = legacyCity;
      activeIds = const [legacyCity];
    }
    _set(catalog.byId(currentId), [
      for (final id in activeIds) ?catalog.byId(id),
    ]);
    if (migrate) await _save();
  }

  /// Travels to [city]: it becomes the city on the map and is activated.
  Future<void> choose(City city) async {
    if (city.id == current?.id) return;
    _set(city, [...value.active.where((c) => c.id != city.id), city]);
    await _save();
  }

  /// Keeps the map of [city] on the device without moving to it.
  Future<void> activate(City city) async {
    if (value.isActive(city)) return;
    _set(current, [...value.active, city]);
    await _save();
  }

  /// Stops keeping [city] (not the current one) and frees its map.
  Future<void> deactivate(City city) async {
    if (city.id == current?.id) return;
    _set(current, [...value.active.where((c) => c.id != city.id)]);
    await _save();
    await OfflineVectorTiles.clearArea(city.id);
  }

  void _set(City? current, List<City> active) {
    if (current != null && !active.any((c) => c.id == current.id)) {
      active = [current, ...active];
    }
    value = CitySelection(current: current, active: List.unmodifiable(active));
    if (current != null) SearchArea.current = SearchArea.of(current);
    OfflineVectorTiles.areas = {for (final c in active) c.id: c.bounds};
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final current = value.current;
    if (current != null) await prefs.setString(_currentKey, current.id);
    await prefs.setStringList(_activeKey, [for (final c in value.active) c.id]);
  }
}

final CityController cityController = CityController();
