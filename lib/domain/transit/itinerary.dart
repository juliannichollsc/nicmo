import 'package:latlong2/latlong.dart';
import 'package:nicmo/domain/transit/transit_network.dart';

/// Ride-hailing apps that can replace a walking leg.
enum RideHailService { uber, indrive }

class ItineraryLeg {
  /// Walking pace used by the planner (~4.5 km/h).
  static const double walkMetersPerMin = 75;

  /// Typical urban car speed in the Valle de Aburrá (~20 km/h) and the
  /// average wait for a driver to arrive.
  static const double carMetersPerMin = 333;
  static const double rideHailPickupMin = 5;

  final TransitMode mode;
  final TransitLine? line;
  final String fromName;
  final String toName;
  final List<TransitStation> stops;
  final List<LatLng> path;
  final double distanceMeters;
  final double durationMin;
  final double waitMin;

  /// Terminal the vehicle is heading to ("towards X").
  final String? headsign;

  /// Bus boarded on the street along its route, not at a listed stop.
  final bool boardsRoadside;

  /// Bus left on the street along its route, near the destination.
  final bool alightsRoadside;

  /// For walking legs that end at a roadside bus boarding point.
  final TransitLine? walkToLine;

  /// A walking leg the rider chose to do by car (planned before the trip).
  final bool byCar;

  /// App used to request that car during the trip, once chosen.
  final RideHailService? rideHail;

  const ItineraryLeg({
    required this.mode,
    required this.fromName,
    required this.toName,
    required this.path,
    required this.distanceMeters,
    required this.durationMin,
    this.line,
    this.stops = const [],
    this.waitMin = 0,
    this.headsign,
    this.boardsRoadside = false,
    this.alightsRoadside = false,
    this.walkToLine,
    this.byCar = false,
    this.rideHail,
  });

  /// Walking legs (also when replaced by a car ride: same origin/target).
  bool get isWalk => mode == TransitMode.walk;

  /// Done by car (ride-hailing) instead of on foot.
  bool get isRideHail => byCar;

  /// The same walking leg on foot or by car.
  /// Car time = pickup wait + distance at urban speed.
  ItineraryLeg withCar(bool car) {
    assert(isWalk, 'only walking legs can be replaced by a car ride');
    return _copy(byCar: car, rideHail: car ? rideHail : null);
  }

  /// Records the app used to request the car (during the trip).
  ItineraryLeg withRideHailApp(RideHailService service) =>
      _copy(byCar: true, rideHail: service);

  ItineraryLeg _copy({required bool byCar, RideHailService? rideHail}) {
    return ItineraryLeg(
      mode: mode,
      fromName: fromName,
      toName: toName,
      path: path,
      distanceMeters: distanceMeters,
      durationMin: byCar
          ? distanceMeters / carMetersPerMin
          : distanceMeters / walkMetersPerMin,
      waitMin: byCar ? rideHailPickupMin : 0,
      walkToLine: walkToLine,
      byCar: byCar,
      rideHail: rideHail,
    );
  }

  /// Number of listed stops travelled (excluding the boarding one).
  int get stopCount =>
      boardsRoadside ? stops.length : (stops.isEmpty ? 0 : stops.length - 1);
}

enum ItineraryTag { fastest, fewestTransfers, leastWalking }

class Itinerary {
  final List<ItineraryLeg> legs;
  final Set<ItineraryTag> tags;

  const Itinerary({required this.legs, this.tags = const {}});

  Itinerary withTags(Set<ItineraryTag> value) =>
      Itinerary(legs: legs, tags: value);

  /// Copy with the walking leg at [index] done on foot or by car.
  Itinerary withCar(int index, bool car) =>
      _replace(index, legs[index].withCar(car));

  Itinerary withRideHailApp(int index, RideHailService service) =>
      _replace(index, legs[index].withRideHailApp(service));

  Itinerary _replace(int index, ItineraryLeg leg) => Itinerary(
    legs: [for (var i = 0; i < legs.length; i++) i == index ? leg : legs[i]],
    tags: tags,
  );

  double get totalMin =>
      legs.fold(0, (sum, leg) => sum + leg.durationMin + leg.waitMin);

  double get walkMeters => legs
      .where((leg) => leg.isWalk && !leg.isRideHail)
      .fold(0, (sum, leg) => sum + leg.distanceMeters);

  List<ItineraryLeg> get rideLegs => legs.where((leg) => !leg.isWalk).toList();

  int get transfers => rideLegs.isEmpty ? 0 : rideLegs.length - 1;

  List<LatLng> get fullPath => [for (final leg in legs) ...leg.path];

  /// Identifies the sequence of lines, used to discard duplicated alternatives.
  String get signature => rideLegs.map((leg) => leg.line!.id).join('>');
}
