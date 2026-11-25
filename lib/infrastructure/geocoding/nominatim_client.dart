import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:nicmo/infrastructure/geocoding/search_area.dart';

/// Thin client for the free OpenStreetMap Nominatim API.
///
/// Nominatim's usage policy allows at most one request per second, so every
/// call goes through a shared queue, and identical queries are cached.
class NominatimClient {
  static const _userAgent =
      'Nicmo/1.0 (public transport trip planner, Colombia)';
  static const _minInterval = Duration(milliseconds: 1050);

  final http.Client client;
  final Map<String, Object> _cache = {};
  Future<void> _queue = Future.value();
  DateTime _last = DateTime.fromMillisecondsSinceEpoch(0);

  NominatimClient({http.Client? client}) : client = client ?? http.Client();

  Future<List<Map<String, dynamic>>> search(
    String query, {
    String languageCode = 'es',
    int limit = 6,
    bool geometry = false,
    String? viewBox,
    bool Function()? cancelled,
  }) {
    final params = {
      'q': query,
      'format': 'jsonv2',
      'limit': '$limit',
      'countrycodes': 'co',
      // The city in use unless a narrower box is given.
      'viewbox': viewBox ?? SearchArea.current.viewBox,
      'bounded': '1',
      'accept-language': languageCode,
      if (geometry) ...{'polygon_geojson': '1', 'dedupe': '0'},
    };
    final uri = Uri.https('nominatim.openstreetmap.org', '/search', params);
    return _enqueue(uri, cancelled).then(
      (value) => value == null
          ? const <Map<String, dynamic>>[]
          : (value as List).cast<Map<String, dynamic>>(),
    );
  }

  /// Address of the map feature at a point (street, barrio, municipality).
  Future<Map<String, dynamic>?> reverse(
    double lat,
    double lon, {
    String languageCode = 'es',
  }) {
    final uri = Uri.https('nominatim.openstreetmap.org', '/reverse', {
      'lat': lat.toStringAsFixed(6),
      'lon': lon.toStringAsFixed(6),
      'format': 'jsonv2',
      'zoom': '18',
      'accept-language': languageCode,
    });
    return _enqueue(uri, null).then((value) => value as Map<String, dynamic>?);
  }

  Future<Object?> _enqueue(Uri uri, bool Function()? cancelled) {
    final key = uri.toString();
    final cached = _cache[key];
    if (cached != null) return Future.value(cached);

    // A superseded search is dropped when its turn comes, so stale requests
    // never delay the latest one.
    final result = _queue.then(
      (_) => cancelled?.call() == true ? null : _throttled(uri),
    );
    _queue = result.then((_) {}, onError: (_) {});
    return result.then((value) {
      if (value != null) _cache[key] = value;
      return value;
    });
  }

  Future<Object?> _throttled(Uri uri) async {
    final wait = _minInterval - DateTime.now().difference(_last);
    if (!wait.isNegative) await Future<void>.delayed(wait);
    _last = DateTime.now();
    try {
      final response = await client
          .get(uri, headers: {'User-Agent': _userAgent})
          .timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) return null;
      return jsonDecode(utf8.decode(response.bodyBytes));
    } catch (_) {
      // Offline or rate limited; callers treat it as "no results".
      return null;
    }
  }
}
