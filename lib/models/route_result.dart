import 'package:latlong2/latlong.dart';

/// Il risultato del calcolo di un percorso: geometria + distanza + durata.
class RouteResult {
  final List<LatLng> polyline;
  final double metri;
  final double secondi;

  const RouteResult({
    required this.polyline,
    required this.metri,
    required this.secondi,
  });

  double get km => metri / 1000;
  int get minuti => (secondi / 60).round();

  /// Distanza formattata, es. "71 km" oppure "850 m".
  String get distanzaLabel {
    if (metri < 1000) return '${metri.round()} m';
    return '${km.toStringAsFixed(km < 10 ? 1 : 0)} km';
  }

  /// Durata formattata, es. "1h 35min".
  String get durataLabel {
    final h = minuti ~/ 60;
    final m = minuti % 60;
    if (h == 0) return '${m}min';
    if (m == 0) return '${h}h';
    return '${h}h ${m}min';
  }

  /// Orario di arrivo stimato a partire da adesso, es. "14:35".
  String get arrivoLabel {
    final arrivo = DateTime.now().add(Duration(minutes: minuti));
    final hh = arrivo.hour.toString().padLeft(2, '0');
    final mm = arrivo.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }
}
