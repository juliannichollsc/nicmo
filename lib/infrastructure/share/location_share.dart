import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:latlong2/latlong.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// Shares where the rider is during a trip: a Google Maps link to the
/// position, which opens the Google Maps app (or the browser) with a pin.
class LocationShare {
  /// Google Maps "search" URL with a pin on [point] (official Maps URLs,
  /// developers.google.com/maps/documentation/urls).
  static Uri mapsLink(
    LatLng point,
  ) => Uri.https('www.google.com', '/maps/search/', {
    'api': '1',
    'query':
        '${point.latitude.toStringAsFixed(6)},${point.longitude.toStringAsFixed(6)}',
  });

  /// Opens WhatsApp with [text] ready to send (the contact is chosen in
  /// WhatsApp). Falls back to wa.me, which opens WhatsApp or its web page.
  static Future<bool> whatsApp(String text) async {
    if (!kIsWeb) {
      final app = Uri.parse(
        'whatsapp://send?text=${Uri.encodeComponent(text)}',
      );
      try {
        if (await launchUrl(app, mode: LaunchMode.externalApplication)) {
          return true;
        }
      } catch (_) {
        // Not installed: try the web link below.
      }
    }
    try {
      return await launchUrl(
        Uri.https('wa.me', '/', {'text': text}),
        mode: LaunchMode.externalApplication,
      );
    } catch (_) {
      return false;
    }
  }

  /// System share sheet (any app: Telegram, SMS, email...).
  static Future<void> other(String text, {Rect? origin}) async {
    await SharePlus.instance.share(
      ShareParams(text: text, sharePositionOrigin: origin),
    );
  }
}
