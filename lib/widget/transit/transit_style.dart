import 'package:flutter/material.dart';
import 'package:nicmo/domain/transit/itinerary.dart';
import 'package:nicmo/domain/transit/transit_network.dart';
import 'package:nicmo/il8n/app_localizations.dart';
import 'package:nicmo/theme/metro_theme.dart';

IconData modeIcon(TransitMode mode) {
  switch (mode) {
    case TransitMode.metro:
      return Icons.subway_rounded;
    case TransitMode.tram:
      return Icons.tram_rounded;
    case TransitMode.cable:
      return Icons.cable_rounded; // only a fallback, see [ModeIcon]
    case TransitMode.bus:
      return Icons.directions_bus_rounded;
    case TransitMode.walk:
      return Icons.directions_walk_rounded;
  }
}

String modeLabel(AppLocalizations l10n, TransitMode mode) {
  switch (mode) {
    case TransitMode.metro:
      return l10n.modeMetro;
    case TransitMode.tram:
      return l10n.modeTram;
    case TransitMode.cable:
      return l10n.modeCable;
    case TransitMode.bus:
      return l10n.modeBus;
    case TransitMode.walk:
      return l10n.modeWalk;
  }
}

/// Line colour as shown in the app (map, menu, lists).
///
/// On the light theme, light line colours (yellow, lime, light teal) are
/// darkened just enough to reach a 3:1 contrast with the pale map (WCAG
/// minimum for graphics); the hue is kept, so a line looks the same on the
/// map and in the menu.
Color lineColor(Color color, Brightness brightness) {
  if (brightness == Brightness.dark) return color;
  return _onLightMap[color] ??= () {
    const background = Color(0xFFF2F3F0);
    final bgLuminance = background.computeLuminance();
    var hsl = HSLColor.fromColor(color);
    var result = color;
    while ((bgLuminance + 0.05) / (result.computeLuminance() + 0.05) < 3.2 &&
        hsl.lightness > 0.05) {
      hsl = hsl.withLightness(hsl.lightness - 0.01);
      result = hsl.toColor();
    }
    return result;
  }();
}

final Map<Color, Color> _onLightMap = {};

/// Colour of a leg: its line, or walking / car grey (dark grey on the light
/// theme, light grey on the dark one).
Color legColor(ItineraryLeg leg, Brightness brightness) {
  final dark = brightness == Brightness.dark;
  if (leg.isRideHail) return dark ? MetroPalette.car : MetroPalette.carOnLight;
  final line = leg.line;
  if (line == null) return dark ? MetroPalette.walk : MetroPalette.walkOnLight;
  return lineColor(line.color, brightness);
}

/// Brand names are not translated.
String rideHailName(RideHailService service) => switch (service) {
  RideHailService.uber => 'Uber',
  RideHailService.indrive => 'inDrive',
};

/// Where a walking (or car) leg starts / ends, readable in any language.
String legSourceName(AppLocalizations l10n, ItineraryLeg leg) =>
    leg.fromName.isEmpty ? l10n.yourStart : leg.fromName;

String legTargetName(AppLocalizations l10n, ItineraryLeg leg) {
  if (leg.walkToLine != null) {
    return l10n.busStreetOf(lineLabel(l10n, leg.walkToLine!));
  }
  return leg.toName.isEmpty ? l10n.yourDestination : leg.toName;
}

/// Readable text colour on top of a line colour.
Color onLineColor(Color color) =>
    color.computeLuminance() > 0.5 ? Colors.black87 : Colors.white;

/// Terminal station the vehicle is heading to, used as "towards X".
String legTerminal(TransitNetwork network, ItineraryLeg leg) {
  if (leg.headsign != null) return leg.headsign!;
  final line = leg.line!;
  if (leg.stops.length < 2) return network.stations[line.stationIds.last]!.name;
  final from = line.stationIds.indexOf(leg.stops.first.id);
  final to = line.stationIds.indexOf(leg.stops.last.id);
  final terminalId = to >= from ? line.stationIds.last : line.stationIds.first;
  return network.stations[terminalId]!.name;
}

/// Short code shown on badges: "A", "K", "MP1", "C3-001", "160".
String lineCode(TransitLine line) =>
    line.group.isStreetBus ? (line.code ?? line.id.substring(3)) : line.id;

/// Line label in the app language ("Línea A", "Line A", "Linie A", "A 线").
String lineLabel(AppLocalizations l10n, TransitLine line) {
  if (line.group == LineGroup.feeder) return l10n.feederRoute(lineCode(line));
  if (line.group == LineGroup.bus) return l10n.busRoute(lineCode(line));
  if (line.id.startsWith('MP')) return l10n.metroplusLine(line.id.substring(2));
  return l10n.lineName(line.id);
}

/// Short instruction for a leg, shared by the results list and trip screen.
String legInstruction(
  AppLocalizations l10n,
  TransitNetwork network,
  ItineraryLeg leg,
) {
  if (leg.isRideHail) {
    // Generic car while planning; the app's name once it was chosen.
    return leg.rideHail == null
        ? l10n.carTo(legTargetName(l10n, leg))
        : l10n.rideHailTo(
            rideHailName(leg.rideHail!),
            legTargetName(l10n, leg),
          );
  }
  if (leg.isWalk) {
    if (leg.walkToLine != null) {
      return l10n.walkToBusStreet(lineLabel(l10n, leg.walkToLine!));
    }
    return l10n.walkTo(leg.toName.isEmpty ? l10n.yourDestination : leg.toName);
  }
  return l10n.boardTowards(
    lineLabel(l10n, leg.line!),
    legTerminal(network, leg),
  );
}

String legDetail(AppLocalizations l10n, ItineraryLeg leg) {
  if (leg.isRideHail) {
    return l10n.rideHailDetail(
      (leg.durationMin + leg.waitMin).ceil(),
      leg.waitMin.round(),
      (leg.distanceMeters / 1000).toStringAsFixed(1),
    );
  }
  final minutes = l10n.minutesShort(leg.durationMin.ceil());
  if (leg.isWalk) {
    return '$minutes · ${l10n.walkDistance(leg.distanceMeters.round())}';
  }
  final getOff = leg.alightsRoadside
      ? l10n.getOffNear(leg.toName.isEmpty ? l10n.yourDestination : leg.toName)
      : l10n.getOffAt(leg.toName);
  return [
    if (leg.boardsRoadside) l10n.boardOnStreet,
    if (leg.stopCount > 0) l10n.stopsCount(leg.stopCount),
    minutes,
    getOff,
  ].join(' · ');
}

class LineBadge extends StatelessWidget {
  final ItineraryLeg leg;
  final bool compact;

  const LineBadge({super.key, required this.leg, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final color = legColor(leg, Theme.of(context).brightness);
    final fg = onLineColor(color);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 6 : 8, vertical: 4),
      decoration: BoxDecoration(
        color: leg.isWalk && !leg.isRideHail
            ? color.withValues(alpha: 0.25)
            : color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          leg.isRideHail
              ? Icon(Icons.local_taxi_rounded, size: 16, color: fg)
              : ModeIcon(
                  leg.mode,
                  size: 16,
                  color: leg.isWalk
                      ? Theme.of(context).colorScheme.onSurface
                      : fg,
                ),
          if (!leg.isWalk) ...[
            const SizedBox(width: 4),
            Text(
              lineCode(leg.line!),
              style: TextStyle(
                color: fg,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ] else if (!compact) ...[
            const SizedBox(width: 2),
            Text(
              '${(leg.durationMin + leg.waitMin).ceil()}′',
              style: TextStyle(
                fontSize: 11,
                color: leg.isRideHail
                    ? fg
                    : Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Mode icon; Material has no gondola glyph so Metrocable is painted.
class ModeIcon extends StatelessWidget {
  final TransitMode mode;
  final double size;
  final Color? color;

  const ModeIcon(this.mode, {super.key, this.size = 24, this.color});

  @override
  Widget build(BuildContext context) {
    final resolved = color ?? IconTheme.of(context).color ?? Colors.white;
    if (mode != TransitMode.cable) {
      return Icon(modeIcon(mode), size: size, color: resolved);
    }
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(painter: _GondolaPainter(resolved)),
    );
  }
}

class _GondolaPainter extends CustomPainter {
  final Color color;

  const _GondolaPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    // Isolated layer so the window "clear" does not punch through parents.
    canvas.saveLayer(Offset.zero & size, Paint());
    final stroke = Paint()
      ..color = color
      ..strokeWidth = w * 0.08
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(w * 0.08, h * 0.22),
      Offset(w * 0.92, h * 0.08),
      stroke,
    );
    canvas.drawLine(
      Offset(w * 0.5, h * 0.15),
      Offset(w * 0.5, h * 0.36),
      stroke,
    );
    final cabin = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.2, h * 0.36, w * 0.6, h * 0.52),
      Radius.circular(w * 0.12),
    );
    canvas.drawRRect(cabin, Paint()..color = color);
    final window = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.29, h * 0.45, w * 0.42, h * 0.18),
      Radius.circular(w * 0.05),
    );
    canvas.drawRRect(window, Paint()..blendMode = BlendMode.clear);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_GondolaPainter oldDelegate) => oldDelegate.color != color;
}

/// Name of a kind of transport (map filter, lines list).
String groupLabel(AppLocalizations l10n, LineGroup group) => switch (group) {
  LineGroup.metro => l10n.modeMetro,
  LineGroup.tram => l10n.modeTram,
  LineGroup.cable => l10n.modeCable,
  LineGroup.metroplus => l10n.groupMetroplus,
  LineGroup.feeder => l10n.groupFeeder,
  LineGroup.bus => l10n.groupBus,
};

/// Name of the Metro (rail and cable) or bus family of groups.
String familyLabel(AppLocalizations l10n, bool buses) =>
    buses ? l10n.familyBuses : l10n.familyMetro;

/// Icon of a kind of transport.
Widget groupIcon(LineGroup group, {double size = 22, Color? color}) =>
    switch (group) {
      LineGroup.metro => ModeIcon(TransitMode.metro, size: size, color: color),
      LineGroup.tram => ModeIcon(TransitMode.tram, size: size, color: color),
      LineGroup.cable => ModeIcon(TransitMode.cable, size: size, color: color),
      LineGroup.metroplus => Icon(
        Icons.directions_bus_filled_rounded,
        size: size,
        color: color,
      ),
      LineGroup.feeder => Icon(
        Icons.airport_shuttle_rounded,
        size: size,
        color: color,
      ),
      LineGroup.bus => Icon(
        Icons.directions_bus_rounded,
        size: size,
        color: color,
      ),
    };

/// Representative colour of a kind of transport (its main line).
Color groupColor(LineGroup group) => switch (group) {
  LineGroup.metro => const Color(0xFF215CA0),
  LineGroup.tram => const Color(0xFF44A925),
  LineGroup.cable => const Color(0xFF8322A7),
  LineGroup.metroplus => const Color(0xFF11707C),
  LineGroup.feeder => const Color(0xFFE65100),
  LineGroup.bus => const Color(0xFF3949AB),
};
