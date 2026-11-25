import 'dart:math' as math;

import 'package:latlong2/latlong.dart';
import 'package:nicmo/domain/transit/itinerary.dart';
import 'package:nicmo/domain/transit/transit_network.dart';
import 'package:nicmo/domain/transit/transit_services.dart';

/// Multimodal planner over the transit network of a city.
///
/// The graph has one "street" node per station and one "on board" node per
/// (line, station). Boarding costs half the headway plus a transfer penalty,
/// so Dijkstra naturally trades waiting and transfers against ride time.
/// Alternatives are produced by re-running Dijkstra with different weights
/// (fewer transfers, less walking) and by penalising lines already proposed.
class MultimodalTripPlanner implements TripPlanner {
  static const double walkMetersPerMin = 75; // ~4.5 km/h
  static const double walkDetour = 1.25;
  static const double accessRadiusMeters = 1200;
  static const double transferRadiusMeters = 450;
  static const double directWalkMaxMeters = 2500;
  static const double dwellMin = 0.4;
  static const double alightMin = 0.5;

  /// Max walk to the street of a bus route that stops anywhere on request.
  static const double roadsideRadiusMeters = 600;

  /// Integrated feeder buses ("rutas integradas") and conventional buses
  /// pick up and drop off passengers along the street; BRT (Metroplús,
  /// line O), metro, tram and cable only stop at their stations.
  static bool boardsAnywhere(TransitLine line) => line.stopsOnRequest;

  /// Route a line belongs to: the official data lists each variant of a
  /// bus route ("103" via one street or another) as its own line.
  static String routeKey(TransitLine line) =>
      line.code == null ? line.id : '${line.group.name}:${line.code}';

  static const Distance _distance = Distance();

  TransitNetwork? _cachedNetwork;
  late _Graph _graph;

  @override
  List<Itinerary> plan(
    TransitNetwork network,
    LatLng origin,
    LatLng destination, {
    String originName = '',
    String destinationName = '',
    int maxResults = 4,
  }) {
    if (!identical(_cachedNetwork, network)) {
      _graph = _Graph.build(network);
      _cachedNetwork = network;
    }
    final query = _Query(
      graph: _graph,
      origin: origin,
      destination: destination,
      originName: originName,
      destinationName: destinationName,
    );

    final found = <String, Itinerary>{};
    Itinerary? tryAdd(_Weights weights) {
      final itinerary = query.run(weights);
      if (itinerary == null || itinerary.legs.isEmpty) return null;
      // Variants of one bus route (same code) are one alternative.
      return found.putIfAbsent(
        itinerary.rideLegs.map((leg) => routeKey(leg.line!)).join('>'),
        () => itinerary,
      );
    }

    tryAdd(const _Weights());
    tryAdd(const _Weights(boardPenalty: 12));
    tryAdd(const _Weights(walkFactor: 2.5));
    for (var i = 0; i < 3 && found.isNotEmpty; i++) {
      final penalties = <String, double>{};
      for (final itinerary in found.values) {
        for (final leg in itinerary.rideLegs) {
          final key = routeKey(leg.line!);
          penalties[key] = (penalties[key] ?? 0) + 15;
        }
      }
      tryAdd(_Weights(linePenalty: penalties));
    }
    // Street buses are many and their frequencies are estimated: the best
    // trip on trunk lines (fixed stations, known frequencies) is always
    // offered when reasonable, even if a few buses are slightly faster.
    final trunk = tryAdd(const _Weights(trunkOnly: true));
    final trunkTrip =
        trunk != null && trunk.rideLegs.any((l) => !l.line!.stopsOnRequest)
        ? trunk
        : null;

    if (found.isEmpty) return const [];

    final results = found.values.toList()
      ..sort((a, b) {
        final byTime = a.totalMin.round().compareTo(b.totalMin.round());
        return byTime != 0 ? byTime : a.walkMeters.compareTo(b.walkMeters);
      });
    final best = results.first.totalMin;
    results.removeWhere((it) => it.totalMin > best * 1.8 + 10);

    final kept = results.take(maxResults).toList();
    if (trunkTrip != null &&
        results.contains(trunkTrip) &&
        !kept.contains(trunkTrip) &&
        kept.length == maxResults) {
      kept[kept.length - 1] = trunkTrip;
    }
    // Tag only the first option that is strictly better than another one.
    int? uniqueBest(num Function(Itinerary) metric) {
      final values = kept.map(metric).toList();
      final best = values.reduce((a, b) => a < b ? a : b);
      if (values.every((v) => v - best < 1)) return null;
      return values.indexWhere((v) => v - best < 1);
    }

    final fewestTransfers = uniqueBest((it) => it.transfers);
    final leastWalking = uniqueBest((it) => it.walkMeters / 50);
    final tagged = <Itinerary>[
      for (var i = 0; i < kept.length; i++)
        kept[i].withTags({
          if (i == 0) ItineraryTag.fastest,
          if (i == fewestTransfers) ItineraryTag.fewestTransfers,
          if (i == leastWalking) ItineraryTag.leastWalking,
        }),
    ];
    return tagged;
  }

  static double meters(LatLng a, LatLng b) =>
      _distance.as(LengthUnit.Meter, a, b);
}

class _Weights {
  final double walkFactor;
  final double boardPenalty;
  final Map<String, double> linePenalty;

  /// Only trunk lines with stations (metro, tram, cable, Metroplús): no
  /// street buses.
  final bool trunkOnly;

  const _Weights({
    this.walkFactor = 1,
    this.boardPenalty = 3,
    this.linePenalty = const {},
    this.trunkOnly = false,
  });
}

enum _EdgeKind { walk, board, ride, alight }

class _Edge {
  final int to;
  final _EdgeKind kind;
  final TransitLine? line;
  final double meters;
  final double minutes;
  final List<LatLng> path;

  /// Ride edges: true when travelling in the line's station order.
  final bool forward;

  const _Edge({
    required this.to,
    required this.kind,
    required this.meters,
    required this.minutes,
    this.line,
    this.path = const [],
    this.forward = true,
  });
}

/// A bus route as one polyline with distances along it ("linear reference"),
/// used to board or alight anywhere on the street.
class _LineGeometry {
  final TransitLine line;
  final List<LatLng> points;
  final List<double> cumulative;
  final List<double> stopAt; // position of each station along [points]
  final List<int> rideNodes; // on-board node of each station
  final double detour;

  _LineGeometry(
    this.line,
    this.points,
    this.cumulative,
    this.stopAt,
    this.rideNodes,
    this.detour,
  );

  double get speedMetersPerMin => line.avgSpeedKmh * 1000 / 60;

  /// Closest point of the route to [p]: (position along route, point, metres).
  (double, LatLng, double) project(LatLng p) {
    final cosLat = math.cos(p.latitude * math.pi / 180);
    var best = (0.0, points.first, double.infinity);
    for (var i = 0; i + 1 < points.length; i++) {
      final a = points[i];
      final b = points[i + 1];
      final ax = (a.longitude - p.longitude) * cosLat;
      final ay = a.latitude - p.latitude;
      final dx = (b.longitude - a.longitude) * cosLat;
      final dy = b.latitude - a.latitude;
      final len2 = dx * dx + dy * dy;
      final t = len2 == 0 ? 0.0 : (-(ax * dx + ay * dy) / len2).clamp(0.0, 1.0);
      final q = LatLng(
        a.latitude + (b.latitude - a.latitude) * t,
        a.longitude + (b.longitude - a.longitude) * t,
      );
      final d = MultimodalTripPlanner.meters(p, q);
      if (d < best.$3) {
        best = (cumulative[i] + (cumulative[i + 1] - cumulative[i]) * t, q, d);
      }
    }
    return best;
  }

  LatLng pointAt(double s) {
    for (var i = 0; i + 1 < points.length; i++) {
      if (s <= cumulative[i + 1]) {
        final span = cumulative[i + 1] - cumulative[i];
        final t = span == 0 ? 0.0 : (s - cumulative[i]) / span;
        return LatLng(
          points[i].latitude +
              (points[i + 1].latitude - points[i].latitude) * t,
          points[i].longitude +
              (points[i + 1].longitude - points[i].longitude) * t,
        );
      }
    }
    return points.last;
  }

  /// Route geometry between two positions, in travel order.
  List<LatLng> slice(double from, double to) {
    final lo = math.min(from, to);
    final hi = math.max(from, to);
    final path = <LatLng>[pointAt(lo)];
    for (var i = 0; i < points.length; i++) {
      if (cumulative[i] > lo && cumulative[i] < hi) path.add(points[i]);
    }
    path.add(pointAt(hi));
    return from <= to ? path : path.reversed.toList();
  }

  /// Ride edge between two positions along the route.
  _Edge ride(int to, double from, double target) {
    final meters = (target - from).abs() * detour;
    final stopsPassed = stopAt
        .where((s) => s > math.min(from, target) && s < math.max(from, target))
        .length;
    return _Edge(
      to: to,
      kind: _EdgeKind.ride,
      line: line,
      meters: meters,
      minutes:
          meters / speedMetersPerMin +
          MultimodalTripPlanner.dwellMin * (stopsPassed + 1),
      path: slice(from, target),
      forward: target >= from,
    );
  }
}

class _Node {
  final TransitStation station;
  final TransitLine? line; // null => street level node of the station

  const _Node(this.station, this.line);
}

class _Graph {
  final TransitNetwork network;
  final List<_Node> nodes;
  final List<List<_Edge>> adjacency;
  final Map<String, int> streetNode;
  final List<_LineGeometry> roadsideLines;

  _Graph(
    this.network,
    this.nodes,
    this.adjacency,
    this.streetNode,
    this.roadsideLines,
  );

  factory _Graph.build(TransitNetwork network) {
    final nodes = <_Node>[];
    final adjacency = <List<_Edge>>[];
    final streetNode = <String, int>{};
    final rideNode = <String, int>{};
    final roadsideLines = <_LineGeometry>[];

    int addNode(_Node node) {
      nodes.add(node);
      adjacency.add(<_Edge>[]);
      return nodes.length - 1;
    }

    for (final station in network.stations.values) {
      streetNode[station.id] = addNode(_Node(station, null));
    }

    for (final line in network.lines.values) {
      final stations = network.stationsOf(line);
      for (final station in stations) {
        final key = '${line.id}|${station.id}';
        if (rideNode.containsKey(key)) continue;
        final idx = addNode(_Node(station, line));
        rideNode[key] = idx;
        final street = streetNode[station.id]!;
        adjacency[street].add(
          _Edge(
            to: idx,
            kind: _EdgeKind.board,
            line: line,
            meters: 0,
            minutes: line.headwayMin / 2,
          ),
        );
        adjacency[idx].add(
          _Edge(
            to: street,
            kind: _EdgeKind.alight,
            meters: 0,
            minutes: MultimodalTripPlanner.alightMin,
          ),
        );
      }

      final speedMetersPerMin = line.avgSpeedKmh * 1000 / 60;
      final geometryPoints = <LatLng>[stations.first.position];
      final cumulative = <double>[0];
      final stopAt = <double>[0];
      final shapeIdx = [
        for (final s in stations) _nearestShapeIndex(line.shape, s.position),
      ];
      for (var i = 0; i + 1 < stations.length; i++) {
        final a = stations[i];
        final b = stations[i + 1];
        final forward = _segment(line, a, b, shapeIdx[i], shapeIdx[i + 1]);
        final meters = _pathLength(forward) * _detour(line.mode, line.shape);
        final minutes =
            meters / speedMetersPerMin + MultimodalTripPlanner.dwellMin;
        final from = rideNode['${line.id}|${a.id}']!;
        final to = rideNode['${line.id}|${b.id}']!;
        adjacency[from].add(
          _Edge(
            to: to,
            kind: _EdgeKind.ride,
            line: line,
            meters: meters,
            minutes: minutes,
            path: forward,
          ),
        );
        adjacency[to].add(
          _Edge(
            to: from,
            kind: _EdgeKind.ride,
            line: line,
            meters: meters,
            minutes: minutes,
            path: forward.reversed.toList(),
            forward: false,
          ),
        );
        for (final point in forward.skip(1)) {
          cumulative.add(
            cumulative.last +
                MultimodalTripPlanner.meters(geometryPoints.last, point),
          );
          geometryPoints.add(point);
        }
        stopAt.add(cumulative.last);
      }
      if (MultimodalTripPlanner.boardsAnywhere(line)) {
        roadsideLines.add(
          _LineGeometry(line, geometryPoints, cumulative, stopAt, [
            for (final s in stations) rideNode['${line.id}|${s.id}']!,
          ], _detour(line.mode, line.shape)),
        );
      }
    }

    // Walking transfers between nearby but distinct stations.
    final stationList = network.stations.values.toList();
    for (var i = 0; i < stationList.length; i++) {
      for (var j = i + 1; j < stationList.length; j++) {
        final a = stationList[i];
        final b = stationList[j];
        final d = MultimodalTripPlanner.meters(a.position, b.position);
        if (d > MultimodalTripPlanner.transferRadiusMeters) continue;
        final walked = d * MultimodalTripPlanner.walkDetour;
        final minutes = walked / MultimodalTripPlanner.walkMetersPerMin;
        adjacency[streetNode[a.id]!].add(
          _Edge(
            to: streetNode[b.id]!,
            kind: _EdgeKind.walk,
            meters: walked,
            minutes: minutes,
            path: [a.position, b.position],
          ),
        );
        adjacency[streetNode[b.id]!].add(
          _Edge(
            to: streetNode[a.id]!,
            kind: _EdgeKind.walk,
            meters: walked,
            minutes: minutes,
            path: [b.position, a.position],
          ),
        );
      }
    }

    return _Graph(network, nodes, adjacency, streetNode, roadsideLines);
  }

  static double _detour(TransitMode mode, List<LatLng> shape) {
    if (shape.isNotEmpty) return 1;
    switch (mode) {
      case TransitMode.bus:
        return 1.3;
      case TransitMode.tram:
        return 1.15;
      case TransitMode.metro:
        return 1.05;
      default:
        return 1;
    }
  }

  static int _nearestShapeIndex(List<LatLng> shape, LatLng p) {
    var best = -1;
    var bestD = double.infinity;
    for (var i = 0; i < shape.length; i++) {
      final dLat = shape[i].latitude - p.latitude;
      final dLng = shape[i].longitude - p.longitude;
      final d = dLat * dLat + dLng * dLng;
      if (d < bestD) {
        bestD = d;
        best = i;
      }
    }
    return best;
  }

  static List<LatLng> _segment(
    TransitLine line,
    TransitStation a,
    TransitStation b,
    int ia,
    int ib,
  ) {
    if (ia < 0 || ib < 0 || (ia - ib).abs() < 1) {
      return [a.position, b.position];
    }
    final slice = ia < ib
        ? line.shape.sublist(ia, ib + 1)
        : line.shape.sublist(ib, ia + 1).reversed.toList();
    // Guard against shapes whose ordering does not follow the stations.
    final direct = MultimodalTripPlanner.meters(a.position, b.position);
    if (_pathLength(slice) > direct * 3 + 500) {
      return [a.position, b.position];
    }
    return [a.position, ...slice, b.position];
  }

  static double _pathLength(List<LatLng> path) {
    var total = 0.0;
    for (var i = 0; i + 1 < path.length; i++) {
      total += MultimodalTripPlanner.meters(path[i], path[i + 1]);
    }
    return total;
  }
}

/// Extra node created for one query: a point on a bus route's street.
class _RoadsideNode {
  final LatLng position;
  final TransitLine line;

  const _RoadsideNode(this.position, this.line);
}

class _Query {
  final _Graph graph;
  final LatLng origin;
  final LatLng destination;
  final String originName;
  final String destinationName;

  late final int originIdx = graph.nodes.length;
  late final int destinationIdx = graph.nodes.length + 1;

  /// Query-only nodes (after origin and destination) and outgoing edges
  /// added on top of the shared graph.
  final List<_RoadsideNode> _roadside = [];
  final Map<int, List<_Edge>> _extra = {};

  _Query({
    required this.graph,
    required this.origin,
    required this.destination,
    required this.originName,
    required this.destinationName,
  }) {
    for (final e in _access(origin)) {
      _add(
        originIdx,
        _walkEdge(e.key, origin, graph.nodes[e.key].station.position, e.value),
      );
    }
    for (final e in _access(destination)) {
      _add(
        e.key,
        _walkEdge(
          destinationIdx,
          graph.nodes[e.key].station.position,
          destination,
          e.value,
        ),
      );
    }
    final direct = MultimodalTripPlanner.meters(origin, destination);
    if (direct <= MultimodalTripPlanner.directWalkMaxMeters) {
      _add(originIdx, _walkEdge(destinationIdx, origin, destination, direct));
    }
    _addRoadsideAccess();
  }

  int get _nodeCount => graph.nodes.length + 2 + _roadside.length;

  void _add(int from, _Edge edge) => (_extra[from] ??= []).add(edge);

  int _newRoadsideNode(LatLng position, TransitLine line) {
    _roadside.add(_RoadsideNode(position, line));
    return _nodeCount - 1;
  }

  _RoadsideNode? _roadsideOf(int node) {
    final i = node - graph.nodes.length - 2;
    return i >= 0 && i < _roadside.length ? _roadside[i] : null;
  }

  /// Lets the trip start or end on the street of any bus route that passes
  /// near the origin / destination, not only at its listed stops.
  void _addRoadsideAccess() {
    const nearStop = 60.0;
    for (final geo in graph.roadsideLines) {
      final (so, qo, dOrigin) = geo.project(origin);
      final (sd, qd, dDestination) = geo.project(destination);
      final boardHere =
          dOrigin <= MultimodalTripPlanner.roadsideRadiusMeters &&
          geo.stopAt.every((s) => (s - so).abs() > nearStop);
      final alightHere =
          dDestination <= MultimodalTripPlanner.roadsideRadiusMeters &&
          geo.stopAt.every((s) => (s - sd).abs() > nearStop);

      int? onBoardAtOrigin;
      if (boardHere) {
        final street = _newRoadsideNode(qo, geo.line);
        onBoardAtOrigin = _newRoadsideNode(qo, geo.line);
        _add(originIdx, _walkEdge(street, origin, qo, dOrigin));
        _add(
          street,
          _Edge(
            to: onBoardAtOrigin,
            kind: _EdgeKind.board,
            line: geo.line,
            meters: 0,
            minutes: geo.line.headwayMin / 2,
          ),
        );
        // Ride to the neighbouring listed stops in both directions.
        final (before, after) = _neighbourStops(geo, so);
        if (before != null) {
          _add(
            onBoardAtOrigin,
            geo.ride(geo.rideNodes[before], so, geo.stopAt[before]),
          );
        }
        if (after != null) {
          _add(
            onBoardAtOrigin,
            geo.ride(geo.rideNodes[after], so, geo.stopAt[after]),
          );
        }
      }

      if (alightHere) {
        final onBoard = _newRoadsideNode(qd, geo.line);
        final street = _newRoadsideNode(qd, geo.line);
        final (before, after) = _neighbourStops(geo, sd);
        if (before != null) {
          _add(
            geo.rideNodes[before],
            geo.ride(onBoard, geo.stopAt[before], sd),
          );
        }
        if (after != null) {
          _add(geo.rideNodes[after], geo.ride(onBoard, geo.stopAt[after], sd));
        }
        if (onBoardAtOrigin != null && (sd - so).abs() > nearStop) {
          // Same bus passes near both ends: one ride, no transfer.
          _add(onBoardAtOrigin, geo.ride(onBoard, so, sd));
        }
        _add(
          onBoard,
          _Edge(
            to: street,
            kind: _EdgeKind.alight,
            meters: 0,
            minutes: MultimodalTripPlanner.alightMin,
          ),
        );
        _add(street, _walkEdge(destinationIdx, qd, destination, dDestination));
      }
    }
  }

  /// Indexes of the listed stops right before and after position [s].
  static (int?, int?) _neighbourStops(_LineGeometry geo, double s) {
    int? before;
    int? after;
    for (var i = 0; i < geo.stopAt.length; i++) {
      if (geo.stopAt[i] <= s) before = i;
      if (geo.stopAt[i] > s) {
        after = i;
        break;
      }
    }
    return (before, after);
  }

  /// Street nodes reachable on foot: everything inside the access radius,
  /// and at least the three closest stations so remote addresses still route.
  List<MapEntry<int, double>> _access(LatLng point) {
    final all = [
      for (final entry in graph.streetNode.entries)
        MapEntry(
          entry.value,
          MultimodalTripPlanner.meters(
            point,
            graph.network.stations[entry.key]!.position,
          ),
        ),
    ]..sort((a, b) => a.value.compareTo(b.value));
    return [
      for (var i = 0; i < all.length; i++)
        if (i < 3 || all[i].value <= MultimodalTripPlanner.accessRadiusMeters)
          all[i],
    ];
  }

  _Edge _walkEdge(int to, LatLng from, LatLng target, double straight) {
    final walked = straight * MultimodalTripPlanner.walkDetour;
    return _Edge(
      to: to,
      kind: _EdgeKind.walk,
      meters: walked,
      minutes: walked / MultimodalTripPlanner.walkMetersPerMin,
      path: [from, target],
    );
  }

  double _cost(_Edge edge, _Weights w) {
    switch (edge.kind) {
      case _EdgeKind.walk:
        return edge.minutes * w.walkFactor;
      case _EdgeKind.board:
        final line = edge.line!;
        // Approximate feeder data (guessed headway, geocoded stops) should
        // only win when it is clearly better than official lines.
        final approximate = line.approximate ? 5 : 0;
        if (w.trunkOnly && line.stopsOnRequest) {
          return double.infinity;
        }
        return edge.minutes +
            w.boardPenalty +
            approximate +
            (w.linePenalty[MultimodalTripPlanner.routeKey(line)] ?? 0);
      case _EdgeKind.ride:
      case _EdgeKind.alight:
        return edge.minutes;
    }
  }

  Iterable<_Edge> _neighbors(int node) sync* {
    if (node < graph.nodes.length) yield* graph.adjacency[node];
    final extra = _extra[node];
    if (extra != null) yield* extra;
  }

  Itinerary? run(_Weights weights) {
    final total = _nodeCount;
    final dist = List<double>.filled(total, double.infinity);
    final prevEdge = List<_Edge?>.filled(total, null);
    final prevNode = List<int>.filled(total, -1);
    final heap = _MinHeap()..insert(originIdx, 0);
    dist[originIdx] = 0;

    while (heap.isNotEmpty) {
      final (node, d) = heap.removeMin();
      if (d > dist[node]) continue;
      if (node == destinationIdx) break;
      for (final edge in _neighbors(node)) {
        final candidate = d + _cost(edge, weights);
        if (candidate < dist[edge.to]) {
          dist[edge.to] = candidate;
          prevEdge[edge.to] = edge;
          prevNode[edge.to] = node;
          heap.insert(edge.to, candidate);
        }
      }
    }
    if (dist[destinationIdx] == double.infinity) return null;

    final edges = <_Edge>[];
    final from = <int>[];
    for (var n = destinationIdx; n != originIdx; n = prevNode[n]) {
      edges.add(prevEdge[n]!);
      from.add(prevNode[n]);
    }
    return _toItinerary(edges.reversed.toList(), from.reversed.toList());
  }

  String _nameOf(int node) {
    if (node == originIdx) return originName;
    if (node == destinationIdx) return destinationName;
    if (_roadsideOf(node) != null) return '';
    return graph.nodes[node].station.name;
  }

  TransitStation? _stationOf(int node) =>
      node < graph.nodes.length ? graph.nodes[node].station : null;

  Itinerary _toItinerary(List<_Edge> edges, List<int> fromNodes) {
    final legs = <ItineraryLeg>[];
    var i = 0;
    while (i < edges.length) {
      final edge = edges[i];
      if (edge.kind == _EdgeKind.walk) {
        final start = fromNodes[i];
        final path = <LatLng>[];
        var meters = 0.0;
        var minutes = 0.0;
        while (i < edges.length && edges[i].kind == _EdgeKind.walk) {
          path.addAll(edges[i].path);
          meters += edges[i].meters;
          minutes += edges[i].minutes;
          i++;
        }
        final end = i < edges.length ? fromNodes[i] : destinationIdx;
        // Skip zero-length hops (e.g. origin exactly on a station).
        if (meters < 15) continue;
        legs.add(
          ItineraryLeg(
            mode: TransitMode.walk,
            fromName: _nameOf(start),
            toName: _nameOf(end),
            path: path,
            distanceMeters: meters,
            durationMin: minutes,
            walkToLine: _roadsideOf(end)?.line,
          ),
        );
      } else if (edge.kind == _EdgeKind.board) {
        final line = edge.line!;
        final wait = edge.minutes;
        final boardsRoadside = _roadsideOf(edge.to) != null;
        final stops = <TransitStation>[?_stationOf(edge.to)];
        final path = <LatLng>[];
        var meters = 0.0;
        var minutes = 0.0;
        bool? forward;
        i++;
        while (i < edges.length && edges[i].kind == _EdgeKind.ride) {
          forward ??= edges[i].forward;
          final station = _stationOf(edges[i].to);
          if (station != null) stops.add(station);
          path.addAll(edges[i].path);
          meters += edges[i].meters;
          minutes += edges[i].minutes;
          i++;
        }
        var alightsRoadside = false;
        if (i < edges.length && edges[i].kind == _EdgeKind.alight) {
          alightsRoadside = _roadsideOf(edges[i].to) != null;
          minutes += edges[i].minutes;
          i++;
        }
        final terminalId = (forward ?? true)
            ? line.stationIds.last
            : line.stationIds.first;
        legs.add(
          ItineraryLeg(
            mode: line.mode,
            line: line,
            fromName: boardsRoadside
                ? originName
                : (stops.isEmpty ? '' : stops.first.name),
            toName: alightsRoadside
                ? destinationName
                : (stops.isEmpty ? '' : stops.last.name),
            stops: stops,
            path: path,
            distanceMeters: meters,
            durationMin: minutes,
            waitMin: wait,
            headsign: graph.network.stations[terminalId]?.name,
            boardsRoadside: boardsRoadside,
            alightsRoadside: alightsRoadside,
          ),
        );
      } else {
        i++;
      }
    }
    return Itinerary(legs: legs);
  }
}

class _MinHeap {
  final List<(int, double)> _data = [];

  bool get isNotEmpty => _data.isNotEmpty;

  void insert(int node, double priority) {
    _data.add((node, priority));
    var i = _data.length - 1;
    while (i > 0) {
      final parent = (i - 1) >> 1;
      if (_data[i].$2 >= _data[parent].$2) break;
      final tmp = _data[i];
      _data[i] = _data[parent];
      _data[parent] = tmp;
      i = parent;
    }
  }

  (int, double) removeMin() {
    final min = _data.first;
    final last = _data.removeLast();
    if (_data.isNotEmpty) {
      _data[0] = last;
      var i = 0;
      while (true) {
        final l = 2 * i + 1;
        final r = l + 1;
        var s = i;
        if (l < _data.length && _data[l].$2 < _data[s].$2) s = l;
        if (r < _data.length && _data[r].$2 < _data[s].$2) s = r;
        if (s == i) break;
        final tmp = _data[i];
        _data[i] = _data[s];
        _data[s] = tmp;
        i = s;
      }
    }
    return min;
  }
}
