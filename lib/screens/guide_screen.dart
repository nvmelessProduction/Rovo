import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/tts_service.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';

/// Dettaglio di una tappa: titolo, racconto e guida audio.
/// L'audio (TTS italiano) è il cuore della modalità Turismo.
class GuideScreen extends StatefulWidget {
  const GuideScreen({super.key});

  @override
  State<GuideScreen> createState() => _GuideScreenState();
}

class _GuideScreenState extends State<GuideScreen> {
  @override
  void dispose() {
    super.dispose();
  }

  void _changeStop(BuildContext context, VoidCallback change) {
    // Cambiando tappa fermiamo l'eventuale racconto in corso.
    context.read<TtsService>().stop();
    change();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final tts = context.watch<TtsService>();
    final stop = app.selectedStop;

    return Scaffold(
      appBar: AppBar(
        title: Text('Tappa ${stop.numero} di ${app.itinerary.numeroTappe}'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Text(
                    stop.titolo,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        if (tts.isSpeaking) {
                          tts.stop();
                        } else {
                          tts.speak(stop.racconto);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: tts.isSpeaking
                            ? AppColors.oliveGreen
                            : AppColors.chiantiRed,
                      ),
                      icon: Icon(tts.isSpeaking ? Icons.stop : Icons.volume_up),
                      label: Text(
                        tts.isSpeaking ? 'Ferma la guida' : 'Ascolta la guida',
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    stop.racconto,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
            ),
            _NavBar(
              hasPrev: app.hasPrev,
              hasNext: app.hasNext,
              onPrev: () => _changeStop(context, app.prevStop),
              onNext: () => _changeStop(context, app.nextStop),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavBar extends StatelessWidget {
  final bool hasPrev;
  final bool hasNext;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  const _NavBar({
    required this.hasPrev,
    required this.hasNext,
    required this.onPrev,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.sand)),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: hasPrev ? onPrev : null,
              icon: const Icon(Icons.chevron_left),
              label: const Text('Precedente'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                foregroundColor: AppColors.chiantiRed,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: hasNext ? onNext : null,
              icon: const Icon(Icons.chevron_right),
              label: const Text('Successiva'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                foregroundColor: AppColors.chiantiRed,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
