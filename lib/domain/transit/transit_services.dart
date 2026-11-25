import 'package:latlong2/latlong.dart';
import 'package:nicmo/domain/transit/itinerary.dart';
import 'package:nicmo/domain/transit/transit_network.dart';

class Place {
  final String name;
  final String? subtitle;
  final LatLng position;
  final TransitStation? station;

  /// True when the exact point could not be resolved (e.g. the corner of an
  /// address is missing in the map data) and a nearby point is used.
  final bool approximate;

  const Place({
    required this.name,
    required this.position,
    this.subtitle,
    this.station,
    this.approximate = false,
  });
}

abstract class TransitNetworkRepository {
  Future<TransitNetwork> load();
}

abstract class PlaceSearchService {
  Future<List<Place>> search(
    String query, {
    String languageCode = 'es',
    LatLng? near,
  });

  /// Human readable name of a point ("Carrera 43B, Patio Bonito"), or null.
  Future<String?> describe(LatLng point, {String languageCode = 'es'});
}

abstract class TripPlanner {
  /// Returns itineraries ordered by recommendation (best first).
  List<Itinerary> plan(
    TransitNetwork network,
    LatLng origin,
    LatLng destination, {
    String originName = '',
    String destinationName = '',
    int maxResults = 4,
  });
}
