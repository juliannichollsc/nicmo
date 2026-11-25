import 'package:latlong2/latlong.dart';
import 'package:nicmo/domain/city/city.dart';

/// Where place and address searches look: the city the user is in.
class SearchArea {
  /// Nominatim `viewbox`: west, north, east, south.
  final String viewBox;

  /// Municipalities of the metropolitan area (address hints).
  final List<String> municipalities;

  /// Ranks ambiguous results when the user's position is unknown.
  final LatLng center;

  const SearchArea({
    required this.viewBox,
    required this.municipalities,
    required this.center,
  });

  SearchArea.of(City city)
    : viewBox = city.bounds.viewBox,
      municipalities = city.municipalities,
      center = city.center;

  static const valleDeAburra = SearchArea(
    viewBox: '-75.72,6.45,-75.42,6.05',
    municipalities: [
      'Medellín',
      'Bello',
      'Itagüí',
      'Envigado',
      'Sabaneta',
      'La Estrella',
      'Caldas',
      'Copacabana',
      'Girardota',
      'Barbosa',
    ],
    center: LatLng(6.2476, -75.5658),
  );

  /// Set by the city selection (see CityController).
  static SearchArea current = valleDeAburra;
}
