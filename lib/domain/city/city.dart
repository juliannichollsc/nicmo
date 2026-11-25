import 'package:latlong2/latlong.dart';

/// Whether the transit network of a city is already in the app.
enum CityStatus {
  available,

  /// Map and place search only; the network is being prepared.
  soon,
}

/// Rectangle covering a city and its metropolitan area.
class CityBounds {
  final double south;
  final double west;
  final double north;
  final double east;

  const CityBounds(this.south, this.west, this.north, this.east);

  /// From `[south, west, north, east]`.
  factory CityBounds.fromJson(List<dynamic> json) => CityBounds(
    (json[0] as num).toDouble(),
    (json[1] as num).toDouble(),
    (json[2] as num).toDouble(),
    (json[3] as num).toDouble(),
  );

  bool contains(LatLng point) =>
      point.latitude >= south &&
      point.latitude <= north &&
      point.longitude >= west &&
      point.longitude <= east;

  bool intersects(CityBounds other) =>
      other.south <= north &&
      other.north >= south &&
      other.west <= east &&
      other.east >= west;

  /// Grown by [fraction] of its size on every side.
  CityBounds expand(double fraction) {
    final dLat = (north - south) * fraction;
    final dLng = (east - west) * fraction;
    return CityBounds(south - dLat, west - dLng, north + dLat, east + dLng);
  }

  /// Nominatim `viewbox`: west, north, east, south.
  String get viewBox => '$west,$north,$east,$south';
}

/// One data file of a city's network ("metro", "buses", "urban").
class CityLayer {
  final String id;
  final String asset;

  const CityLayer(this.id, this.asset);
}

class City {
  final String id;
  final String name;
  final String region;
  final CityStatus status;

  /// Badge colour (`#RRGGBB`), when the catalog sets one.
  final String? color;
  final LatLng center;
  final double zoom;
  final CityBounds bounds;

  /// Municipalities of the metropolitan area (address search hints).
  final List<String> municipalities;

  /// Transit systems, as their users call them ("Metro", "TransMilenio").
  final List<String> systems;

  /// Data credits shown on the map.
  final List<String> attributions;
  final List<CityLayer> layers;

  const City({
    required this.id,
    required this.name,
    required this.region,
    required this.status,
    this.color,
    required this.center,
    required this.zoom,
    required this.bounds,
    this.municipalities = const [],
    this.systems = const [],
    this.attributions = const [],
    this.layers = const [],
  });

  bool get available => status == CityStatus.available;

  factory City.fromJson(Map<String, dynamic> json) {
    final center = json['center'] as List;
    return City(
      id: json['id'] as String,
      name: json['name'] as String,
      region: json['region'] as String? ?? '',
      status: json['status'] == 'available'
          ? CityStatus.available
          : CityStatus.soon,
      color: json['color'] as String?,
      center: LatLng(
        (center[0] as num).toDouble(),
        (center[1] as num).toDouble(),
      ),
      zoom: (json['zoom'] as num?)?.toDouble() ?? 12.5,
      bounds: CityBounds.fromJson(json['bounds'] as List),
      municipalities: List<String>.from(json['municipalities'] as List? ?? []),
      systems: List<String>.from(json['systems'] as List? ?? []),
      attributions: List<String>.from(json['attributions'] as List? ?? []),
      layers: [
        for (final l in (json['layers'] as List? ?? const []))
          CityLayer(l['id'] as String, l['asset'] as String),
      ],
    );
  }
}

class CityCatalog {
  final List<City> cities;

  const CityCatalog(this.cities);

  factory CityCatalog.fromJson(Map<String, dynamic> json) => CityCatalog([
    for (final c in json['cities'] as List)
      City.fromJson(c as Map<String, dynamic>),
  ]);

  City? byId(String? id) {
    for (final city in cities) {
      if (city.id == id) return city;
    }
    return null;
  }

  /// City whose area contains [point] (the user's position), if any.
  City? at(LatLng point) {
    for (final city in cities) {
      if (city.bounds.contains(point)) return city;
    }
    return null;
  }
}
