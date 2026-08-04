import 'package:flutter/material.dart';

import '../models/itinerary.dart';
import '../models/stop.dart';
import '../theme/app_theme.dart';
import 'stat_tile.dart';

/// Contenuto riutilizzabile dell'itinerario: intestazione, statistiche
/// (km / durata / tappe), pulsante d'azione opzionale e lista delle tappe.
///
/// Usato in due posti:
/// - nel bottom sheet trascinabile della mappa (con [scrollController]);
/// - nella scheda "Turismo" a schermo intero (con [onStart]).
class ItinerarySheet extends StatelessWidget {
  final Itinerary itinerary;
  final void Function(Stop stop) onStopTap;
  final ScrollController? scrollController;
  final VoidCallback? onStart;
  final String startLabel;
  final int? selectedStopNumero;
  final bool showHandle;

  const ItinerarySheet({
    super.key,
    required this.itinerary,
    required this.onStopTap,
    this.scrollController,
    this.onStart,
    this.startLabel = 'Avvia esperienza',
    this.selectedStopNumero,
    this.showHandle = true,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        if (showHandle)
          Center(
            child: Container(
              width: 44,
              height: 5,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: AppColors.muted.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        Text(itinerary.titolo, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 4),
        Text(
          itinerary.sottotitolo,
          style: const TextStyle(color: AppColors.muted, fontSize: 14),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Row(
              children: [
                StatTile(
                  icon: Icons.route,
                  value: '${itinerary.km.toStringAsFixed(0)} km',
                  label: 'Distanza',
                ),
                StatTile(
                  icon: Icons.schedule,
                  value: itinerary.durataLabel,
                  label: 'Durata',
                ),
                StatTile(
                  icon: Icons.place,
                  value: '${itinerary.numeroTappe}',
                  label: 'Tappe',
                ),
              ],
            ),
          ),
        ),
        if (onStart != null) ...[
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onStart,
              icon: const Icon(Icons.navigation),
              label: Text(startLabel),
            ),
          ),
        ],
        const SizedBox(height: 20),
        const Text(
          'Le tappe',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.charcoal,
          ),
        ),
        const SizedBox(height: 8),
        ...itinerary.stops.map((stop) {
          final isSelected = selectedStopNumero == stop.numero;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Material(
              color: isSelected ? AppColors.oliveGreen.withValues(alpha: 0.12) : AppColors.sand,
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => onStopTap(stop),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: AppColors.chiantiRed,
                        child: Text(
                          '${stop.numero}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          stop.titolo,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: AppColors.muted),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}
