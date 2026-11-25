import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:nicmo/infrastructure/geocoding/nominatim_client.dart';

void main() {
  test('a superseded search is never sent', () async {
    final sent = <String>[];
    final client = NominatimClient(
      client: MockClient((request) async {
        sent.add(request.url.queryParameters['q']!);
        return http.Response('[]', 200);
      }),
    );
    var latest = 0;
    final first = ++latest;
    final stale = client.search(
      'Cra. 43B # 1',
      cancelled: () => first != latest,
    );
    final second = ++latest;
    final fresh = client.search(
      'Cra. 43B # 1A Sur',
      cancelled: () => second != latest,
    );

    await Future.wait([stale, fresh]);
    expect(sent, ['Cra. 43B # 1A Sur']);
  });

  test('identical queries are answered from the cache', () async {
    var calls = 0;
    final client = NominatimClient(
      client: MockClient((request) async {
        calls++;
        return http.Response('[]', 200);
      }),
    );
    await client.search('Poblado');
    await client.search('Poblado');
    expect(calls, 1);
  });
}
