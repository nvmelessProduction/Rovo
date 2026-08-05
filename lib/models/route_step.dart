import 'package:latlong2/latlong.dart';

/// Una manovra del percorso (es. "gira a destra su Via Roma").
///
/// I dati arrivano da OSRM; il testo in italiano viene costruito da
/// [InstructionBuilder] così la UI e la voce dicono la stessa cosa.
class RouteStep {
  final String tipo; // OSRM maneuver.type, es. "turn", "roundabout"
  final String? modificatore; // OSRM maneuver.modifier, es. "right"
  final String nomeStrada; // nome della strada da percorrere
  final int? uscitaRotonda; // numero di uscita, solo per rotonde
  final double metri; // lunghezza di questo tratto
  final LatLng posizione; // punto in cui si esegue la manovra
  final int indiceInizio; // indice del punto iniziale nella polyline completa

  const RouteStep({
    required this.tipo,
    required this.modificatore,
    required this.nomeStrada,
    required this.uscitaRotonda,
    required this.metri,
    required this.posizione,
    required this.indiceInizio,
  });

  bool get isArrivo => tipo == 'arrive';
}
