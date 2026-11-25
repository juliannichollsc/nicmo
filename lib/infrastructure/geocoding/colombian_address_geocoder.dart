import 'dart:math' as math;

import 'package:latlong2/latlong.dart';
import 'package:nicmo/domain/transit/transit_services.dart';
import 'package:nicmo/infrastructure/geocoding/colombian_address.dart';
import 'package:nicmo/infrastructure/geocoding/nominatim_client.dart';
import 'package:nicmo/infrastructure/geocoding/search_area.dart';

/// Locates Colombian addresses ("Calle X # Y - Z") on OpenStreetMap data.
///
/// 1. Fetches the geometry of the primary street ("Diagonal 54") and keeps
///    the stretches that match the barrio / municipality hints.
/// 2. Fetches the crossing street ("Carrera 17") only around those
///    stretches, so busy names are not cut by Nominatim's result limit.
/// 3. Computes where both lines meet: that corner is the address (the
///    "- 100" metres are within one block of it).
/// 4. When the map has no crossing street, falls back to the primary street
///    in the hinted barrio and flags the result as approximate.
class ColombianAddressGeocoder {
  /// Two carriageways or a slightly offset junction still count as the
  /// corner; it is less than a block and similar to the "- 70" metres.
  static const double _cornerToleranceMeters = 100;
  static const int _pageSize = 40;
  static const double _duplicateMeters = 80;
  static const double _approximateMeters = 700;

  final NominatimClient nominatim;

  ColombianAddressGeocoder(this.nominatim);

  Future<List<Place>> geocode(
    ColombianAddress address, {
    String languageCode = 'es',
    LatLng? near,
    bool Function()? cancelled,
  }) async {
    var (primary, _) = await _streets(
      address.primaryName,
      languageCode,
      cancelled: cancelled,
    );
    if (primary.isEmpty) return const [];

    // Keep only stretches in the barrio / municipality the user wrote.
    final best = primary.map((s) => s.score(address.hints)).reduce(math.max);
    if (best > 0) {
      primary = primary.where((s) => s.score(address.hints) == best).toList();
    }

    final origin = near ?? SearchArea.current.center;
    final corners = <_Candidate>[];
    var nearest = <_Candidate>[];
    var nearestDistance = double.infinity;

    void collect(List<_Street> primaryStreets, List<_Street> cross) {
      for (final p in primaryStreets) {
        for (final c in cross) {
          final (distance, point) = _closestApproach(p.points, c.points);
          if (distance <= _cornerToleranceMeters) {
            corners.add(_Candidate(p, point, false));
          } else if (distance < nearestDistance) {
            nearestDistance = distance;
            nearest = [_Candidate(p, point, true)];
          }
        }
      }
    }

    // 1. Crossing street around the whole primary street (one request).
    final crossNames = address.crossNames;
    final (crossAround, truncated) = await _streets(
      crossNames.first,
      languageCode,
      viewBox: _viewBoxAround(primary),
      cancelled: cancelled,
    );
    collect(primary, crossAround);

    // 2. Long streets are split in many short ways and Nominatim returns at
    //    most 40, so the corner may be missing. Ask again inside each of the
    //    closest barrios ("Carrera 43A, Manila"), where few ways match.
    if (corners.isEmpty && truncated) {
      // Barrios where the primary street passes closest to the crossing
      // street go first (or closest to the user when nothing is known).
      double rank(List<_Street> streets) {
        if (crossAround.isEmpty) {
          return _meters(_middle(streets.first.points), origin);
        }
        var best = double.infinity;
        for (final p in streets) {
          for (final c in crossAround) {
            best = math.min(best, _closestApproach(p.points, c.points).$1);
          }
        }
        return best;
      }

      final areas = _groupByArea(primary).entries.toList()
        ..sort((a, b) => rank(a.value).compareTo(rank(b.value)));
      for (final area in areas.take(2)) {
        final barrio = area.key.split(',').first;
        if (barrio.isEmpty) continue;
        final (cross, _) = await _streets(
          '${crossNames.first}, $barrio',
          languageCode,
          cancelled: cancelled,
        );
        collect(area.value, cross);
        if (corners.isNotEmpty) break;
      }
    }

    // 3. The crossing street is not in the map: estimate its position from
    //    the neighbouring numbered streets (16 and 18 for a 17).
    if (corners.isEmpty) {
      final estimate = await _interpolate(
        address,
        primary,
        languageCode,
        cancelled,
      );
      if (estimate != null) corners.add(estimate);
    }

    // 4. No corner in the map data: the point of the primary street closest
    //    to the crossing street, or one point per barrio as a last resort.
    final candidates = corners.isNotEmpty
        ? corners
        : nearestDistance <= _approximateMeters
        ? nearest
        : [
            for (final group in _groupByArea(primary).values)
              _Candidate(group.first, _middle(group.first.points), true),
          ];

    final unique = <_Candidate>[];
    for (final c in candidates) {
      if (unique.every((u) => _meters(u.point, c.point) > _duplicateMeters)) {
        unique.add(c);
      }
    }
    unique.sort((a, b) {
      final byHint =
          b.street.score(address.hints) - a.street.score(address.hints);
      if (byHint != 0) return byHint;
      return _meters(a.point, origin).compareTo(_meters(b.point, origin));
    });

    return [
      for (final c in unique.take(5))
        Place(
          name: address.label,
          subtitle: c.street.area,
          position: c.point,
          approximate: c.approximate,
        ),
    ];
  }

  /// Estimates where the crossing number falls on the primary street from
  /// mapped neighbours: between two of them it interpolates by number; with
  /// a single neighbour it uses that corner, flagged approximate.
  Future<_Candidate?> _interpolate(
    ColombianAddress address,
    List<_Street> primary,
    String languageCode,
    bool Function()? cancelled,
  ) async {
    final match = RegExp(r'^(\d+)([A-Z]?)').firstMatch(address.crossNumber);
    if (match == null) return null;
    final base = int.parse(match.group(1)!);
    final letter = match.group(2)!;
    final target =
        base + (letter.isEmpty ? 0 : (letter.codeUnitAt(0) - 64) * 0.25);
    final type = address.crossNames.first.split(' ').first;
    final sur = address.crossSur ? ' Sur' : '';
    final viewBox = _viewBoxAround(primary);

    (double, _Street, LatLng)? below;
    (double, _Street, LatLng)? above;
    var requests = 0;
    for (final delta in const [-1, 1, -2, 2]) {
      final number = base + delta;
      if (number <= 0 ||
          (delta < 0 && below != null) ||
          (delta > 0 && above != null)) {
        continue;
      }
      if (requests++ >= 4) break;
      final (cross, _) = await _streets(
        '$type $number$sur',
        languageCode,
        viewBox: viewBox,
        cancelled: cancelled,
      );
      for (final p in primary) {
        for (final c in cross) {
          final (distance, point) = _closestApproach(p.points, c.points);
          if (distance > _cornerToleranceMeters) continue;
          final anchor = (number.toDouble(), p, point);
          if (number < target) {
            below ??= anchor;
          } else {
            above ??= anchor;
          }
        }
      }
      if (below != null && above != null) break;
      // Neither direct neighbour is mapped here: the numbering is absent in
      // this area, so further requests would only add waiting time.
      if (delta == 1 && below == null && above == null) break;
    }

    if (below != null && above != null) {
      final (n1, street, p1) = below;
      final (n2, _, p2) = above;
      if (_meters(p1, p2) < 600) {
        final t = (target - n1) / (n2 - n1);
        return _Candidate(
          street,
          LatLng(
            p1.latitude + (p2.latitude - p1.latitude) * t,
            p1.longitude + (p2.longitude - p1.longitude) * t,
          ),
          false,
        );
      }
    }
    final single = below ?? above;
    return single == null ? null : _Candidate(single.$2, single.$3, true);
  }

  /// Street stretches named [name]; the flag tells whether Nominatim's page
  /// limit was reached (some stretches may be missing).
  Future<(List<_Street>, bool)> _streets(
    String name,
    String languageCode, {
    String? viewBox,
    bool Function()? cancelled,
  }) async {
    final results = await nominatim.search(
      name,
      languageCode: languageCode,
      limit: _pageSize,
      geometry: true,
      viewBox: viewBox,
      cancelled: cancelled,
    );
    final wanted = ColombianAddress.normalize(name);
    final streets = <_Street>[];
    for (final r in results) {
      if (ColombianAddress.normalize(r['name'] as String? ?? '') != wanted) {
        continue;
      }
      final geo = r['geojson'] as Map<String, dynamic>?;
      final lines = switch (geo?['type']) {
        'LineString' => [geo!['coordinates'] as List],
        'MultiLineString' => (geo!['coordinates'] as List).cast<List>(),
        _ => const <List>[],
      };
      for (final line in lines) {
        final points = [
          for (final c in line)
            LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()),
        ];
        if (points.length >= 2) {
          streets.add(_Street(r['display_name'] as String, points));
        }
      }
    }
    return (streets, results.length >= _pageSize);
  }

  static String _viewBoxAround(List<_Street> streets) {
    const margin = 0.012; // ~1.3 km
    var minLat = 90.0, maxLat = -90.0, minLng = 180.0, maxLng = -180.0;
    for (final s in streets) {
      for (final p in s.points) {
        minLat = math.min(minLat, p.latitude);
        maxLat = math.max(maxLat, p.latitude);
        minLng = math.min(minLng, p.longitude);
        maxLng = math.max(maxLng, p.longitude);
      }
    }
    return '${minLng - margin},${maxLat + margin},'
        '${maxLng + margin},${minLat - margin}';
  }

  static Map<String, List<_Street>> _groupByArea(List<_Street> streets) {
    final groups = <String, List<_Street>>{};
    for (final s in streets) {
      groups.putIfAbsent(s.area, () => []).add(s);
    }
    return groups;
  }

  static LatLng _middle(List<LatLng> points) => points[points.length ~/ 2];

  static double _meters(LatLng a, LatLng b) =>
      const Distance().as(LengthUnit.Meter, a, b);

  /// Smallest distance between two polylines and the point where it occurs
  /// (distance 0 when they cross).
  static (double, LatLng) _closestApproach(List<LatLng> a, List<LatLng> b) {
    final ref = a.first;
    final cosLat = math.cos(ref.latitude * math.pi / 180);
    math.Point<double> project(LatLng p) => math.Point(
      (p.longitude - ref.longitude) * 111320 * cosLat,
      (p.latitude - ref.latitude) * 111320,
    );
    LatLng unproject(math.Point<double> p) => LatLng(
      ref.latitude + p.y / 111320,
      ref.longitude + p.x / (111320 * cosLat),
    );

    final pa = a.map(project).toList();
    final pb = b.map(project).toList();
    var bestDistance = double.infinity;
    var bestPoint = pa.first;
    for (var i = 0; i + 1 < pa.length; i++) {
      for (var j = 0; j + 1 < pb.length; j++) {
        final (d, p) = _segmentDistance(pa[i], pa[i + 1], pb[j], pb[j + 1]);
        if (d < bestDistance) {
          bestDistance = d;
          bestPoint = p;
        }
      }
    }
    return (bestDistance, unproject(bestPoint));
  }

  /// Distance between segments p1p2 and q1q2 and the midpoint of the gap.
  static (double, math.Point<double>) _segmentDistance(
    math.Point<double> p1,
    math.Point<double> p2,
    math.Point<double> q1,
    math.Point<double> q2,
  ) {
    final r = p2 - p1;
    final s = q2 - q1;
    final denominator = r.x * s.y - r.y * s.x;
    if (denominator.abs() > 1e-9) {
      final t = ((q1.x - p1.x) * s.y - (q1.y - p1.y) * s.x) / denominator;
      final u = ((q1.x - p1.x) * r.y - (q1.y - p1.y) * r.x) / denominator;
      if (t >= 0 && t <= 1 && u >= 0 && u <= 1) {
        return (0, math.Point(p1.x + r.x * t, p1.y + r.y * t));
      }
    }
    var best = (double.infinity, p1);
    for (final (point, start, end) in [
      (p1, q1, q2),
      (p2, q1, q2),
      (q1, p1, p2),
      (q2, p1, p2),
    ]) {
      final closest = _closestOnSegment(point, start, end);
      final d = point.distanceTo(closest);
      if (d < best.$1) {
        best = (
          d,
          math.Point((point.x + closest.x) / 2, (point.y + closest.y) / 2),
        );
      }
    }
    return best;
  }

  static math.Point<double> _closestOnSegment(
    math.Point<double> p,
    math.Point<double> a,
    math.Point<double> b,
  ) {
    final ab = b - a;
    final lengthSquared = ab.x * ab.x + ab.y * ab.y;
    if (lengthSquared == 0) return a;
    final t = (((p.x - a.x) * ab.x + (p.y - a.y) * ab.y) / lengthSquared).clamp(
      0.0,
      1.0,
    );
    return math.Point(a.x + ab.x * t, a.y + ab.y * t);
  }
}

class _Street {
  final String displayName;
  final List<LatLng> points;
  late final String area = _area(displayName);
  late final String _normalized = ColombianAddress.normalize(displayName);

  _Street(this.displayName, this.points);

  int score(List<String> hints) =>
      hints.where((h) => _normalized.contains(h)).length;

  /// "Diagonal 54, Niquía, Bello, Valle de Aburrá, …" → "Niquía, Bello".
  static String _area(String displayName) {
    final parts = displayName.split(',').map((p) => p.trim()).toList();
    final barrio = parts.length > 1 ? parts[1] : '';
    final municipality = parts.firstWhere(
      SearchArea.current.municipalities.contains,
      orElse: () => '',
    );
    return [barrio, municipality].where((p) => p.isNotEmpty).toSet().join(', ');
  }
}

class _Candidate {
  final _Street street;
  final LatLng point;
  final bool approximate;

  const _Candidate(this.street, this.point, this.approximate);
}
