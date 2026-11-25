import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:nicmo/app_info.dart';
import 'package:nicmo/domain/city/city.dart';
import 'package:nicmo/domain/transit/transit_network.dart';
import 'package:nicmo/domain/transit/transit_services.dart';
import 'package:nicmo/il8n/app_localizations.dart';
import 'package:nicmo/state/city_state.dart';
import 'package:nicmo/state/location_state.dart';
import 'package:nicmo/state/map_filter_state.dart';
import 'package:nicmo/state/trip_state.dart';
import 'package:nicmo/theme/metro_theme.dart';
import 'package:nicmo/widget/map/metro_map.dart';
import 'package:nicmo/widget/city/city_card.dart';
import 'package:nicmo/widget/shared/shell.dart';
import 'package:nicmo/widget/map/transport_filter.dart';
import 'package:nicmo/widget/trip/itinerary_results.dart';
import 'package:nicmo/widget/trip/trip_search_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<MetroMapState> _mapKey = GlobalKey<MetroMapState>();
  bool _centeredOnUser = false;

  /// Map centre while placing a point by hand, and whether the map is being
  /// dragged (the pin lifts while moving and drops when it stops).
  final ValueNotifier<LatLng> _center = ValueNotifier(
    cityController.current?.center ?? MetroMap.medellin,
  );
  final ValueNotifier<bool> _moving = ValueNotifier(false);
  Timer? _settle;

  @override
  void initState() {
    super.initState();
    tripController.ensureNetwork();
    locationController.addListener(_onLocation);
    locationController.start();
    tripController.addListener(_onTrip);
    cityController.addListener(_onCity);
  }

  /// City just changed to: announced by a pill while the camera flies.
  City? _arrived;
  Timer? _arrivedTimer;
  String? _cityId = cityController.current?.id;

  void _onCity() {
    final city = cityController.current;
    if (city == null || city.id == _cityId || !mounted) return;
    _cityId = city.id;
    // Chosen from the cities screen opened over the menu: show the flight.
    appScaffoldKey.currentState?.closeDrawer();
    // The user is probably not in the new city: don't fly back to them.
    _centeredOnUser = true;
    setState(() => _arrived = city);
    _arrivedTimer?.cancel();
    _arrivedTimer = Timer(const Duration(milliseconds: 2800), () {
      if (mounted) setState(() => _arrived = null);
    });
  }

  @override
  void dispose() {
    locationController.removeListener(_onLocation);
    tripController.removeListener(_onTrip);
    cityController.removeListener(_onCity);
    _arrivedTimer?.cancel();
    _settle?.cancel();
    _center.dispose();
    _moving.dispose();
    super.dispose();
  }

  TripStatus _lastStatus = TripStatus.idle;
  PlaceSlot? _lastPicking;
  Place? _lastOrigin;

  /// When a search starts, frame origin and destination together (the camera
  /// centres on their midpoint); the route itself is framed when it arrives.
  void _onTrip() {
    final state = tripController.value;
    if (state.status == TripStatus.searching &&
        _lastStatus != TripStatus.searching &&
        state.origin != null &&
        state.destination != null) {
      _mapKey.currentState?.fitPoints([
        state.origin!.position,
        state.destination!.position,
      ]);
    }
    _lastStatus = state.status;

    // Placing a point by hand: start from the current place of that slot,
    // or from the user, close enough to pick a doorway.
    if (state.pickingOnMap != null && _lastPicking == null) {
      final current = state.pickingOnMap == PlaceSlot.origin
          ? state.origin
          : state.destination;
      final start =
          current?.position ??
          locationController.value?.position ??
          _center.value;
      _mapKey.currentState?.animateTo(start, 17);
    }
    _lastPicking = state.pickingOnMap;

    // "My location" with a coarse network fix (desktop browsers): offer to
    // place the start by hand instead of trusting it.
    final origin = state.origin;
    final location = locationController.value;
    if (!identical(origin, _lastOrigin) &&
        origin != null &&
        origin.approximate &&
        location != null) {
      _warnImpreciseLocation(location);
    }
    _lastOrigin = origin;
  }

  void _warnImpreciseLocation(UserLocation location) {
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 6),
          content: Text(
            l10n.impreciseLocation(location.accuracyMeters.round()),
          ),
          action: SnackBarAction(
            label: l10n.adjust,
            textColor: MetroPalette.greenBright,
            onPressed: () => tripController.startPicking(PlaceSlot.origin),
          ),
        ),
      );
  }

  void _onLocation() {
    final location = locationController.value;
    if (location == null || !mounted) return;
    // Fly to the user on the first fix, unless a trip is already on screen.
    if (!_centeredOnUser && tripController.value.selected == null) {
      _centeredOnUser = true;
      // A coarse network fix is shown with its whole uncertainty circle.
      final zoom = location.accuracyMeters > 500 ? 13.0 : 15.0;
      _mapKey.currentState?.animateTo(location.position, zoom);
    }
  }

  Future<LatLng?> _locate() async {
    final started = await locationController.start();
    final location = locationController.value;
    if (!mounted) return null;
    if (!started || location == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.locationUnavailable),
        ),
      );
      return null;
    }
    _mapKey.currentState?.animateTo(location.position, 16);
    return location.position;
  }

  Future<void> _useMyLocationAsOrigin() async {
    final position = await _locate();
    final location = locationController.value;
    if (position == null || location == null || !mounted) return;
    tripController.setPlace(
      PlaceSlot.origin,
      Place(
        name: AppLocalizations.of(context)!.myLocation,
        position: position,
        approximate: !location.isPrecise,
      ),
    );
  }

  /// While placing a point, a tap brings that spot under the centre pin.
  void _onMapTap(LatLng point) {
    if (tripController.value.pickingOnMap == null) return;
    _mapKey.currentState?.animateTo(point);
  }

  void _onCameraMoved(LatLng center) {
    _center.value = center;
    if (tripController.value.pickingOnMap == null) return;
    _moving.value = true;
    _settle?.cancel();
    _settle = Timer(
      const Duration(milliseconds: 180),
      () => _moving.value = false,
    );
  }

  void _confirmPick() {
    tripController.confirmPick(
      _center.value,
      languageCode: Localizations.localeOf(context).languageCode,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TripState>(
      valueListenable: tripController,
      builder: (context, state, _) => ValueListenableBuilder<UserLocation?>(
        valueListenable: locationController,
        builder: (context, location, _) => ValueListenableBuilder<String?>(
          valueListenable: lineFilter,
          builder: (context, filter, _) => ValueListenableBuilder<LineGroup?>(
            valueListenable: groupFilter,
            builder: (context, group, _) => LayoutBuilder(
              builder: (context, constraints) {
                final picking = state.pickingOnMap != null;
                final sheetVisible =
                    !picking &&
                    (state.status == TripStatus.searching ||
                        state.status == TripStatus.results);
                // Map controls (menu, transport filter, centre on me) while
                // nothing covers the top of the map.
                final controlsVisible = !picking && !sheetVisible;
                // The map runs under the status bar: controls start below.
                final top = MediaQuery.paddingOf(context).top + 12;
                return Stack(
                  children: [
                    Positioned.fill(
                      child: MetroMap(
                        key: _mapKey,
                        city: cityController.current,
                        network: state.network,
                        itinerary: state.selected,
                        // The point being placed is shown by the centre pin.
                        origin: state.pickingOnMap == PlaceSlot.origin
                            ? null
                            : state.origin?.position,
                        destination: state.pickingOnMap == PlaceSlot.destination
                            ? null
                            : state.destination?.position,
                        userPosition: location?.position,
                        userAccuracy: location?.accuracyMeters,
                        onTap: _onMapTap,
                        onCameraMoved: _onCameraMoved,
                        lineFilter: filter,
                        groupFilter: group,
                        // Keep framed content clear of the search card (at
                        // the top with the results sheet, 46% of the height;
                        // otherwise at the bottom, under the map controls).
                        fitPadding: sheetVisible
                            ? EdgeInsets.fromLTRB(
                                40,
                                240,
                                40,
                                constraints.maxHeight * 0.46 + 24,
                              )
                            : EdgeInsets.fromLTRB(40, top + 80, 40, 300),
                      ),
                    ),
                    // Origin / destination: at the bottom, within thumb reach;
                    // up top while the route alternatives fill the bottom.
                    Positioned.fill(
                      child: SafeArea(
                        child: IgnorePointer(
                          ignoring: picking,
                          child: AnimatedAlign(
                            alignment: sheetVisible
                                ? Alignment.topCenter
                                : Alignment.bottomCenter,
                            duration: const Duration(milliseconds: 480),
                            curve: Curves.easeInOutCubicEmphasized,
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: AnimatedSlide(
                                offset: picking
                                    ? const Offset(0, 1.3)
                                    : Offset.zero,
                                duration: const Duration(milliseconds: 380),
                                curve: Curves.easeInOutCubicEmphasized,
                                child: AnimatedOpacity(
                                  opacity: picking ? 0 : 1,
                                  duration: const Duration(milliseconds: 250),
                                  child: _EntranceSlide(
                                    child: TripSearchCard(
                                      state: state,
                                      onUseMyLocation: _useMyLocationAsOrigin,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Menu and transport filter (top left), centre on me (top
                    // right).
                    Positioned(
                      left: 12,
                      top: top,
                      child: IgnorePointer(
                        ignoring: !controlsVisible,
                        child: AnimatedScale(
                          scale: controlsVisible ? 1 : 0,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOutBack,
                          child: const _MenuButton(),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 60,
                      top: top,
                      right: 72,
                      child: IgnorePointer(
                        ignoring: !controlsVisible,
                        child: AnimatedOpacity(
                          opacity: controlsVisible ? 1 : 0,
                          duration: const Duration(milliseconds: 250),
                          child: Align(
                            alignment: Alignment.topLeft,
                            // Nothing to filter in a city without network.
                            child: state.network?.lines.isEmpty ?? true
                                ? const SizedBox.shrink()
                                : TransportFilter(network: state.network),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 12,
                      top: top,
                      child: IgnorePointer(
                        ignoring: !controlsVisible,
                        child: AnimatedScale(
                          scale: controlsVisible ? 1 : 0,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOutBack,
                          child: FloatingActionButton.small(
                            heroTag: 'locate_fab',
                            tooltip: AppLocalizations.of(context)!.centerOnMe,
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.surface,
                            foregroundColor: location == null
                                ? Theme.of(context).colorScheme.onSurfaceVariant
                                : Theme.of(context).colorScheme.primary,
                            onPressed: _locate,
                            child: Icon(
                              location == null
                                  ? Icons.location_searching_rounded
                                  : Icons.my_location_rounded,
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (picking) ...[
                      Positioned.fill(
                        child: IgnorePointer(
                          child: _CenterPin(moving: _moving),
                        ),
                      ),
                      Positioned(
                        left: 12,
                        right: 12,
                        top: top,
                        child: _EntranceSlide(
                          child: _Panel(
                            child: Row(
                              children: [
                                _PointBadge(
                                  icon: state.pickingOnMap == PlaceSlot.origin
                                      ? Icons.trip_origin_rounded
                                      : Icons.flag_rounded,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    state.pickingOnMap == PlaceSlot.origin
                                        ? AppLocalizations.of(
                                            context,
                                          )!.movePinOrigin
                                        : AppLocalizations.of(
                                            context,
                                          )!.movePinDestination,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                    Positioned.fill(
                      child: IgnorePointer(
                        ignoring: !sheetVisible,
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 450),
                          switchInCurve: Curves.easeOutCubic,
                          switchOutCurve: Curves.easeInCubic,
                          transitionBuilder: _slideFromBottom,
                          child: sheetVisible
                              ? ItineraryResultsSheet(
                                  key: const ValueKey('sheet'),
                                  state: state,
                                  onStart: () => context.push('/trip'),
                                )
                              : const SizedBox.shrink(),
                        ),
                      ),
                    ),
                    // "Now in Bogotá" while the camera flies there.
                    Positioned(
                      left: 0,
                      right: 0,
                      top: top + 60,
                      child: IgnorePointer(
                        child: Center(
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 420),
                            switchInCurve: Curves.easeOutBack,
                            switchOutCurve: Curves.easeInCubic,
                            transitionBuilder: (child, animation) =>
                                FadeTransition(
                                  opacity: animation,
                                  child: ScaleTransition(
                                    scale: Tween(
                                      begin: 0.7,
                                      end: 1.0,
                                    ).animate(animation),
                                    child: child,
                                  ),
                                ),
                            child: _arrived == null || !_arrived!.available
                                ? const SizedBox.shrink()
                                : _ArrivalPill(
                                    key: ValueKey(_arrived!.id),
                                    city: _arrived!,
                                  ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 12,
                      right: 12,
                      // Picking panel at the bottom; "no routes" under the
                      // map controls, above the search card.
                      top: picking ? null : top + 56,
                      bottom: picking ? 12 : null,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 450),
                        switchInCurve: Curves.easeOutCubic,
                        switchOutCurve: Curves.easeInCubic,
                        transitionBuilder: _slideFromBottom,
                        child: _statusCard(context, state),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  static Widget _slideFromBottom(Widget child, Animation<double> animation) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 0.35),
        end: Offset.zero,
      ).animate(animation),
      child: FadeTransition(opacity: animation, child: child),
    );
  }

  Widget _statusCard(BuildContext context, TripState state) {
    final l10n = AppLocalizations.of(context)!;
    if (state.pickingOnMap != null) {
      return _PickPanel(
        key: const ValueKey('picking'),
        center: _center,
        confirmLabel: l10n.confirmPoint,
        cancelLabel: l10n.cancel,
        onConfirm: _confirmPick,
        onCancel: tripController.cancelPicking,
      );
    }
    final city = cityController.current;
    switch (state.status) {
      case TripStatus.idle when city != null && !city.available:
        // The network of this city is not in the app yet.
        return _InfoCard(
          key: ValueKey('soon-${city.id}'),
          leading: CityBadge(city: city, size: 36),
          text: l10n.citySoonNote(city.name),
          action: kMultiCityEnabled
              ? TextButton(
                  onPressed: () => context.push('/cities'),
                  child: Text(l10n.changeCity),
                )
              : null,
        );
      case TripStatus.idle:
        return const SizedBox.shrink(key: ValueKey('idle'));
      case TripStatus.empty:
      case TripStatus.error:
        return _InfoCard(
          key: ValueKey(state.status),
          leading: const Icon(
            Icons.wrong_location_outlined,
            color: Colors.orangeAccent,
            size: 30,
          ),
          text: state.status == TripStatus.empty
              ? l10n.noRoutes
              : l10n.routeError,
          action: TextButton(
            onPressed: tripController.reset,
            child: Text(l10n.cancel),
          ),
        );
      case TripStatus.searching:
      case TripStatus.results:
        return const SizedBox.shrink(key: ValueKey('sheet'));
    }
  }
}

class _EntranceSlide extends StatelessWidget {
  final Widget child;

  const _EntranceSlide({required this.child});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) => Transform.translate(
        offset: Offset(0, -40 * (1 - t)),
        child: Opacity(opacity: t, child: child),
      ),
      child: child,
    );
  }
}

class _Panel extends StatelessWidget {
  final Widget child;

  const _Panel({required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      elevation: 10,
      shadowColor: Colors.black54,
      color: isDark
          ? MetroPalette.surface.withValues(alpha: 0.96)
          : Colors.white.withValues(alpha: 0.98),
      borderRadius: BorderRadius.circular(22),
      child: Padding(padding: const EdgeInsets.all(14), child: child),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final Widget leading;
  final String text;
  final Widget? action;

  const _InfoCard({
    super.key,
    required this.leading,
    required this.text,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    return _Panel(
      child: Row(
        children: [
          leading,
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: textColor.withValues(alpha: 0.9),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          ?action,
        ],
      ),
    );
  }
}

/// Pin fixed at the centre of the map; it lifts while the map moves and
/// drops with a small bounce when it stops, like ride-hailing apps.
class _CenterPin extends StatelessWidget {
  final ValueListenable<bool> moving;

  const _CenterPin({required this.moving});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: moving,
      builder: (context, isMoving, _) => Stack(
        alignment: Alignment.center,
        children: [
          // Shadow on the exact point.
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: isMoving ? 14 : 8,
            height: isMoving ? 6 : 4,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: isMoving ? 0.25 : 0.45),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          AnimatedSlide(
            // The pin tip sits on the centre; lifted while dragging.
            offset: Offset(0, isMoving ? -0.75 : -0.5),
            duration: Duration(milliseconds: isMoving ? 150 : 350),
            curve: isMoving ? Curves.easeOut : Curves.elasticOut,
            child: SizedBox(
              width: 48,
              height: 60,
              child: const Icon(
                Icons.location_on_rounded,
                size: 60,
                color: MetroPalette.green,
                shadows: [Shadow(blurRadius: 10, color: Colors.black54)],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PointBadge extends StatelessWidget {
  final IconData icon;

  const _PointBadge({required this.icon});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 18,
      backgroundColor: MetroPalette.green,
      child: Icon(icon, color: Colors.white, size: 20),
    );
  }
}

/// Live coordinates under the pin with confirm / cancel actions.
class _PickPanel extends StatelessWidget {
  final ValueListenable<LatLng> center;
  final String confirmLabel;
  final String cancelLabel;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const _PickPanel({
    super.key,
    required this.center,
    required this.confirmLabel,
    required this.cancelLabel,
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    return _Panel(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(Icons.my_location_rounded, color: MetroPalette.green),
              const SizedBox(width: 10),
              ValueListenableBuilder<LatLng>(
                valueListenable: center,
                builder: (context, point, _) => Text(
                  formatCoordinates(point),
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.w700,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onCancel,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: MetroPalette.green,
                    side: const BorderSide(color: MetroPalette.green),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(cancelLabel),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: onConfirm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: MetroPalette.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  icon: const Icon(Icons.check_rounded),
                  label: Text(confirmLabel),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Opens the side menu (it also opens by swiping from the left edge).
class _MenuButton extends StatelessWidget {
  const _MenuButton();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return FloatingActionButton.small(
      heroTag: 'menu_fab',
      tooltip: MaterialLocalizations.of(context).openAppDrawerTooltip,
      backgroundColor: scheme.surface,
      foregroundColor: scheme.onSurface,
      onPressed: () => Scaffold.of(context).openDrawer(),
      child: const Icon(Icons.menu_rounded),
    );
  }
}

/// "Now in Medellín" with the city badge, shown after changing city.
class _ArrivalPill extends StatelessWidget {
  final City city;

  const _ArrivalPill({super.key, required this.city});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      elevation: 10,
      shadowColor: Colors.black45,
      color: isDark
          ? MetroPalette.surface.withValues(alpha: 0.96)
          : Colors.white.withValues(alpha: 0.98),
      borderRadius: BorderRadius.circular(24),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(6, 6, 16, 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CityBadge(city: city, size: 32),
            const SizedBox(width: 10),
            Text(
              AppLocalizations.of(context)!.cityNowIn(city.name),
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }
}
