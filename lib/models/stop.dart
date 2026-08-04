import 'package:latlong2/latlong.dart';

/// Una tappa di un itinerario turistico.
///
/// I campi sono pensati per mappare 1:1 una futura tabella `stops` del
/// database (M2), così il passaggio da dati mock a backend non richiede
/// riscritture del modello.
class Stop {
  final String id;
  final int numero; // ordine della tappa lungo il percorso (1..N)
  final String titolo;
  final LatLng posizione;
  final String racconto; // testo letto dalla guida audio (TTS it-IT)

  const Stop({
    required this.id,
    required this.numero,
    required this.titolo,
    required this.posizione,
    required this.racconto,
  });

  factory Stop.fromJson(Map<String, dynamic> json) => Stop(
        id: json['id'] as String,
        numero: json['numero'] as int,
        titolo: json['titolo'] as String,
        posizione: LatLng(
          (json['lat'] as num).toDouble(),
          (json['lng'] as num).toDouble(),
        ),
        racconto: json['racconto'] as String,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'numero': numero,
        'titolo': titolo,
        'lat': posizione.latitude,
        'lng': posizione.longitude,
        'racconto': racconto,
      };
}
