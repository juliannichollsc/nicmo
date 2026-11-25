import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:nicmo/domain/transit/itinerary.dart';
import 'package:nicmo/domain/transit/transit_network.dart';
import 'package:nicmo/infrastructure/ride_hail/ride_hail_launcher.dart';

void main() {
  const walk = ItineraryLeg(
    mode: TransitMode.walk,
    fromName: 'A',
    toName: 'Poblado',
    path: [LatLng(6.2018, -75.5704), LatLng(6.2125, -75.5776)],
    distanceMeters: 1500,
    durationMin: 20, // 1500 m / 75 m/min
  );
  final itinerary = Itinerary(legs: [walk]);

  test('a walking leg done by car changes time, keeps the route', () {
    final byCar = itinerary.withCar(0, true);
    final leg = byCar.legs.single;
    expect(leg.isRideHail, isTrue);
    expect(leg.rideHail, isNull); // app chosen later, during the trip
    expect(leg.isWalk, isTrue); // same start and end as the walk
    expect(leg.waitMin, ItineraryLeg.rideHailPickupMin);
    expect(byCar.totalMin, closeTo(5 + 1500 / 333, 0.01));
    expect(byCar.walkMeters, 0);

    final withApp = byCar.withRideHailApp(0, RideHailService.indrive);
    expect(withApp.legs.single.rideHail, RideHailService.indrive);
    expect(withApp.totalMin, byCar.totalMin);

    final back = withApp.withCar(0, false);
    expect(back.legs.single.rideHail, isNull);
    expect(back.legs.single.isRideHail, isFalse);
    expect(back.totalMin, closeTo(20, 0.01));
    expect(back.walkMeters, 1500);
  });

  test('Uber link carries pickup and drop-off', () {
    final uri = RideHailLauncher.uberLink(
      pickup: walk.path.first,
      pickupName: 'Carrera 43B',
      dropoff: walk.path.last,
      dropoffName: 'Poblado',
    );
    expect(uri.host, 'm.uber.com');
    expect(uri.queryParameters['action'], 'setPickup');
    expect(uri.queryParameters['dropoff[latitude]'], '6.212500');
    expect(uri.queryParameters['dropoff[nickname]'], 'Poblado');
    expect(uri.queryParameters['pickup[longitude]'], '-75.570400');
  });

  test('inDrive receives the drop-off as a standard geo: intent', () {
    expect(
      RideHailLauncher.geoUri(
        const LatLng(6.2125, -75.5776),
        'Estación (Poblado)',
      ),
      'geo:6.212500,-75.577600?q=6.212500,-75.577600(Estaci%C3%B3n%20Poblado)',
    );
  });
}
