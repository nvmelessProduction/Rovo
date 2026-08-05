import 'package:latlong2/latlong.dart';

/// Un luogo trovato dalla ricerca (indirizzo, città, punto di interesse).
class Place {
  final String id;
  final String nome; // riga principale, es. "Via Roma 12"
  final String descrizione; // riga secondaria, es. "Ladispoli, Roma, Lazio"
  final LatLng posizione;

  const Place({
    required this.id,
    required this.nome,
    required this.descrizione,
    required this.posizione,
  });

  /// Costruisce un Place dalla risposta di Nominatim (OpenStreetMap).
  factory Place.fromNominatim(Map<String, dynamic> json) {
    final display = (json['display_name'] as String?) ?? '';
    final parti = display.split(',').map((s) => s.trim()).toList();
    final nome = parti.isNotEmpty ? parti.first : display;
    final descrizione = parti.length > 1 ? parti.sublist(1).join(', ') : '';
    return Place(
      id: '${json['osm_type'] ?? ''}${json['osm_id'] ?? display}',
      nome: nome,
      descrizione: descrizione,
      posizione: LatLng(
        double.parse(json['lat'].toString()),
        double.parse(json['lon'].toString()),
      ),
    );
  }
}
