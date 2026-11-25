import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:nicmo/domain/transit/transit_network.dart';

// Also run on the web (flutter test --platform chrome): bitwise operators
// behave differently there.
void main() {
  test('decodes the reference encoded polyline', () {
    // Example of the Google polyline documentation.
    expect(decodePolyline('_p~iF~ps|U_ulLnnqC_mqNvxq`@'), [
      const LatLng(38.5, -120.2),
      const LatLng(40.7, -120.95),
      const LatLng(43.252, -126.453),
    ]);
  });

  test('negative coordinates (Medellín) decode on every platform', () {
    // [6.15268, -75.62645], [6.15573, -75.62136]
    final points = decodePolyline('gupd@hxqlMaRy^');
    expect(points.first.latitude, closeTo(6.15268, 1e-9));
    expect(points.first.longitude, closeTo(-75.62645, 1e-9));
    expect(points.last.longitude, closeTo(-75.62136, 1e-9));
  });
}
