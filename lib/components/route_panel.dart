import 'package:flutter/material.dart';

import '../models/place.dart';
import '../models/route_result.dart';
import '../theme/app_theme.dart';

/// Pannello in basso con il riepilogo del percorso calcolato:
/// distanza, durata, orario di arrivo e destinazione.
class RoutePanel extends StatelessWidget {
  final Place destinazione;
  final RouteResult percorso;
  final VoidCallback onAnnulla;
  final VoidCallback onAvvia;

  const RoutePanel({
    super.key,
    required this.destinazione,
    required this.percorso,
    required this.onAnnulla,
    required this.onAvvia,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      elevation: 6,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.flag, color: AppColors.chiantiRed, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    destinazione.nome,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  onPressed: onAnnulla,
                  icon: const Icon(Icons.close, color: AppColors.muted),
                  tooltip: 'Annulla percorso',
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                _Info(
                  valore: percorso.durataLabel,
                  etichetta: 'durata',
                  forte: true,
                ),
                const SizedBox(width: 20),
                _Info(valore: percorso.distanzaLabel, etichetta: 'distanza'),
                const SizedBox(width: 20),
                _Info(valore: percorso.arrivoLabel, etichetta: 'arrivo'),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onAvvia,
                icon: const Icon(Icons.navigation),
                label: const Text('Avvia navigazione'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Info extends StatelessWidget {
  final String valore;
  final String etichetta;
  final bool forte;

  const _Info({
    required this.valore,
    required this.etichetta,
    this.forte = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          valore,
          style: TextStyle(
            fontSize: forte ? 22 : 18,
            fontWeight: FontWeight.w700,
            color: forte ? AppColors.success : AppColors.charcoal,
          ),
        ),
        Text(
          etichetta,
          style: const TextStyle(fontSize: 12, color: AppColors.muted),
        ),
      ],
    );
  }
}
