import 'package:latlong2/latlong.dart';

import 'stop.dart';

/// Un itinerario turistico: il percorso disegnato sulla mappa, le tappe
/// con i racconti e le statistiche di viaggio.
class Itinerary {
  final String id;
  final String titolo;
  final String sottotitolo;
  final List<Stop> stops;
  final List<LatLng> routePolyline; // geometria del percorso (mock in M1)
  final double km;
  final int durataMin;

  const Itinerary({
    required this.id,
    required this.titolo,
    required this.sottotitolo,
    required this.stops,
    required this.routePolyline,
    required this.km,
    required this.durataMin,
  });

  int get numeroTappe => stops.length;

  /// Durata formattata, es. "1h 30min".
  String get durataLabel {
    final h = durataMin ~/ 60;
    final m = durataMin % 60;
    if (h == 0) return '${m}min';
    if (m == 0) return '${h}h';
    return '${h}h ${m}min';
  }
}
