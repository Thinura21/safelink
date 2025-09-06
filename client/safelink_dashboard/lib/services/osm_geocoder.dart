import 'dart:convert';
import 'package:http/http.dart' as http;

class OsmSuggestion {
  final String display;
  final double lat;
  final double lon;
  OsmSuggestion({required this.display, required this.lat, required this.lon});
}

class OsmGeocoder {
  static const _ua = 'safelink_dashboard/1.0 (+https://example.com; contact: admin@example.com)';

  static Future<List<OsmSuggestion>> query(String q) async {
    final qq = q.trim();
    if (qq.isEmpty) return [];
    final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
      'format': 'jsonv2',
      'q': qq,
      'limit': '8',
      'addressdetails': '1',
    });
    final res = await http.get(uri, headers: {'User-Agent': _ua});
    if (res.statusCode != 200) return [];
    final data = (jsonDecode(res.body) as List).cast<Map<String, dynamic>>();
    return data
        .map((m) => OsmSuggestion(
              display: (m['display_name'] ?? '').toString(),
              lat: double.tryParse((m['lat'] ?? '0').toString()) ?? 0,
              lon: double.tryParse((m['lon'] ?? '0').toString()) ?? 0,
            ))
        .where((s) => s.lat != 0 && s.lon != 0)
        .toList();
  }

  static Future<String> reverse(double lat, double lon) async {
    final uri = Uri.https('nominatim.openstreetmap.org', '/reverse', {
      'format': 'jsonv2',
      'lat': '$lat',
      'lon': '$lon',
    });
    final res = await http.get(uri, headers: {'User-Agent': _ua});
    if (res.statusCode != 200) return '';
    final j = (jsonDecode(res.body) as Map<String, dynamic>);
    return (j['display_name'] ?? '').toString();
  }
}
