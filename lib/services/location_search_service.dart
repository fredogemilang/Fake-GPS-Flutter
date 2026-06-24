import 'dart:convert';
import 'package:http/http.dart' as http;

class LocationSearchService {
  final String apiKey;

  const LocationSearchService({required this.apiKey});

  /// Cari tempat berdasarkan query teks.
  /// Mengembalikan list of {name, address, lat, lng}.
  Future<List<Map<String, dynamic>>> searchPlaces(String query) async {
    final url = Uri.https(
      'maps.googleapis.com',
      '/maps/api/place/textsearch/json',
      {
        'query': query,
        'key': apiKey,
        'language': 'id',
      },
    );

    final response = await http.get(url);
    if (response.statusCode != 200) return [];

    final data = jsonDecode(response.body);
    if (data['status'] != 'OK') return [];

    final results = data['results'] as List;
    return results.map((r) => {
      'name': r['name'] as String,
      'address': r['formatted_address'] as String? ?? '',
      'lat': (r['geometry']['location']['lat'] as num).toDouble(),
      'lng': (r['geometry']['location']['lng'] as num).toDouble(),
    }).toList();
  }

  /// Reverse geocoding: koordinat → alamat.
  static Future<String> getAddressFromCoordinates(
    double lat,
    double lng, {
    String apiKey = '',
  }) async {
    final url = Uri.https(
      'maps.googleapis.com',
      '/maps/api/geocode/json',
      {
        'latlng': '$lat,$lng',
        'key': apiKey,
        'language': 'id',
      },
    );

    final response = await http.get(url);
    if (response.statusCode != 200) return '$lat, $lng';

    final data = jsonDecode(response.body);
    if (data['status'] != 'OK') return '$lat, $lng';

    final results = data['results'] as List;
    if (results.isEmpty) return '$lat, $lng';

    return results[0]['formatted_address'] as String? ?? '$lat, $lng';
  }
}
