import '../models/route_step.dart';

/// Trasforma le manovre tecniche di OSRM in frasi italiane naturali,
/// usate sia sullo schermo sia dalla voce.
class InstructionBuilder {
  /// Frase base della manovra, es. "Gira a destra su Via Roma".
  static String frase(RouteStep step) {
    final via = step.nomeStrada.trim();
    final suVia = via.isEmpty ? '' : ' su $via';
    final dir = _direzione(step.modificatore);

    switch (step.tipo) {
      case 'depart':
        return via.isEmpty ? 'Parti' : 'Parti su $via';

      case 'arrive':
        return 'Sei arrivato a destinazione';

      case 'turn':
        if (step.modificatore == 'uturn') return 'Fai inversione';
        if (step.modificatore == 'straight') return 'Prosegui dritto$suVia';
        return 'Gira $dir$suVia';

      case 'new name':
      case 'continue':
        if (step.modificatore == 'uturn') return 'Fai inversione';
        return 'Prosegui dritto$suVia';

      case 'merge':
        return 'Immettiti $dir$suVia';

      case 'on ramp':
        return via.isEmpty ? 'Prendi la rampa $dir' : 'Prendi la rampa$suVia';

      case 'off ramp':
        return via.isEmpty ? 'Prendi l\'uscita $dir' : 'Prendi l\'uscita$suVia';

      case 'fork':
        return 'Al bivio tieni $dir$suVia';

      case 'end of road':
        return 'Alla fine della strada gira $dir$suVia';

      case 'roundabout':
      case 'rotary':
        final n = step.uscitaRotonda;
        if (n != null && n > 0) {
          return 'Alla rotonda prendi la ${_ordinale(n)} uscita$suVia';
        }
        return 'Entra nella rotonda$suVia';

      case 'roundabout turn':
        return 'Alla rotonda gira $dir$suVia';

      case 'exit roundabout':
      case 'exit rotary':
        return 'Esci dalla rotonda$suVia';

      default:
        return via.isEmpty ? 'Prosegui' : 'Prosegui su $via';
    }
  }

  /// Frase annunciata dalla voce a una certa distanza dalla manovra,
  /// es. "Tra 300 metri, gira a destra su Via Roma".
  static String annuncio(RouteStep step, double metriAllaManovra) {
    final base = frase(step);
    if (step.tipo == 'depart') return base;
    if (step.isArrivo) {
      if (metriAllaManovra <= 60) return 'Sei arrivato a destinazione';
      return 'Tra ${distanzaParlata(metriAllaManovra)} arrivi a destinazione';
    }
    if (metriAllaManovra <= 60) return base;
    return 'Tra ${distanzaParlata(metriAllaManovra)}, ${_minuscolaIniziale(base)}';
  }

  /// Distanza pronunciata in modo naturale: arrotondata, non "287 metri".
  static String distanzaParlata(double metri) {
    if (metri >= 1000) {
      final km = metri / 1000;
      if (km >= 10) return '${km.round()} chilometri';
      final testo = km.toStringAsFixed(1).replaceAll('.', ',');
      return '$testo chilometri';
    }
    if (metri >= 100) return '${(metri / 50).round() * 50} metri';
    return '${(metri / 10).round() * 10} metri';
  }

  /// Distanza compatta per lo schermo, es. "300 m" o "1,2 km".
  static String distanzaBreve(double metri) {
    if (metri >= 1000) {
      final km = metri / 1000;
      final testo = km >= 10
          ? km.round().toString()
          : km.toStringAsFixed(1).replaceAll('.', ',');
      return '$testo km';
    }
    if (metri >= 100) return '${(metri / 50).round() * 50} m';
    return '${(metri / 10).round() * 10} m';
  }

  static String _direzione(String? modificatore) {
    switch (modificatore) {
      case 'right':
        return 'a destra';
      case 'left':
        return 'a sinistra';
      case 'slight right':
        return 'leggermente a destra';
      case 'slight left':
        return 'leggermente a sinistra';
      case 'sharp right':
        return 'tutto a destra';
      case 'sharp left':
        return 'tutto a sinistra';
      case 'uturn':
        return 'facendo inversione';
      case 'straight':
        return 'dritto';
      default:
        return 'dritto';
    }
  }

  static String _ordinale(int n) {
    const nomi = [
      'prima',
      'seconda',
      'terza',
      'quarta',
      'quinta',
      'sesta',
      'settima',
      'ottava',
    ];
    if (n >= 1 && n <= nomi.length) return nomi[n - 1];
    return '$n°';
  }

  static String _minuscolaIniziale(String testo) {
    if (testo.isEmpty) return testo;
    return testo[0].toLowerCase() + testo.substring(1);
  }
}
