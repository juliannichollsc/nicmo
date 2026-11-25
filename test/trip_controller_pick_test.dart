import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:nicmo/domain/transit/transit_services.dart';
import 'package:nicmo/infrastructure/transit/city_transit_network_repository.dart';
import 'package:nicmo/infrastructure/transit/multimodal_trip_planner.dart';
import 'package:nicmo/state/trip_state.dart';

class _FakeSearch implements PlaceSearchService {
  @override
  Future<List<Place>> search(
    String query, {
    String languageCode = 'es',
    LatLng? near,
  }) async => const [];

  @override
  Future<String?> describe(LatLng point, {String languageCode = 'es'}) async =>
      'Carrera 43B, Patio Bonito';
}

void main() {
  test('a point placed by hand keeps its exact coordinates', () async {
    final controller = TripController(
      networkRepository: CityTransitNetworkRepository(city: () => null),
      placeSearch: _FakeSearch(),
      planner: MultimodalTripPlanner(),
    );
    const point = LatLng(6.201843, -75.570402);

    controller.startPicking(PlaceSlot.destination);
    expect(controller.value.pickingOnMap, PlaceSlot.destination);

    await controller.confirmPick(point);

    final destination = controller.value.destination!;
    expect(controller.value.pickingOnMap, isNull);
    expect(destination.position, point);
    expect(destination.name, 'Carrera 43B, Patio Bonito');
    expect(destination.subtitle, '6.20184, -75.57040');
  });
}
