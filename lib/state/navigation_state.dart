import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';

import '../models/place.dart';
import '../models/route_result.dart';
import '../services/location_service.dart';
import '../services/routing_service.dart';

/// Stato della navigazione "normale" (non turistica): posizione dell'utente,
/// destinazione scelta e percorso calcolato.
class NavigationState extends ChangeNotifier {
  final LocationService _location;
  final RoutingService _routing;

  NavigationState({
    LocationService? location,
    RoutingService? routing,
  })  : _location = location ?? LocationService(),
        _routing = routing ?? RoutingService();

  /// Punto di partenza usato se il GPS non è disponibile (centro Italia).
  static const LatLng _fallbackPartenza = LatLng(41.9028, 12.4964);

  LatLng? _posizioneUtente;
  Place? _destinazione;
  RouteResult? _percorso;
  bool _caricando = false;
  String? _errore;

  LatLng? get posizioneUtente => _posizioneUtente;
  Place? get destinazione => _destinazione;
  RouteResult? get percorso => _percorso;
  bool get caricando => _caricando;
  String? get errore => _errore;
  bool get haPercorso => _percorso != null;

  /// Legge la posizione GPS (chiedendo il permesso la prima volta).
  Future<void> aggiornaPosizione() async {
    final pos = await _location.currentPosition();
    if (pos != null) {
      _posizioneUtente = pos;
      notifyListeners();
    }
  }

  /// Imposta la destinazione e calcola il percorso dalla posizione attuale.
  Future<void> vaiA(Place destinazione) async {
    _destinazione = destinazione;
    _percorso = null;
    _errore = null;
    _caricando = true;
    notifyListeners();

    try {
      // Se non abbiamo ancora la posizione, proviamo a ottenerla ora.
      _posizioneUtente ??= await _location.currentPosition();
      final partenza = _posizioneUtente ?? _fallbackPartenza;
      _percorso = await _routing.route(partenza, destinazione.posizione);
    } catch (e) {
      _errore = 'Non riesco a calcolare il percorso. Controlla la connessione.';
    } finally {
      _caricando = false;
      notifyListeners();
    }
  }

  /// Annulla destinazione e percorso.
  void annulla() {
    _destinazione = null;
    _percorso = null;
    _errore = null;
    _caricando = false;
    notifyListeners();
  }
}
