import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../components/itinerary_sheet.dart';
import '../models/stop.dart';
import '../state/app_state.dart';
import 'guide_screen.dart';

/// Scheda "Turismo": presenta l'itinerario turistico dell'esperienza.
/// Da qui si avvia l'esperienza (che attiva la guida audio sulla mappa)
/// oppure si apre direttamente il dettaglio di una tappa.
class ItineraryScreen extends StatelessWidget {
  /// Avvia l'esperienza e riporta l'utente alla mappa (tab 0).
  final VoidCallback onStartExperience;

  const ItineraryScreen({super.key, required this.onStartExperience});

  void _openGuide(BuildContext context, Stop stop) {
    context.read<AppState>().selectStopById(stop.id);
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const GuideScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();

    return Scaffold(
      appBar: AppBar(title: const Text('Turismo')),
      body: SafeArea(
        child: ItinerarySheet(
          itinerary: app.itinerary,
          showHandle: false,
          startLabel: 'Avvia esperienza',
          onStart: () {
            context.read<AppState>().startExperience();
            onStartExperience();
          },
          onStopTap: (stop) => _openGuide(context, stop),
        ),
      ),
    );
  }
}
