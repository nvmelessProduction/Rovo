import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'data/seed.dart';
import 'screens/fuel_screen.dart';
import 'screens/home_screen.dart';
import 'screens/itinerary_screen.dart';
import 'services/tts_service.dart';
import 'state/app_state.dart';
import 'state/navigation_state.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const RovaApp());
}

class RovaApp extends StatelessWidget {
  const RovaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Stato dell'app: modalità (normale/turismo), tappa selezionata.
        ChangeNotifierProvider(create: (_) => AppState(viaDelChianti)),
        // Guida audio (TTS italiano), condivisa tra le schermate.
        ChangeNotifierProvider(create: (_) => TtsService()),
        // Navigazione normale: posizione, destinazione e percorso.
        ChangeNotifierProvider(create: (_) => NavigationState()),
      ],
      child: MaterialApp(
        title: 'Rova',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const RootScaffold(),
      ),
    );
  }
}

/// Contenitore con la barra di navigazione a 3 schede:
/// Mappa · Turismo · Carburante.
class RootScaffold extends StatefulWidget {
  const RootScaffold({super.key});

  @override
  State<RootScaffold> createState() => _RootScaffoldState();
}

class _RootScaffoldState extends State<RootScaffold> {
  int _index = 0;

  void _goToTab(int i) => setState(() => _index = i);

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomeScreen(onOpenTourism: () => _goToTab(1)),
      ItineraryScreen(onStartExperience: () => _goToTab(0)),
      const FuelScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: _goToTab,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Mappa'),
          BottomNavigationBarItem(
            icon: Icon(Icons.headphones),
            label: 'Turismo',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.local_gas_station),
            label: 'Carburante',
          ),
        ],
      ),
    );
  }
}
