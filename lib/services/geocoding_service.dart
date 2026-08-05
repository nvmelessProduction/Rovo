import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/place.dart';

/// Ricerca di indirizzi e luoghi tramite Nominatim (OpenStreetMap).
///
/// Gratuito e senza chiavi. In futuro (M2) potremo puntare a un'istanza
/// nostra sul server personale: cambierà solo l'URL qui dentro.
class GeocodingService {
  // Nominatim richiede un User-Agent che identifichi l'app.
  static const Map<String, String> _headers = {
    'User-Agent': 'Rova/1.0 (app di navigazione)',
    'Accept-Language': 'it',
  };

  /// Cerca luoghi corrispondenti a [query], con priorità all'Italia.
  Future<List<Place>> search(String query) async {
    final q = query.trim();
    if (q.length < 3) return [];

    final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
      'q': q,
      'format': 'jsonv2',
      'addressdetails': '0',
      'limit': '8',
      'countrycodes': 'it',
    });

    final res = await http.get(uri, headers: _headers);
    if (res.statusCode != 200) {
      throw Exception('Ricerca non riuscita (codice ${res.statusCode})');
    }

    final data = jsonDecode(res.body);
    if (data is! List) return [];
    return data
        .whereType<Map<String, dynamic>>()
        .map(Place.fromNominatim)
        .toList();
  }
}
