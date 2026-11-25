import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:nicmo/il8n/app_localizations_de.dart';
import 'package:nicmo/il8n/app_localizations_en.dart';
import 'package:nicmo/il8n/app_localizations_es.dart';
import 'package:nicmo/il8n/app_localizations_zh.dart';
import 'package:nicmo/infrastructure/share/location_share.dart';

void main() {
  test('Google Maps link puts a pin on the position', () {
    final link = LocationShare.mapsLink(const LatLng(6.2018417, -75.5704));
    expect(link.host, 'www.google.com');
    expect(link.path, '/maps/search/');
    expect(link.queryParameters['api'], '1');
    expect(link.queryParameters['query'], '6.201842,-75.570400');
  });

  test('the message carries destination, time left and the link', () {
    final text = AppLocalizationsEs().shareMessage(
      'Parque Arví',
      23,
      LocationShare.mapsLink(const LatLng(6.25, -75.56)).toString(),
    );
    expect(text, contains('Parque Arví'));
    expect(text, contains('23 min'));
    expect(text, contains('https://www.google.com/maps/search/?api=1'));
  });

  test('the message follows the app language', () {
    const link = 'https://www.google.com/maps/search/?api=1&query=6.25,-75.56';
    expect(
      AppLocalizationsEs().shareMessage('Arví', 5, link),
      startsWith('Voy en camino a Arví'),
    );
    expect(
      AppLocalizationsEn().shareMessage('Arví', 5, link),
      startsWith("I'm on my way to Arví"),
    );
    expect(
      AppLocalizationsDe().shareMessage('Arví', 5, link),
      startsWith('Ich bin mit Nicmo unterwegs nach Arví'),
    );
    expect(
      AppLocalizationsZh().shareMessage('Arví', 5, link),
      startsWith('我正在用 Nicmo 前往 Arví'),
    );
  });
}
