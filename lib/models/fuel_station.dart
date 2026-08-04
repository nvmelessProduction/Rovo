import 'package:latlong2/latlong.dart';

/// Un distributore di carburante.
///
/// In M1 i prezzi sono mock; dalla M3 arriveranno dagli open data
/// Osservaprezzi Carburanti (MIMIT) ingeriti nel database.
class FuelStation {
  final String id;
  final String nome;
  final String brand;
  final LatLng posizione;
  final double prezzoBenzina; // €/litro
  final double prezzoGasolio; // €/litro
  final String indirizzo;

  const FuelStation({
    required this.id,
    required this.nome,
    required this.brand,
    required this.posizione,
    required this.prezzoBenzina,
    required this.prezzoGasolio,
    required this.indirizzo,
  });

  factory FuelStation.fromJson(Map<String, dynamic> json) => FuelStation(
        id: json['id'] as String,
        nome: json['nome'] as String,
        brand: json['brand'] as String,
        posizione: LatLng(
          (json['lat'] as num).toDouble(),
          (json['lng'] as num).toDouble(),
        ),
        prezzoBenzina: (json['prezzoBenzina'] as num).toDouble(),
        prezzoGasolio: (json['prezzoGasolio'] as num).toDouble(),
        indirizzo: json['indirizzo'] as String,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'nome': nome,
        'brand': brand,
        'lat': posizione.latitude,
        'lng': posizione.longitude,
        'prezzoBenzina': prezzoBenzina,
        'prezzoGasolio': prezzoGasolio,
        'indirizzo': indirizzo,
      };
}
