import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../models/route_result.dart';
import '../models/route_step.dart';

/// Calcolo del percorso su strada tramite OSRM (OpenStreetMap Routing Machine).
///
/// Usa il server pubblico di demo: va bene per sviluppo e test, ma non è
/// pensato per il traffico di un'app in produzione. In M4 useremo un motore
/// di routing (OSRM/Valhalla) sul server personale: cambierà solo [_host].
class RoutingService {
  const RoutingService();

  static const String _host = 'router.project-osrm.org';

  /// Calcola il percorso in auto da [da] a [a], con le manovre passo-passo.
  Future<RouteResult> route(LatLng da, LatLng a) async {
    final coords =
        '${da.longitude},${da.latitude};${a.longitude},${a.latitude}';
    final uri = Uri.https(_host, '/route/v1/driving/$coords', {
      'overview': 'full',
      'geometries': 'geojson',
      'steps': 'true',
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
    return parseRoute(r);
  }

  /// Estrae geometria e manovre da una route OSRM.
  ///
  /// La polyline viene ricostruita concatenando la geometria dei singoli
  /// step: così ogni manovra sa a quale punto del tracciato corrisponde,
  /// informazione necessaria per sapere quanto manca alla prossima svolta.
  static RouteResult parseRoute(Map<String, dynamic> r) {
    final polyline = <LatLng>[];
    final steps = <RouteStep>[];

    for (final leg in (r['legs'] as List? ?? const [])) {
      for (final s in ((leg as Map)['steps'] as List? ?? const [])) {
        final step = s as Map<String, dynamic>;
        final manovra = step['maneuver'] as Map<String, dynamic>? ?? const {};
        final punti = _puntiGeoJson(step['geometry']);

        final indiceInizio = polyline.length;
        // Evita di ripetere il punto di giunzione tra uno step e il successivo.
        if (polyline.isNotEmpty && punti.isNotEmpty) {
          polyline.addAll(punti.skip(1));
        } else {
          polyline.addAll(punti);
        }

        final loc = manovra['location'];
        steps.add(RouteStep(
          tipo: (manovra['type'] ?? '').toString(),
          modificatore: manovra['modifier']?.toString(),
          nomeStrada: (step['name'] ?? '').toString(),
          uscitaRotonda: (step['exit'] as num?)?.toInt(),
          metri: (step['distance'] as num?)?.toDouble() ?? 0,
          posizione: loc is List && loc.length >= 2
              ? LatLng((loc[1] as num).toDouble(), (loc[0] as num).toDouble())
              : (punti.isNotEmpty ? punti.first : const LatLng(0, 0)),
          indiceInizio: indiceInizio == 0 ? 0 : indiceInizio - 1,
        ));
      }
    }

    // Se per qualche motivo mancassero gli step, ripieghiamo sulla geometria
    // complessiva, così il percorso resta comunque disegnabile.
    final geometria =
        polyline.isNotEmpty ? polyline : _puntiGeoJson(r['geometry']);

    return RouteResult(
      polyline: geometria,
      steps: steps,
      metri: (r['distance'] as num).toDouble(),
      secondi: (r['duration'] as num).toDouble(),
    );
  }

  /// GeoJSON usa [longitudine, latitudine]: qui invertiamo.
  static List<LatLng> _puntiGeoJson(dynamic geometry) {
    if (geometry is! Map) return const [];
    final coords = geometry['coordinates'];
    if (coords is! List) return const [];
    return coords
        .whereType<List>()
        .map((c) => LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()))
        .toList();
  }
}
