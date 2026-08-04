import 'package:latlong2/latlong.dart';

/// Tipo di segnalazione stile Waze.
/// Definito ora per fissare il modello dati; l'uso pieno arriva in M6
/// (segnalazioni community in tempo reale via backend).
enum ReportType {
  autovelox,
  incidente,
  cantiere,
  traffico,
  pericolo,
}

/// Una segnalazione inserita da un utente lungo la strada.
class Report {
  final String id;
  final ReportType tipo;
  final LatLng posizione;
  final DateTime timestamp;

  const Report({
    required this.id,
    required this.tipo,
    required this.posizione,
    required this.timestamp,
  });

  factory Report.fromJson(Map<String, dynamic> json) => Report(
        id: json['id'] as String,
        tipo: ReportType.values.byName(json['tipo'] as String),
        posizione: LatLng(
          (json['lat'] as num).toDouble(),
          (json['lng'] as num).toDouble(),
        ),
        timestamp: DateTime.parse(json['timestamp'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'tipo': tipo.name,
        'lat': posizione.latitude,
        'lng': posizione.longitude,
        'timestamp': timestamp.toIso8601String(),
      };
}
