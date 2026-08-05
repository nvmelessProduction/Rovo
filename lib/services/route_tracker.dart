import 'dart:math' as math;

import 'package:latlong2/latlong.dart';

/// Posizione dell'utente proiettata sul percorso.
class RouteProgress {
  final int indiceSegmento; // segmento della polyline su cui si trova
  final double metriPercorsi; // distanza percorsa dall'inizio del tragitto
  final double metriDalPercorso; // quanto è lontano dalla linea del percorso

  const RouteProgress({
    required this.indiceSegmento,
    required this.metriPercorsi,
    required this.metriDalPercorso,
  });
}

/// Calcola l'avanzamento lungo un percorso: dove sei, quanto hai fatto,
/// quanto manca e se ti sei allontanato dalla strada prevista.
class RouteTracker {
  final List<LatLng> polyline;

  /// Distanza cumulata dall'inizio fino a ogni punto della polyline.
  late final List<double> _cumulate;

  static const Distance _distance = Distance();

  RouteTracker(this.polyline) {
    _cumulate = List<double>.filled(polyline.length, 0);
    for (var i = 1; i < polyline.length; i++) {
      _cumulate[i] =
          _cumulate[i - 1] + _distance(polyline[i - 1], polyline[i]);
    }
  }

  double get metriTotali => _cumulate.isEmpty ? 0 : _cumulate.last;

  /// Distanza cumulata fino al punto [indice] della polyline.
  double metriFinoA(int indice) {
    if (_cumulate.isEmpty) return 0;
    final i = indice.clamp(0, _cumulate.length - 1);
    return _cumulate[i];
  }

  /// Proietta [posizione] sul percorso: trova il punto più vicino sulla linea.
  ///
  /// [daSegmento] permette di cercare solo in avanti rispetto al punto già
  /// raggiunto, evitando che un percorso che si ripassa vicino faccia
  /// "saltare indietro" l'avanzamento.
  RouteProgress progresso(LatLng posizione, {int daSegmento = 0}) {
    if (polyline.length < 2) {
      return const RouteProgress(
        indiceSegmento: 0,
        metriPercorsi: 0,
        metriDalPercorso: 0,
      );
    }

    var miglioreIndice = daSegmento;
    var migliorDistanza = double.infinity;
    var migliorMetri = 0.0;

    final inizio = daSegmento.clamp(0, polyline.length - 2);
    for (var i = inizio; i < polyline.length - 1; i++) {
      final a = polyline[i];
      final b = polyline[i + 1];
      final t = _proiezione(posizione, a, b);
      final punto = LatLng(
        a.latitude + (b.latitude - a.latitude) * t,
        a.longitude + (b.longitude - a.longitude) * t,
      );
      final d = _distance(posizione, punto);
      if (d < migliorDistanza) {
        migliorDistanza = d;
        miglioreIndice = i;
        migliorMetri = _cumulate[i] + _distance(a, punto);
      }
    }

    return RouteProgress(
      indiceSegmento: miglioreIndice,
      metriPercorsi: migliorMetri,
      metriDalPercorso: migliorDistanza,
    );
  }

  /// Posizione relativa (0..1) della proiezione di [p] sul segmento a-b.
  static double _proiezione(LatLng p, LatLng a, LatLng b) {
    // Alle distanze in gioco basta un piano cartesiano locale, con la
    // longitudine compressa in base alla latitudine.
    final fattore = math.cos(a.latitude * math.pi / 180);
    final ax = a.longitude * fattore, ay = a.latitude;
    final bx = b.longitude * fattore, by = b.latitude;
    final px = p.longitude * fattore, py = p.latitude;

    final dx = bx - ax, dy = by - ay;
    final lunghezza2 = dx * dx + dy * dy;
    if (lunghezza2 == 0) return 0;

    final t = ((px - ax) * dx + (py - ay) * dy) / lunghezza2;
    return t.clamp(0.0, 1.0);
  }
}
