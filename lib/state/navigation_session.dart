import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../models/place.dart';
import '../models/route_result.dart';
import '../models/route_step.dart';
import '../services/instruction_builder.dart';
import '../services/location_service.dart';
import '../services/route_tracker.dart';
import '../services/routing_service.dart';
import '../services/tts_service.dart';

/// Guida attiva: segue la posizione durante il viaggio, dice quanto manca
/// alla prossima manovra, la annuncia a voce e ricalcola se si sbaglia strada.
class NavigationSession extends ChangeNotifier {
  final TtsService _tts;
  final LocationService _location;
  final RoutingService _routing;

  NavigationSession({
    required TtsService tts,
    LocationService? location,
    RoutingService? routing,
  })  : _tts = tts, // ignore: prefer_initializing_formals
        _location = location ?? const LocationService(),
        _routing = routing ?? const RoutingService();

  /// Soglie (in metri) a cui annunciare la manovra successiva.
  static const List<double> _soglieAnnuncio = [800, 300, 100];

  /// Oltre questa distanza dal percorso si considera "fuori strada".
  static const double _sogliaFuoriPercorso = 60;

  /// Quante letture consecutive fuori strada prima di ricalcolare.
  static const int _letturePrimaDiRicalcolare = 3;

  StreamSubscription<Position>? _sub;
  RouteTracker? _tracker;

  Place? _destinazione;
  RouteResult? _percorso;
  LatLng? _posizione;
  double _direzione = 0; // gradi, per orientare la mappa
  double _velocita = 0; // m/s

  int _stepCorrente = 0;
  int _segmentoCorrente = 0;
  double _metriAllaManovra = 0;
  double _metriRimanenti = 0;
  int _secondiRimanenti = 0;

  bool _attiva = false;
  bool _arrivato = false;
  bool _vocePresente = true;
  bool _ricalcolando = false;
  int _lettureFuoriPercorso = 0;
  final Set<String> _annunciFatti = {};

  bool get attiva => _attiva;
  bool get arrivato => _arrivato;
  bool get ricalcolando => _ricalcolando;
  bool get vocePresente => _vocePresente;
  LatLng? get posizione => _posizione;
  double get direzione => _direzione;
  double get velocitaKmh => _velocita * 3.6;
  Place? get destinazione => _destinazione;
  RouteResult? get percorso => _percorso;
  double get metriAllaManovra => _metriAllaManovra;

  RouteStep? get stepCorrente {
    final steps = _percorso?.steps;
    if (steps == null || steps.isEmpty) return null;
    return steps[_stepCorrente.clamp(0, steps.length - 1)];
  }

  /// La manovra da mostrare: è quella che stai per eseguire, cioè l'inizio
  /// dello step successivo a quello che stai percorrendo.
  RouteStep? get prossimaManovra {
    final steps = _percorso?.steps;
    if (steps == null || steps.isEmpty) return null;
    final i = (_stepCorrente + 1).clamp(0, steps.length - 1);
    return steps[i];
  }

  String get istruzione {
    final m = prossimaManovra;
    if (m == null) return 'Prosegui';
    return InstructionBuilder.frase(m);
  }

  String get distanzaManovraLabel =>
      InstructionBuilder.distanzaBreve(_metriAllaManovra);

  String get distanzaRimanenteLabel =>
      InstructionBuilder.distanzaBreve(_metriRimanenti);

  String get durataRimanenteLabel =>
      RouteResult.formattaDurata((_secondiRimanenti / 60).round());

  String get arrivoLabel =>
      RouteResult.formattaOrarioArrivo((_secondiRimanenti / 60).round());

  /// Avvia la guida su [percorso] verso [destinazione].
  Future<void> avvia(Place destinazione, RouteResult percorso) async {
    _destinazione = destinazione;
    _impostaPercorso(percorso);
    _attiva = true;
    _arrivato = false;
    notifyListeners();

    if (_vocePresente) {
      final primo = percorso.steps.isNotEmpty ? percorso.steps.first : null;
      await _parla(primo != null
          ? InstructionBuilder.frase(primo)
          : 'Navigazione avviata');
    }

    await _sub?.cancel();
    _sub = _location.stream().listen(_onPosizione, onError: (_) {});
  }

  void _impostaPercorso(RouteResult percorso) {
    _percorso = percorso;
    _tracker = RouteTracker(percorso.polyline);
    _stepCorrente = 0;
    _segmentoCorrente = 0;
    _metriRimanenti = percorso.metri;
    _secondiRimanenti = percorso.secondi.round();
    _metriAllaManovra = percorso.steps.isNotEmpty ? percorso.steps.first.metri : 0;
    _annunciFatti.clear();
    _lettureFuoriPercorso = 0;
  }

  void _onPosizione(Position pos) {
    final tracker = _tracker;
    final percorso = _percorso;
    if (!_attiva || tracker == null || percorso == null) return;

    _posizione = LatLng(pos.latitude, pos.longitude);
    if (pos.heading >= 0) _direzione = pos.heading;
    _velocita = pos.speed < 0 ? 0 : pos.speed;

    final prog = tracker.progresso(_posizione!, daSegmento: _segmentoCorrente);
    _segmentoCorrente = prog.indiceSegmento;

    // Fuori percorso: dopo alcune letture consecutive, ricalcola.
    if (prog.metriDalPercorso > _sogliaFuoriPercorso) {
      _lettureFuoriPercorso++;
      if (_lettureFuoriPercorso >= _letturePrimaDiRicalcolare && !_ricalcolando) {
        _ricalcola();
      }
      notifyListeners();
      return;
    }
    _lettureFuoriPercorso = 0;

    _aggiornaStep(prog, tracker, percorso);
    _aggiornaRimanenti(prog, tracker, percorso);
    _controllaArrivo();
    _annunciaSeServe();

    notifyListeners();
  }

  /// Avanza allo step giusto in base a quanto si è percorso.
  void _aggiornaStep(
    RouteProgress prog,
    RouteTracker tracker,
    RouteResult percorso,
  ) {
    final steps = percorso.steps;
    if (steps.isEmpty) return;

    while (_stepCorrente < steps.length - 2 &&
        prog.metriPercorsi >= tracker.metriFinoA(steps[_stepCorrente + 1].indiceInizio)) {
      _stepCorrente++;
      // Cambiata manovra: gli annunci ripartono per quella nuova.
      _annunciFatti.removeWhere((k) => k.startsWith('${_stepCorrente - 1}:'));
    }

    final prossimo = (_stepCorrente + 1).clamp(0, steps.length - 1);
    final metriManovra = tracker.metriFinoA(steps[prossimo].indiceInizio);
    _metriAllaManovra = (metriManovra - prog.metriPercorsi).clamp(0, double.infinity);
  }

  void _aggiornaRimanenti(
    RouteProgress prog,
    RouteTracker tracker,
    RouteResult percorso,
  ) {
    _metriRimanenti =
        (tracker.metriTotali - prog.metriPercorsi).clamp(0, double.infinity);
    final frazione =
        tracker.metriTotali <= 0 ? 0.0 : _metriRimanenti / tracker.metriTotali;
    _secondiRimanenti = (percorso.secondi * frazione).round();
  }

  void _controllaArrivo() {
    if (_arrivato) return;
    if (_metriRimanenti <= 40) {
      _arrivato = true;
      _attiva = false;
      _sub?.cancel();
      _parla('Sei arrivato a destinazione');
    }
  }

  /// Annuncia la manovra alle soglie previste, una volta sola ciascuna.
  void _annunciaSeServe() {
    if (!_vocePresente || _arrivato) return;
    final manovra = prossimaManovra;
    if (manovra == null) return;

    for (final soglia in _soglieAnnuncio) {
      // Il tratto è più corto della soglia: quell'annuncio non ha senso.
      if (soglia > (_percorso?.metri ?? 0)) continue;
      final chiave = '$_stepCorrente:${soglia.round()}';
      if (_annunciFatti.contains(chiave)) continue;
      if (_metriAllaManovra <= soglia) {
        _annunciFatti.add(chiave);
        _parla(InstructionBuilder.annuncio(manovra, _metriAllaManovra));
        return; // un annuncio per volta
      }
    }
  }

  Future<void> _ricalcola() async {
    final dest = _destinazione;
    final pos = _posizione;
    if (dest == null || pos == null) return;

    _ricalcolando = true;
    notifyListeners();
    if (_vocePresente) await _parla('Ricalcolo il percorso');

    try {
      final nuovo = await _routing.route(pos, dest.posizione);
      _impostaPercorso(nuovo);
    } catch (_) {
      // Se il ricalcolo fallisce teniamo il percorso vecchio: meglio di niente.
      _lettureFuoriPercorso = 0;
    } finally {
      _ricalcolando = false;
      notifyListeners();
    }
  }

  Future<void> _parla(String testo) async {
    try {
      await _tts.speak(testo);
    } catch (_) {
      // La voce non deve mai bloccare la navigazione.
    }
  }

  void alternaVoce() {
    _vocePresente = !_vocePresente;
    if (!_vocePresente) _tts.stop();
    notifyListeners();
  }

  /// Ripete a voce l'istruzione corrente.
  void ripetiIstruzione() {
    final m = prossimaManovra;
    if (m != null) _parla(InstructionBuilder.annuncio(m, _metriAllaManovra));
  }

  Future<void> termina() async {
    _attiva = false;
    _arrivato = false;
    await _sub?.cancel();
    _sub = null;
    await _tts.stop();
    notifyListeners();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
