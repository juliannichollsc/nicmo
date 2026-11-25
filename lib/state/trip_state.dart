import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import 'package:nicmo/domain/transit/itinerary.dart';
import 'package:nicmo/domain/transit/transit_network.dart';
import 'package:nicmo/domain/transit/transit_services.dart';
import 'package:nicmo/infrastructure/geocoding/metro_place_search_service.dart';
import 'package:nicmo/infrastructure/transit/city_transit_network_repository.dart';
import 'package:nicmo/infrastructure/transit/multimodal_trip_planner.dart';
import 'package:nicmo/state/active_trip_state.dart';
import 'package:nicmo/state/city_state.dart';
import 'package:nicmo/state/map_filter_state.dart';

enum TripStatus { idle, searching, results, empty, error }

enum PlaceSlot { origin, destination }

class TripState {
  final TransitNetwork? network;
  final Place? origin;
  final Place? destination;
  final TripStatus status;
  final List<Itinerary> itineraries;
  final int selectedIndex;
  final PlaceSlot? pickingOnMap;

  const TripState({
    this.network,
    this.origin,
    this.destination,
    this.status = TripStatus.idle,
    this.itineraries = const [],
    this.selectedIndex = 0,
    this.pickingOnMap,
  });

  Itinerary? get selected =>
      itineraries.isEmpty ? null : itineraries[selectedIndex];

  TripState copyWith({
    TransitNetwork? network,
    Place? origin,
    Place? destination,
    TripStatus? status,
    List<Itinerary>? itineraries,
    int? selectedIndex,
    PlaceSlot? pickingOnMap,
    bool clearPicking = false,
  }) {
    return TripState(
      network: network ?? this.network,
      origin: origin ?? this.origin,
      destination: destination ?? this.destination,
      status: status ?? this.status,
      itineraries: itineraries ?? this.itineraries,
      selectedIndex: selectedIndex ?? this.selectedIndex,
      pickingOnMap: clearPicking ? null : (pickingOnMap ?? this.pickingOnMap),
    );
  }
}

class TripController extends ValueNotifier<TripState> {
  final TransitNetworkRepository networkRepository;
  final PlaceSearchService placeSearch;
  final TripPlanner planner;

  TripController({
    required this.networkRepository,
    required this.placeSearch,
    required this.planner,
  }) : super(const TripState());

  /// Bumped when the city changes, so a network still loading for the
  /// previous city is not installed.
  int _generation = 0;

  Future<TransitNetwork> ensureNetwork() async {
    final known = value.network;
    if (known != null) return known;
    final generation = _generation;
    final network = await networkRepository.load();
    if (value.network == null && generation == _generation) {
      value = value.copyWith(network: network);
    }
    return network;
  }

  /// Another city is in use: places, routes and network of the previous
  /// one no longer apply.
  void changeCity() {
    _generation++;
    value = const TripState();
    ensureNetwork().ignore();
  }

  /// [near] (usually the user's position) ranks ambiguous results.
  Future<List<Place>> search(
    String query,
    String languageCode, {
    LatLng? near,
  }) => placeSearch.search(query, languageCode: languageCode, near: near);

  /// Sets or clears ([place] == null) a slot. Any change invalidates the
  /// previous results so stale routes are never shown.
  void setPlace(PlaceSlot slot, Place? place) {
    value = TripState(
      network: value.network,
      origin: slot == PlaceSlot.origin ? place : value.origin,
      destination: slot == PlaceSlot.destination ? place : value.destination,
    );
  }

  /// Starts placing [slot] by hand: the map shows a centre pin.
  void startPicking(PlaceSlot slot) =>
      value = value.copyWith(pickingOnMap: slot);

  void cancelPicking() => value = value.copyWith(clearPicking: true);

  /// Uses exactly [point] for the slot being picked. The place gets the
  /// coordinates as its label right away; a street name replaces it when
  /// the reverse lookup answers (the position never changes).
  Future<void> confirmPick(LatLng point, {String languageCode = 'es'}) async {
    final slot = value.pickingOnMap;
    if (slot == null) return;
    final coordinates = formatCoordinates(point);
    final place = Place(name: coordinates, position: point);
    setPlace(slot, place);

    final name = await placeSearch
        .describe(point, languageCode: languageCode)
        .catchError((_) => null);
    final current = slot == PlaceSlot.origin ? value.origin : value.destination;
    if (name == null || !identical(current, place)) return;
    // Replace in place: keep status and results untouched.
    final named = Place(name: name, subtitle: coordinates, position: point);
    value = TripState(
      network: value.network,
      origin: slot == PlaceSlot.origin ? named : value.origin,
      destination: slot == PlaceSlot.destination ? named : value.destination,
      status: value.status,
      itineraries: value.itineraries,
      selectedIndex: value.selectedIndex,
      pickingOnMap: value.pickingOnMap,
    );
  }

  void swap() {
    value = TripState(
      network: value.network,
      origin: value.destination,
      destination: value.origin,
    );
  }

  /// Does the walking leg [legIndex] of the selected route on foot or by
  /// car; times update everywhere (results, map and active trip).
  void setLegCar(int legIndex, bool byCar) =>
      _updateSelected((it) => it.withCar(legIndex, byCar), legIndex);

  /// Remembers which app the car of [legIndex] was requested with.
  void setLegApp(int legIndex, RideHailService service) =>
      _updateSelected((it) => it.withRideHailApp(legIndex, service), legIndex);

  void _updateSelected(Itinerary Function(Itinerary) change, int legIndex) {
    final selected = value.selected;
    if (selected == null || !selected.legs[legIndex].isWalk) return;
    final itineraries = [...value.itineraries];
    itineraries[value.selectedIndex] = change(selected);
    value = value.copyWith(itineraries: itineraries);
  }

  void select(int index) {
    if (index < 0 || index >= value.itineraries.length) return;
    value = value.copyWith(selectedIndex: index);
  }

  void reset() => value = TripState(network: value.network);

  /// Restores a trip in progress saved on the device (see ActiveTripStore).
  void resume({
    required Itinerary itinerary,
    required Place origin,
    required Place destination,
  }) {
    value = TripState(
      network: value.network,
      origin: origin,
      destination: destination,
      status: TripStatus.results,
      itineraries: [itinerary],
    );
  }

  bool get isSearching => value.status == TripStatus.searching;

  Future<void> planTrip() async {
    final origin = value.origin;
    final destination = value.destination;
    if (origin == null || destination == null) return;
    value = value.copyWith(
      status: TripStatus.searching,
      itineraries: const [],
      selectedIndex: 0,
    );
    try {
      final network = await ensureNetwork();
      // Planning takes a few ms; keep the skeleton visible long enough to
      // read as a transition instead of a flicker.
      await Future<void>.delayed(const Duration(milliseconds: 650));
      final results = planner.plan(
        network,
        origin.position,
        destination.position,
        originName: origin.name,
        destinationName: destination.name,
      );
      value = value.copyWith(
        status: results.isEmpty ? TripStatus.empty : TripStatus.results,
        itineraries: results,
      );
    } catch (error, stack) {
      debugPrint('planTrip failed: $error\n$stack');
      value = value.copyWith(status: TripStatus.error);
    }
  }
}

String formatCoordinates(LatLng p) =>
    '${p.latitude.toStringAsFixed(5)}, ${p.longitude.toStringAsFixed(5)}';

final CityTransitNetworkRepository _networkRepository =
    CityTransitNetworkRepository(city: () => cityController.current);

final TripController tripController = TripController(
  networkRepository: _networkRepository,
  placeSearch: MetroPlaceSearchService(networkRepository: _networkRepository),
  planner: MultimodalTripPlanner(),
);

/// Resets trips and map filters whenever the city in use changes.
void bindTripToCity() {
  var cityId = cityController.current?.id;
  cityController.addListener(() {
    final id = cityController.current?.id;
    if (id == cityId) return;
    cityId = id;
    lineFilter.value = null;
    groupFilter.value = null;
    ActiveTripStore.pending = null;
    ActiveTripStore.clear().ignore();
    tripController.changeCity();
  });
}
