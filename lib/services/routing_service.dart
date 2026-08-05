import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../models/route_result.dart';

/// Calcolo del percorso su strada tramite OSRM (OpenStreetMap Routing Machine).
///
/// Usa il server pubblico di demo: va bene per sviluppo e test, ma non è
/// pensato per il traffico di un'app in produzione. In M4 useremo un motore
/// di routing (OSRM/Valhalla) sul server personale: cambierà solo [_host].
class RoutingService {
  static const String _host = 'router.project-osrm.org';

  /// Calcola il percorso in auto da [da] a [a].
  Future<RouteResult> route(LatLng da, LatLng a) async {
    final coords =
        '${da.longitude},${da.latitude};${a.longitude},${a.latitude}';
    final uri = Uri.https(_host, '/route/v1/driving/$coords', {
      'overview': 'full',
      'geometries': 'geojson',
    });

    final res = await http.get(uri);
    if (res.statusCode != 200) {
      throw Exception('Calcolo percorso non riuscito (codice ${res.statusCode})');
    }

    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final routes = data['routes'];
    if (data['code'] != 'Ok' || routes is! List || routes.isEmpty) {
      throw Exception('Nessun percorso trovato per questa destinazione');
    }

    final r = routes.first as Map<String, dynamic>;
    final coordinate = (r['geometry']['coordinates'] as List)
        // GeoJSON usa [longitudine, latitudine]: qui invertiamo.
        .map((c) => LatLng(
              (c[1] as num).toDouble(),
              (c[0] as num).toDouble(),
            ))
        .toList();

    return RouteResult(
      polyline: coordinate,
      metri: (r['distance'] as num).toDouble(),
      secondi: (r['duration'] as num).toDouble(),
    );
  }
}
