import 'package:latlong2/latlong.dart';
import 'package:nicmo/domain/transit/transit_network.dart';
import 'package:nicmo/domain/transit/transit_services.dart';
import 'package:nicmo/infrastructure/geocoding/colombian_address.dart';
import 'package:nicmo/infrastructure/geocoding/colombian_address_geocoder.dart';
import 'package:nicmo/infrastructure/geocoding/nominatim_client.dart';

/// Place search in three layers:
/// 1. Colombian street addresses ("Cra. 43B # 1A Sur - 70") are located by
///    street intersection ([ColombianAddressGeocoder]).
/// 2. Stations of the city's network (offline).
/// 3. Free-text OpenStreetMap Nominatim search (places, barrios, landmarks),
///    bounded to the city in use ([SearchArea]).
class MetroPlaceSearchService implements PlaceSearchService {
  final TransitNetworkRepository networkRepository;
  final NominatimClient nominatim;
  final ColombianAddressGeocoder addressGeocoder;

  MetroPlaceSearchService({
    required TransitNetworkRepository networkRepository,
    NominatimClient? nominatim,
  }) : this._(networkRepository, nominatim ?? NominatimClient());

  // One client for both searches so they share the 1 request/second queue.
  MetroPlaceSearchService._(this.networkRepository, this.nominatim)
    : addressGeocoder = ColombianAddressGeocoder(nominatim);

  int _latest = 0;

  @override
  Future<List<Place>> search(
    String query, {
    String languageCode = 'es',
    LatLng? near,
  }) async {
    final id = ++_latest;
    bool cancelled() => id != _latest;
    final normalized = normalize(query);
    if (normalized.length < 2) return const [];

    final address = ColombianAddress.tryParse(query);
    if (address != null) {
      final places = await addressGeocoder.geocode(
        address,
        languageCode: languageCode,
        near: near,
        cancelled: cancelled,
      );
      if (places.isNotEmpty || cancelled()) return places;
    }

    final network = await networkRepository.load();
    final stations = _searchStations(network, normalized);
    final remote = await _searchNominatim(query, languageCode, cancelled);
    return [...stations, ...remote];
  }

  @override
  Future<String?> describe(LatLng point, {String languageCode = 'es'}) async {
    final data = await nominatim.reverse(
      point.latitude,
      point.longitude,
      languageCode: languageCode,
    );
    final address = data?['address'] as Map<String, dynamic>?;
    if (address == null) return null;
    final street = address['road'] ?? address['pedestrian'] ?? data!['name'];
    final area =
        address['neighbourhood'] ??
        address['suburb'] ??
        address['quarter'] ??
        address['city'];
    final parts = [
      if (street is String && street.isNotEmpty) street,
      if (area is String && area.isNotEmpty) area,
    ];
    return parts.isEmpty ? null : parts.join(', ');
  }

  List<Place> _searchStations(TransitNetwork network, String normalized) {
    final matches =
        network.stations.values
            .where((s) => normalize(s.name).contains(normalized))
            .toList()
          ..sort((a, b) {
            final aStarts = normalize(a.name).startsWith(normalized) ? 0 : 1;
            final bStarts = normalize(b.name).startsWith(normalized) ? 0 : 1;
            return aStarts != bStarts
                ? aStarts - bStarts
                : a.name.compareTo(b.name);
          });
    return [
      for (final station in matches.take(5))
        Place(name: station.name, position: station.position, station: station),
    ];
  }

  Future<List<Place>> _searchNominatim(
    String query,
    String languageCode,
    bool Function() cancelled,
  ) async {
    final data = await nominatim.search(
      query,
      languageCode: languageCode,
      cancelled: cancelled,
    );
    return [
      for (final item in data)
        Place(
          name: (item['name'] as String?)?.isNotEmpty == true
              ? item['name'] as String
              : (item['display_name'] as String).split(',').first,
          subtitle: _shortAddress(item['display_name'] as String),
          position: LatLng(
            double.parse(item['lat'] as String),
            double.parse(item['lon'] as String),
          ),
        ),
    ];
  }

  static String _shortAddress(String displayName) {
    final parts = displayName.split(',').map((p) => p.trim()).toList();
    return parts.skip(1).take(3).join(', ');
  }

  static String normalize(String value) =>
      ColombianAddress.normalize(value.trim());
}
