import 'dart:convert';
import 'package:http/http.dart' as http;


class OverpassService {
  /// radius in meters
  static Future<List<Map<String, dynamic>>> fetchPOIs(
      double lat, double lon, {int radius = 3000}) async {
    final query = '''
    [out:json][timeout:25];
    (
      node["amenity"="hospital"](around:$radius,$lat,$lon);
      node["amenity"="clinic"](around:$radius,$lat,$lon);
      node["amenity"="pharmacy"](around:$radius,$lat,$lon);
      node["amenity"="police"](around:$radius,$lat,$lon);
      node["emergency"="fire_station"](around:$radius,$lat,$lon);
    );
    out center;
    ''';

    final url = Uri.parse(
      'https://overpass-api.de/api/interpreter?data=${Uri.encodeComponent(query)}',
    );

    final res = await http.get(url);
    if (res.statusCode != 200) {
      throw Exception('Overpass API error: ${res.statusCode}');
    }

    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final elements = (body['elements'] as List).cast<dynamic>();

    final List<Map<String, dynamic>> pois = [];
    for (var e in elements) {
      double? plat = (e['lat'] is num) ? (e['lat'] as num).toDouble() : null;
      double? plon = (e['lon'] is num) ? (e['lon'] as num).toDouble() : null;

      if (plat == null || plon == null) {
        final center = e['center'] as Map<String, dynamic>?;
        if (center != null) {
          plat = (center['lat'] as num).toDouble();
          plon = (center['lon'] as num).toDouble();
        }
      }

      if (plat == null || plon == null) continue; 

      final tags = e['tags'] as Map<String, dynamic>?;
      final name = tags != null ? (tags['name'] as String?) : null;
      String type = 'unknown';
      if (tags != null) {
        if (tags.containsKey('amenity')) {
          type = tags['amenity'] as String;
        } else if (tags.containsKey('emergency')) {
          type = tags['emergency'] as String;
        }
      }

      pois.add({
        'name': name,
        'type': type,
        'lat': plat,
        'lon': plon,
      });
    }

    return pois;
  }
}
