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
