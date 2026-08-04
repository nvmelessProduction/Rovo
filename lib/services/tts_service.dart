import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Wrapper attorno a flutter_tts per la guida audio in italiano.
///
/// Espone stato "in riproduzione" così la UI può mostrare Ascolta/Ferma.
/// L'audio è usato SOLO nella modalità Turismo: nella navigazione normale
/// l'app resta muta.
class TtsService extends ChangeNotifier {
  final FlutterTts _tts = FlutterTts();
  bool _isSpeaking = false;
  bool _initialized = false;

  bool get isSpeaking => _isSpeaking;

  Future<void> _ensureInit() async {
    if (_initialized) return;
    await _tts.setLanguage('it-IT');
    await _selectBestItalianVoice();
    await _tts.setSpeechRate(0.48); // un po' più lento: si guida
    await _tts.setPitch(1.0);
    await _tts.setVolume(1.0);
    // Aspetta la fine del parlato prima di completare speak().
    await _tts.awaitSpeakCompletion(true);
    _tts.setCompletionHandler(() {
      _isSpeaking = false;
      notifyListeners();
    });
    _tts.setCancelHandler(() {
      _isSpeaking = false;
      notifyListeners();
    });
    _tts.setErrorHandler((_) {
      _isSpeaking = false;
      notifyListeners();
    });
    _initialized = true;
  }

  /// Sceglie la migliore voce italiana tra quelle installate sul dispositivo.
  /// Preferisce le voci "premium/enhanced/Siri" (naturali) ed evita le
  /// "compact" (robotiche). Se non trova nulla di meglio, resta sul default.
  ///
  /// Nota: l'app può usare solo le voci INSTALLATE nel telefono. Per sentire
  /// una voce davvero naturale, scaricare una voce italiana "Enhanced/Premium"
  /// da Impostazioni iOS → Accessibilità → Contenuto letto → Voci → Italiano.
  Future<void> _selectBestItalianVoice() async {
    try {
      final dynamic raw = await _tts.getVoices;
      if (raw is! List) return;
      final voices = raw
          .whereType<Map>()
          .map((v) => v.map((k, val) => MapEntry(k.toString(), val.toString())))
          .where((v) => (v['locale'] ?? '').toLowerCase().startsWith('it'))
          .toList();
      if (voices.isEmpty) return;

      int score(Map<String, String> v) {
        final name = (v['name'] ?? '').toLowerCase();
        var s = 0;
        if (name.contains('premium')) s += 4;
        if (name.contains('enhanced')) s += 3;
        if (name.contains('siri')) s += 3;
        if (name.contains('compact')) s -= 2;
        return s;
      }

      voices.sort((a, b) => score(b).compareTo(score(a)));
      final best = voices.first;
      if (score(best) <= 0) return; // niente di meglio del default
      await _tts.setVoice({
        'name': best['name'] ?? '',
        'locale': best['locale'] ?? 'it-IT',
      });
    } catch (_) {
      // In caso di errore restiamo sulla voce di default it-IT.
    }
  }

  /// Legge [testo] ad alta voce. Se sta già parlando, prima ferma.
  Future<void> speak(String testo) async {
    await _ensureInit();
    if (_isSpeaking) {
      await stop();
    }
    _isSpeaking = true;
    notifyListeners();
    await _tts.speak(testo);
  }

  Future<void> stop() async {
    await _tts.stop();
    _isSpeaking = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }
}
