import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:nicmo/domain/city/city.dart';
import 'package:nicmo/domain/transit/itinerary.dart';
import 'package:nicmo/domain/transit/transit_network.dart';
import 'package:nicmo/theme/metro_theme.dart';
import 'package:nicmo/widget/map/base_map_layer.dart';
import 'package:nicmo/widget/transit/transit_style.dart';

/// Free OpenStreetMap base map without street names (see [BaseMapLayer]),
/// with the network of the city on top and an animated itinerary.
class MetroMap extends StatefulWidget {
  static const LatLng medellin = LatLng(6.2476, -75.5658);

  /// City on the map: initial camera and data credits. Changing it flies
  /// the camera there.
  final City? city;
  final TransitNetwork? network;
  final Itinerary? itinerary;
  final LatLng? origin;
  final LatLng? destination;
  final LatLng? userPosition;
  final double? userAccuracy;
  final LatLng? vehiclePosition;
  final ItineraryLeg? vehicleLeg;
  final ValueChanged<LatLng>? onTap;

  /// Show only this line of the network (chosen in the side menu).
  final String? lineFilter;

  /// Show only this kind of transport (map filter); [lineFilter] wins.
  final LineGroup? groupFilter;

  /// Called with the map centre whenever the camera moves.
  final ValueChanged<LatLng>? onCameraMoved;
  final EdgeInsets fitPadding;

  const MetroMap({
    super.key,
    this.city,
    this.network,
    this.itinerary,
    this.origin,
    this.destination,
    this.userPosition,
    this.userAccuracy,
    this.vehiclePosition,
    this.vehicleLeg,
    this.onTap,
    this.lineFilter,
    this.groupFilter,
    this.onCameraMoved,
    this.fitPadding = const EdgeInsets.fromLTRB(48, 180, 48, 300),
  });

  @override
  State<MetroMap> createState() => MetroMapState();
}

class MetroMapState extends State<MetroMap> with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  late final AnimationController _reveal = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..repeat();
  AnimationController? _camera;
  bool _ready = false;

  /// Camera move requested before the map was ready; applied on ready.
  VoidCallback? _pendingCamera;

  /// Last camera shown and its city. A map rebuilt for another city (the
  /// city was changed on a screen covering it) starts there and flies over.
  static ({String city, LatLng center, double zoom})? _lastCamera;
  late final bool _flyIn =
      widget.city != null &&
      _lastCamera != null &&
      _lastCamera!.city != widget.city!.id;
  bool _showStations = false;

  /// Feeder buses are many: on the whole-network view they appear from a
  /// neighbourhood zoom, and their stops closer still.
  bool _showFeeders = false;
  bool _showStops = false;

  /// Station names: 0 hidden, 1 only along the selected route, 2 all
  /// rail / tram / cable stations.
  int _labelLevel = 0;

  static const _labelledModes = {
    TransitMode.metro,
    TransitMode.tram,
    TransitMode.cable,
  };

  @override
  void didUpdateWidget(MetroMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    final city = widget.city;
    if (city != null && city.id != oldWidget.city?.id) {
      // The city is usually chosen on a screen covering the map: fly once
      // that screen has gone, so the flight is seen.
      Future<void>.delayed(const Duration(milliseconds: 650), () {
        if (mounted && widget.city?.id == city.id) {
          flyTo(city.center, city.zoom);
        }
      });
    }
    final before = oldWidget.itinerary;
    final after = widget.itinerary;
    // Same route with a leg switched between walking and car: redraw in
    // place, without replaying the reveal or moving the camera.
    final sameRoute =
        before != null &&
        after != null &&
        before.signature == after.signature &&
        before.legs.length == after.legs.length;
    if (widget.lineFilter != oldWidget.lineFilter &&
        widget.lineFilter != null &&
        widget.network != null) {
      final line = widget.network!.lines[widget.lineFilter];
      if (line != null) {
        fitPoints(
          line.shape.isNotEmpty
              ? line.shape
              : [for (final s in widget.network!.stationsOf(line)) s.position],
        );
      }
    }
    if (widget.groupFilter != oldWidget.groupFilter &&
        widget.groupFilter != null &&
        widget.lineFilter == null &&
        widget.network != null) {
      final points = [
        for (final line in widget.network!.lines.values)
          if (line.group == widget.groupFilter && line.drawable)
            ...line.shape.isNotEmpty
                ? line.shape
                : [
                    for (final s in widget.network!.stationsOf(line))
                      s.position,
                  ],
      ];
      if (points.isNotEmpty) fitPoints(points);
    }
    if (!identical(before, after) && !sameRoute) {
      _reveal.forward(from: 0);
      if (after != null) fitPoints(after.fullPath);
    } else if (widget.itinerary == null &&
        (oldWidget.origin != widget.origin ||
            oldWidget.destination != widget.destination)) {
      fitPoints([?widget.origin, ?widget.destination]);
    }
  }

  @override
  void dispose() {
    _reveal.dispose();
    _pulse.dispose();
    _camera?.dispose();
    _mapController.dispose();
    super.dispose();
  }

  /// Smoothly flies the camera to [center] / [zoom].
  void animateTo(LatLng center, [double? zoom]) {
    if (!_ready) {
      _pendingCamera = () => animateTo(center, zoom);
      return;
    }
    final camera = _mapController.camera;
    final latTween = Tween(begin: camera.center.latitude, end: center.latitude);
    final lngTween = Tween(
      begin: camera.center.longitude,
      end: center.longitude,
    );
    final zoomTween = Tween(begin: camera.zoom, end: zoom ?? camera.zoom);
    _camera?.dispose();
    final controller = _camera = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    final curve = CurvedAnimation(
      parent: controller,
      curve: Curves.easeInOutCubic,
    );
    controller.addListener(() {
      _mapController.move(
        LatLng(latTween.evaluate(curve), lngTween.evaluate(curve)),
        zoomTween.evaluate(curve),
      );
    });
    controller.forward();
  }

  /// Long camera flight (to another city): zooms out to see both places,
  /// travels, and zooms back in, instead of panning across the country at
  /// street level.
  void flyTo(LatLng center, double zoom) {
    if (!_ready) {
      _pendingCamera = () => flyTo(center, zoom);
      return;
    }
    final camera = _mapController.camera;
    final start = camera.center;
    final startZoom = camera.zoom;
    final km = const Distance().as(LengthUnit.Kilometer, start, center);
    if (km < 30) {
      animateTo(center, zoom);
      return;
    }
    // Zoom level that shows both ends (each level halves the span).
    final overview = (zoom - math.log(km / 8) / math.ln2).clamp(5.0, zoom);
    final dip = math.max(0.0, math.min(startZoom, zoom) - overview);
    _camera?.dispose();
    final controller = _camera = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );
    final curve = CurvedAnimation(
      parent: controller,
      curve: Curves.easeInOutCubic,
    );
    controller.addListener(() {
      final t = curve.value;
      // The zoom dips most at mid-flight and lands exactly on [zoom].
      final z =
          startZoom +
          (zoom - startZoom) * controller.value -
          dip * math.sin(math.pi * controller.value);
      _mapController.move(
        LatLng(
          start.latitude + (center.latitude - start.latitude) * t,
          start.longitude + (center.longitude - start.longitude) * t,
        ),
        z,
      );
    });
    controller.forward();
  }

  void fitPoints(List<LatLng> points) {
    if (points.isEmpty) return;
    if (!_ready) {
      _pendingCamera = () => fitPoints(points);
      return;
    }
    if (points.length == 1) {
      animateTo(points.first, 15);
      return;
    }
    final target = CameraFit.bounds(
      bounds: LatLngBounds.fromPoints(points),
      padding: widget.fitPadding,
      maxZoom: 16,
    ).fit(_mapController.camera);
    animateTo(target.center, target.zoom);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: _flyIn
            ? _lastCamera!.center
            : (widget.city?.center ?? MetroMap.medellin),
        initialZoom: _flyIn ? _lastCamera!.zoom : (widget.city?.zoom ?? 12.5),
        // Low enough for the flight between cities (see flyTo).
        minZoom: 5,
        maxZoom: 18,
        backgroundColor: isDark ? MetroPalette.night : const Color(0xFFF2F5F3),
        onMapReady: () {
          final city = widget.city;
          if (city != null) {
            // Also when the camera never moves (onPositionChanged).
            _lastCamera = (
              city: city.id,
              center: _mapController.camera.center,
              zoom: _mapController.camera.zoom,
            );
          }
          if (_flyIn && city != null) {
            Future<void>.delayed(const Duration(milliseconds: 650), () {
              if (mounted && widget.city?.id == city.id) {
                flyTo(city.center, city.zoom);
              }
            });
          }
          _ready = true;
          final pending = _pendingCamera;
          _pendingCamera = null;
          pending?.call();
          if (widget.itinerary != null) {
            fitPoints(widget.itinerary!.fullPath);
            _reveal.forward(from: 0);
          }
        },
        onTap: widget.onTap == null ? null : (_, point) => widget.onTap!(point),
        onPositionChanged: (camera, _) {
          if (widget.city != null) {
            _lastCamera = (
              city: widget.city!.id,
              center: camera.center,
              zoom: camera.zoom,
            );
          }
          widget.onCameraMoved?.call(camera.center);
          final show = camera.zoom >= 13.5;
          final labels = camera.zoom >= 14 ? 2 : (camera.zoom >= 12.5 ? 1 : 0);
          final feeders = camera.zoom >= 14;
          final stops = camera.zoom >= 15;
          if (show != _showStations ||
              labels != _labelLevel ||
              feeders != _showFeeders ||
              stops != _showStops) {
            setState(() {
              _showStations = show;
              _labelLevel = labels;
              _showFeeders = feeders;
              _showStops = stops;
            });
          }
        },
      ),
      children: [
        const BaseMapLayer(),
        if (widget.network != null) ..._networkLayers(widget.network!),
        if (widget.itinerary != null) _routeLayer(widget.itinerary!),
        if (widget.network != null && _labelLevel > 0)
          _stationLabels(widget.network!),
        if (widget.userPosition != null && (widget.userAccuracy ?? 0) > 5)
          CircleLayer(
            circles: [
              CircleMarker(
                point: widget.userPosition!,
                radius: widget.userAccuracy!.clamp(5, 5000),
                useRadiusInMeter: true,
                color: const Color(0xFF29B6F6).withValues(alpha: 0.14),
                borderColor: const Color(0xFF29B6F6).withValues(alpha: 0.5),
                borderStrokeWidth: 1,
              ),
            ],
          ),
        MarkerLayer(markers: _markers()),
        RichAttributionWidget(
          alignment: AttributionAlignment.bottomLeft,
          // Map texts do not follow the app language (data source names).
          attributions: [
            const TextSourceAttribution('© OpenStreetMap'),
            const TextSourceAttribution('OpenFreeMap'),
            // Transit data of the city (e.g. Metro de Medellín open data,
            // CC BY-SA 4.0).
            for (final credit in widget.city?.attributions ?? const <String>[])
              TextSourceAttribution(credit),
          ],
        ),
      ],
    );
  }

  /// Lines on screen: the chosen line, the chosen kind of transport, or
  /// the whole network (street buses only from a neighbourhood zoom).
  List<TransitLine> _visibleLines(TransitNetwork network) {
    final single = network.lines[widget.lineFilter];
    if (single != null) return [single];
    final group = widget.groupFilter;
    return [
      for (final line in network.lines.values)
        if (line.drawable &&
            (group != null
                ? line.group == group
                : (!line.group.isStreetBus || _showFeeders)))
          line,
    ];
  }

  List<Widget> _networkLayers(TransitNetwork network) {
    final brightness = Theme.of(context).brightness;
    final dim = widget.itinerary != null;
    final lines = _visibleLines(network)
      // Draw buses first so rail lines stay on top.
      ..sort((a, b) => b.mode.index.compareTo(a.mode.index));
    final shown = {for (final line in lines) line.id};
    final singleLine = widget.lineFilter != null;
    return [
      PolylineLayer(
        polylines: [
          for (final line in lines)
            Polyline(
              points: line.shape.isNotEmpty
                  ? line.shape
                  : [for (final s in network.stationsOf(line)) s.position],
              // Same colour as the line in the menu and the lines list,
              // nearly opaque so each line can be told apart.
              color: lineColor(
                line.color,
                brightness,
              ).withValues(alpha: dim ? 0.18 : 0.85),
              strokeWidth: line.mode == TransitMode.bus ? 3 : 4,
              // Buses dashed ("- - -") to set them apart from rail lines;
              // cables dotted, like the cabins.
              pattern: switch (line.mode) {
                TransitMode.bus => StrokePattern.dashed(segments: const [8, 6]),
                TransitMode.cable => const StrokePattern.dotted(
                  spacingFactor: 1.6,
                ),
                _ => const StrokePattern.solid(),
              },
            ),
        ],
      ),
      // Feeder bus stops: small dots in the colour of their route.
      if (!dim && (_showStops || (singleLine && _showStations)))
        CircleLayer(
          circles: [
            for (final line in lines)
              for (final stop in line.stops)
                CircleMarker(
                  point: stop.position,
                  radius: 2.5,
                  color: Colors.white,
                  borderColor: lineColor(line.color, brightness),
                  borderStrokeWidth: 1.5,
                ),
          ],
        ),
      if (_showStations)
        CircleLayer(
          circles: [
            for (final station in network.stations.values)
              if (station.lineIds.any(shown.contains))
                CircleMarker(
                  point: station.position,
                  radius: station.lineIds.length > 1 ? 5 : 3.5,
                  color: Colors.white.withValues(alpha: dim ? 0.4 : 0.9),
                  borderColor: lineColor(
                    network
                        .lines[station.lineIds.firstWhere(shown.contains)]!
                        .color,
                    brightness,
                  ),
                  borderStrokeWidth: 2,
                ),
          ],
        ),
    ];
  }

  /// Names of metro, tram and Metrocable stations (buses are left out).
  /// Stations of the selected route show from further away and stand out.
  Widget _stationLabels(TransitNetwork network) {
    final onRoute = <String>{
      for (final leg in widget.itinerary?.rideLegs ?? const <ItineraryLeg>[])
        if (_labelledModes.contains(leg.mode))
          for (final stop in leg.stops) stop.id,
    };
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return MarkerLayer(
      markers: [
        for (final station in network.stations.values)
          if ((_labelLevel == 2 || onRoute.contains(station.id)) &&
              (widget.lineFilter == null ||
                  station.lineIds.contains(widget.lineFilter)) &&
              (widget.groupFilter == null ||
                  widget.lineFilter != null ||
                  station.lineIds.any(
                    (id) => network.lines[id]?.group == widget.groupFilter,
                  )) &&
              station.lineIds.any(
                (id) => _labelledModes.contains(network.lines[id]?.mode),
              ))
            Marker(
              point: station.position,
              width: 160,
              height: 20,
              // The label starts just right of the station dot.
              alignment: Alignment.centerRight,
              child: IgnorePointer(
                child: _StationLabel(
                  name: station.name,
                  highlighted: onRoute.contains(station.id),
                  dimmed:
                      widget.itinerary != null && !onRoute.contains(station.id),
                  isDark: isDark,
                ),
              ),
            ),
      ],
    );
  }

  Widget _routeLayer(Itinerary itinerary) {
    final brightness = Theme.of(context).brightness;
    return AnimatedBuilder(
      animation: _reveal,
      builder: (context, _) {
        final progress = Curves.easeInOutCubic.transform(_reveal.value);
        final partial = _revealLegs(itinerary.legs, progress);
        return PolylineLayer(
          polylines: [
            for (final (leg, points) in partial)
              Polyline(
                points: points,
                color: legColor(leg, brightness),
                strokeWidth: leg.isRideHail ? 5 : (leg.isWalk ? 5 : 7),
                borderColor: leg.isWalk
                    ? Colors.transparent
                    : Colors.white.withValues(alpha: 0.85),
                borderStrokeWidth: leg.isWalk ? 0 : 2,
                // Walking: dotted. Car (Uber / inDrive): dashed.
                pattern: leg.isRideHail
                    ? StrokePattern.dashed(segments: const [14, 8])
                    : leg.isWalk
                    ? const StrokePattern.dotted(spacingFactor: 2)
                    : const StrokePattern.solid(),
              ),
          ],
        );
      },
    );
  }

  /// Cuts the itinerary at [progress] of its total length so the route
  /// appears to be drawn from origin to destination.
  static List<(ItineraryLeg, List<LatLng>)> _revealLegs(
    List<ItineraryLeg> legs,
    double progress,
  ) {
    const distance = Distance();
    double length(List<LatLng> p) {
      var total = 0.0;
      for (var i = 0; i + 1 < p.length; i++) {
        total += distance(p[i], p[i + 1]);
      }
      return total;
    }

    final total = legs.fold<double>(0, (sum, l) => sum + length(l.path));
    var budget = total * progress;
    final result = <(ItineraryLeg, List<LatLng>)>[];
    for (final leg in legs) {
      if (budget <= 0 || leg.path.length < 2) break;
      final points = <LatLng>[leg.path.first];
      for (var i = 0; i + 1 < leg.path.length; i++) {
        final a = leg.path[i];
        final b = leg.path[i + 1];
        final d = distance(a, b);
        if (d <= budget) {
          points.add(b);
          budget -= d;
        } else {
          final t = d == 0 ? 0.0 : budget / d;
          points.add(
            LatLng(
              a.latitude + (b.latitude - a.latitude) * t,
              a.longitude + (b.longitude - a.longitude) * t,
            ),
          );
          budget = 0;
          break;
        }
      }
      result.add((leg, points));
    }
    return result;
  }

  List<Marker> _markers() {
    return [
      if (widget.userPosition != null)
        Marker(
          point: widget.userPosition!,
          width: 44,
          height: 44,
          child: _Pulse(
            animation: _pulse,
            color: const Color(0xFF4FC3F7),
            child: const _Dot(color: Color(0xFF29B6F6)),
          ),
        ),
      if (widget.origin != null)
        Marker(
          point: widget.origin!,
          width: 48,
          height: 48,
          child: _Pulse(
            animation: _pulse,
            color: MetroPalette.greenBright,
            child: const _Dot(color: MetroPalette.green),
          ),
        ),
      if (widget.destination != null)
        Marker(
          key: ValueKey(widget.destination),
          point: widget.destination!,
          width: 48,
          height: 56,
          alignment: Alignment.topCenter,
          child: const _DropPin(),
        ),
      if (widget.vehiclePosition != null && widget.vehicleLeg != null)
        Marker(
          point: widget.vehiclePosition!,
          width: 46,
          height: 46,
          child: _VehicleMarker(leg: widget.vehicleLeg!),
        ),
    ];
  }
}

class _Dot extends StatelessWidget {
  final Color color;

  const _Dot({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: const [BoxShadow(blurRadius: 6, color: Colors.black38)],
      ),
    );
  }
}

class _Pulse extends StatelessWidget {
  final Animation<double> animation;
  final Color color;
  final Widget child;

  const _Pulse({
    required this.animation,
    required this.color,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      child: child,
      builder: (context, child) {
        final t = animation.value;
        return Stack(
          alignment: Alignment.center,
          children: [
            Transform.scale(
              scale: 0.4 + t * 1.6,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(alpha: (1 - t) * 0.45),
                ),
              ),
            ),
            child!,
          ],
        );
      },
    );
  }
}

/// Destination pin that drops in with a bounce every time it is placed.
class _DropPin extends StatelessWidget {
  const _DropPin();

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 700),
      curve: Curves.bounceOut,
      builder: (context, t, child) => Transform.translate(
        offset: Offset(0, -40 * (1 - t)),
        child: Opacity(opacity: t.clamp(0, 1), child: child),
      ),
      child: const Icon(
        Icons.location_on_rounded,
        size: 48,
        color: MetroPalette.green,
        shadows: [Shadow(blurRadius: 8, color: Colors.black45)],
      ),
    );
  }
}

class _VehicleMarker extends StatelessWidget {
  final ItineraryLeg leg;

  const _VehicleMarker({required this.leg});

  @override
  Widget build(BuildContext context) {
    final color = leg.isWalk && !leg.isRideHail
        ? MetroPalette.green
        : legColor(leg, Theme.of(context).brightness);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(blurRadius: 12, color: color.withValues(alpha: 0.7)),
        ],
      ),
      alignment: Alignment.center,
      child: leg.isRideHail
          ? Icon(Icons.local_taxi_rounded, size: 22, color: onLineColor(color))
          : ModeIcon(leg.mode, size: 22, color: onLineColor(color)),
    );
  }
}

/// Small station name with a halo so it reads over any map colour.
class _StationLabel extends StatelessWidget {
  final String name;
  final bool highlighted;
  final bool dimmed;
  final bool isDark;

  const _StationLabel({
    required this.name,
    required this.highlighted,
    required this.dimmed,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final fill = highlighted
        ? (isDark ? Colors.white : Colors.black)
        : (isDark ? const Color(0xFFD7EBDD) : const Color(0xFF26372D));
    final halo = isDark ? MetroPalette.night : Colors.white;
    final style = TextStyle(
      fontSize: highlighted ? 11.5 : 10.5,
      fontWeight: highlighted ? FontWeight.w800 : FontWeight.w600,
      letterSpacing: 0.1,
      height: 1,
    );
    return Opacity(
      opacity: dimmed ? 0.55 : 1,
      child: Padding(
        padding: const EdgeInsets.only(left: 8),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Stack(
            children: [
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.visible,
                style: style.copyWith(
                  foreground: Paint()
                    ..style = PaintingStyle.stroke
                    ..strokeWidth = 3
                    ..strokeJoin = StrokeJoin.round
                    ..color = halo.withValues(alpha: 0.9),
                ),
              ),
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.visible,
                style: style.copyWith(color: fill),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
