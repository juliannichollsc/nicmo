import 'dart:ui';

import 'package:latlong2/latlong.dart';

enum TransitMode { metro, tram, cable, bus, walk }

TransitMode transitModeFromString(String value) {
  switch (value) {
    case 'metro':
      return TransitMode.metro;
    case 'tram':
      return TransitMode.tram;
    case 'cable':
      return TransitMode.cable;
    case 'bus':
      return TransitMode.bus;
    default:
      return TransitMode.walk;
  }
}

class TransitStation {
  final String id;
  final String name;
  final LatLng position;
  final List<String> lineIds;

  const TransitStation({
    required this.id,
    required this.name,
    required this.position,
    required this.lineIds,
  });

  factory TransitStation.fromJson(Map<String, dynamic> json) {
    return TransitStation(
      id: json['id'] as String,
      name: json['name'] as String,
      position: LatLng(
        (json['lat'] as num).toDouble(),
        (json['lng'] as num).toDouble(),
      ),
      lineIds: List<String>.from(json['lines'] as List? ?? const []),
    );
  }
}

/// How lines are grouped in the app (map filter, lines list). The first
/// three form the Metro (rail and cable); the rest are buses.
enum LineGroup {
  metro,
  tram,
  cable,

  /// Bus rapid transit with stations (Metroplús, line O).
  metroplus,

  /// Integrated feeder routes of the Metro ("rutas integradas").
  feeder,

  /// Conventional public buses ("transporte público colectivo").
  bus;

  bool get isBus => index >= metroplus.index;

  /// Many lines along streets: shown from a neighbourhood zoom.
  bool get isStreetBus => this == feeder || this == bus;

  static const metroGroups = [metro, tram, cable];
  static const busGroups = [metroplus, feeder, bus];
}

/// A stop of a feeder bus along its street path (shown on the map; the
/// planner boards and alights these buses anywhere along the path).
class LineStop {
  final String name;
  final LatLng position;

  const LineStop(this.name, this.position);
}

class TransitLine {
  final String id;
  final String name;
  final TransitMode mode;
  final Color color;
  final double avgSpeedKmh;
  final double headwayMin;
  final bool approximate;
  final List<String> stationIds;
  final List<LatLng> shape;
  final List<LineStop> stops;

  /// Code shown to riders when it differs from the id ("160" for a bus
  /// whose id is "BU-160-ENV").
  final String? code;

  /// Municipalities the line runs through (street buses), in order.
  final List<String> municipalities;

  const TransitLine({
    required this.id,
    required this.name,
    required this.mode,
    required this.color,
    required this.avgSpeedKmh,
    required this.headwayMin,
    required this.approximate,
    required this.stationIds,
    required this.shape,
    this.stops = const [],
    this.code,
    this.municipalities = const [],
  });

  LineGroup get group => switch (mode) {
    TransitMode.metro => LineGroup.metro,
    TransitMode.tram => LineGroup.tram,
    TransitMode.cable => LineGroup.cable,
    _ when id.startsWith('AL-') => LineGroup.feeder,
    _ when id.startsWith('BU-') => LineGroup.bus,
    _ => LineGroup.metroplus,
  };

  /// Street buses pick up and drop off anywhere along their path; trunk
  /// lines only stop at their stations.
  bool get stopsOnRequest => group.isStreetBus;

  /// Feeder routes without a real street path (only their ends are known)
  /// are not drawn: a straight line across the city would mislead.
  bool get drawable => !approximate || shape.isNotEmpty;

  factory TransitLine.fromJson(Map<String, dynamic> json) {
    final mode = transitModeFromString(json['mode'] as String);
    return TransitLine(
      id: json['id'] as String,
      name: json['name'] as String,
      mode: mode,
      color: _parseColor(json['color'] as String?),
      avgSpeedKmh:
          (json['avgSpeedKmh'] as num?)?.toDouble() ?? _defaultSpeed(mode),
      headwayMin: (json['headwayMin'] as num?)?.toDouble() ?? 6,
      approximate: json['approximate'] as bool? ?? false,
      stationIds: List<String>.from(json['stations'] as List),
      shape: json['path'] is String
          ? decodePolyline(json['path'] as String)
          : [
              for (final p in (json['shape'] as List? ?? const []))
                LatLng((p[0] as num).toDouble(), (p[1] as num).toDouble()),
            ],
      code: json['code'] as String?,
      municipalities: List<String>.from(
        json['municipalities'] as List? ?? const [],
      ),
      stops: [
        for (final s in (json['stops'] as List? ?? const []))
          LineStop(
            s[2] as String,
            LatLng((s[0] as num).toDouble(), (s[1] as num).toDouble()),
          ),
      ],
    );
  }

  static double _defaultSpeed(TransitMode mode) {
    switch (mode) {
      case TransitMode.metro:
        return 35;
      case TransitMode.tram:
        return 15;
      case TransitMode.cable:
        return 18;
      case TransitMode.bus:
        return 16;
      case TransitMode.walk:
        return 4.5;
    }
  }

  static Color _parseColor(String? hex) {
    if (hex == null || hex.length < 7) {
      return const Color(0xFF65BC4B);
    }
    return Color(int.parse('FF${hex.substring(1, 7)}', radix: 16));
  }
}

class TransitNetwork {
  final Map<String, TransitLine> lines;
  final Map<String, TransitStation> stations;

  const TransitNetwork({required this.lines, required this.stations});

  /// A city whose network is not in the app yet.
  static const empty = TransitNetwork(lines: {}, stations: {});

  factory TransitNetwork.fromJson(Map<String, dynamic> json) =>
      TransitNetwork.fromLayers([json]);

  /// Merges the layer files of a city (metro, buses...). Stations are shared
  /// by id across layers; the lines of each station are derived from the
  /// lines themselves, so a layer never lists lines of another one.
  factory TransitNetwork.fromLayers(List<Map<String, dynamic>> layers) {
    final parsed = <String, TransitStation>{};
    for (final layer in layers) {
      for (final s in layer['stations'] as List? ?? const []) {
        final station = TransitStation.fromJson(s as Map<String, dynamic>);
        parsed.putIfAbsent(station.id, () => station);
      }
    }
    final lines = <String, TransitLine>{};
    for (final layer in layers) {
      for (final l in layer['lines'] as List? ?? const []) {
        final line = TransitLine.fromJson(l as Map<String, dynamic>);
        // Skip lines referencing unknown stations instead of crashing.
        if (line.stationIds.length >= 2 &&
            line.stationIds.every(parsed.containsKey)) {
          lines[line.id] = line;
        }
      }
    }
    final lineIds = <String, List<String>>{};
    for (final line in lines.values) {
      for (final id in line.stationIds.toSet()) {
        (lineIds[id] ??= []).add(line.id);
      }
    }
    final stations = <String, TransitStation>{
      for (final s in parsed.values)
        s.id: TransitStation(
          id: s.id,
          name: s.name,
          position: s.position,
          lineIds: lineIds[s.id] ?? const [],
        ),
    };
    return TransitNetwork(lines: lines, stations: stations);
  }

  List<TransitStation> stationsOf(TransitLine line) => [
    for (final id in line.stationIds) stations[id]!,
  ];
}

/// Decodes an encoded polyline (Google format, precision 5).
List<LatLng> decodePolyline(String text) {
  const factor = 1e5;
  final points = <LatLng>[];
  var index = 0, lat = 0, lng = 0;
  int next() {
    var shift = 0, result = 0, b = 0;
    do {
      b = text.codeUnitAt(index++) - 63;
      result |= (b & 0x1F) << shift;
      shift += 5;
    } while (b >= 0x20);
    // Not `~(result >> 1)`: on the web, bitwise NOT gives an unsigned
    // 32-bit number and negative deltas would become huge.
    return (result & 1) != 0 ? -(result >> 1) - 1 : result >> 1;
  }

  while (index < text.length) {
    lat += next();
    lng += next();
    points.add(LatLng(lat / factor, lng / factor));
  }
  return points;
}
