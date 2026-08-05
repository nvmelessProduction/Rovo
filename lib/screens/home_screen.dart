import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../components/fuel_marker.dart';
import '../components/itinerary_sheet.dart';
import '../components/numbered_marker.dart';
import '../components/route_panel.dart';
import '../data/seed.dart';
import '../models/fuel_station.dart';
import '../models/place.dart';
import '../models/stop.dart';
import '../services/location_service.dart';
import '../state/app_state.dart';
import '../state/navigation_session.dart';
import '../state/navigation_state.dart';
import '../theme/app_theme.dart';
import 'guide_screen.dart';
import 'navigation_screen.dart';
import 'search_screen.dart';

/// Schermata principale: mappa OpenStreetMap a tutto schermo.
///
/// - Modalità normale: ricerca destinazione, percorso su strada, posizione GPS.
///   Nessun racconto audio.
/// - Modalità Turismo: itinerario, tappe numerate e bottom sheet con la lista.
class HomeScreen extends StatefulWidget {
  /// Passa alla scheda "Turismo" (gestita dal RootScaffold).
  final VoidCallback onOpenTourism;

  const HomeScreen({super.key, required this.onOpenTourism});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const LatLng _centroIniziale = LatLng(43.545, 11.300);

  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    // Chiede la posizione all'avvio (il permesso viene chiesto una volta sola).
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final nav = context.read<NavigationState>();
      await nav.aggiornaPosizione();
      final pos = nav.posizioneUtente;
      if (pos != null && mounted && !nav.haPercorso) {
        _mapController.move(pos, 14);
      }
    });
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  void _openGuide(BuildContext context, Stop stop) {
    context.read<AppState>().selectStopById(stop.id);
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const GuideScreen()),
    );
  }

  void _showFuel(BuildContext context, FuelStation s, bool cheapest) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: cheapest ? AppColors.success : AppColors.fuel,
        content: Text(
          '${s.nome} · Benzina ${s.prezzoBenzina.toStringAsFixed(3)} € · '
          'Gasolio ${s.prezzoGasolio.toStringAsFixed(3)} €',
        ),
      ),
    );
  }

  /// Apre la ricerca; se l'utente sceglie un luogo, calcola il percorso
  /// e inquadra la mappa sull'intero tragitto.
  Future<void> _cercaDestinazione() async {
    final nav = context.read<NavigationState>();
    final scelto = await Navigator.of(context).push<Place>(
      MaterialPageRoute(builder: (_) => const SearchScreen()),
    );
    if (scelto == null || !mounted) return;

    await nav.vaiA(scelto);
    if (!mounted) return;

    final percorso = nav.percorso;
    if (percorso != null && percorso.polyline.isNotEmpty) {
      _mapController.fitCamera(
        CameraFit.coordinates(
          coordinates: percorso.polyline,
          padding: const EdgeInsets.fromLTRB(40, 120, 40, 200),
        ),
      );
    } else if (nav.errore != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.chiantiRed,
          content: Text(nav.errore!),
        ),
      );
    }
  }

  /// Avvia la guida turn-by-turn a schermo intero.
  Future<void> _avviaNavigazione() async {
    final nav = context.read<NavigationState>();
    final sessione = context.read<NavigationSession>();
    final destinazione = nav.destinazione;
    final percorso = nav.percorso;
    if (destinazione == null || percorso == null) return;

    // Senza permesso GPS la guida non può seguire l'utente.
    final ok = await LocationService().assicuraPermesso();
    if (!mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Per navigare serve la posizione. Attiva il GPS e concedi il permesso.',
          ),
        ),
      );
      return;
    }

    await sessione.avvia(destinazione, percorso);
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const NavigationScreen()),
    );
  }

  void _centraSuDiMe() async {
    final nav = context.read<NavigationState>();
    await nav.aggiornaPosizione();
    final pos = nav.posizioneUtente;
    if (!mounted) return;
    if (pos == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Posizione non disponibile. Attiva il GPS e concedi il permesso.',
          ),
        ),
      );
      return;
    }
    _mapController.move(pos, 15);
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final nav = context.watch<NavigationState>();
    final itinerary = app.itinerary;

    // Il distributore più economico (benzina) è evidenziato anche sulla mappa.
    final cheapestId = ([...fuelStationsMock]
          ..sort((a, b) => a.prezzoBenzina.compareTo(b.prezzoBenzina)))
        .first
        .id;

    final fuelMarkers = fuelStationsMock.map((s) {
      return Marker(
        point: s.posizione,
        width: 32,
        height: 32,
        child: FuelMarker(
          cheapest: s.id == cheapestId,
          onTap: () => _showFuel(context, s, s.id == cheapestId),
        ),
      );
    }).toList();

    final stopMarkers = app.isTourism
        ? itinerary.stops.map((stop) {
            return Marker(
              point: stop.posizione,
              width: 46,
              height: 46,
              child: NumberedMarker(
                numero: stop.numero,
                selected: app.selectedStopIndex == stop.numero - 1,
                onTap: () => _openGuide(context, stop),
              ),
            );
          }).toList()
        : <Marker>[];

    final navMarkers = <Marker>[
      if (nav.posizioneUtente != null)
        Marker(
          point: nav.posizioneUtente!,
          width: 24,
          height: 24,
          child: const _PallinoPosizione(),
        ),
      if (nav.destinazione != null)
        Marker(
          point: nav.destinazione!.posizione,
          width: 36,
          height: 36,
          child: const Icon(
            Icons.location_on,
            color: AppColors.chiantiRed,
            size: 36,
          ),
        ),
    ];

    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: const MapOptions(
              initialCenter: _centroIniziale,
              initialZoom: 9.2,
              minZoom: 4,
              maxZoom: 18,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.rova.app',
              ),
              if (app.isTourism)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: itinerary.routePolyline,
                      strokeWidth: 5,
                      color: AppColors.chiantiRed,
                    ),
                  ],
                ),
              if (nav.percorso != null)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: nav.percorso!.polyline,
                      strokeWidth: 6,
                      color: AppColors.fuel,
                    ),
                  ],
                ),
              MarkerLayer(markers: [...fuelMarkers, ...stopMarkers, ...navMarkers]),
            ],
          ),

          // Barra di ricerca (in modalità normale è attiva).
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: _SearchBar(
                  tourism: app.isTourism,
                  testo: nav.destinazione?.nome,
                  onTap: app.isTourism ? null : _cercaDestinazione,
                  onExitTourism: context.read<AppState>().exitTourism,
                ),
              ),
            ),
          ),

          // Pulsante "centra sulla mia posizione".
          if (!app.isTourism)
            Positioned(
              right: 16,
              bottom: nav.haPercorso ? 170 : 108,
              child: FloatingActionButton.small(
                heroTag: 'gps',
                backgroundColor: Colors.white,
                foregroundColor: AppColors.chiantiRed,
                onPressed: _centraSuDiMe,
                child: const Icon(Icons.my_location),
              ),
            ),

          if (nav.caricando)
            const Positioned(
              top: 80,
              left: 0,
              right: 0,
              child: Center(child: _Caricamento()),
            ),

          // Riepilogo del percorso calcolato.
          if (!app.isTourism && nav.haPercorso)
            Positioned(
              left: 16,
              right: 16,
              bottom: 24,
              child: RoutePanel(
                destinazione: nav.destinazione!,
                percorso: nav.percorso!,
                onAnnulla: context.read<NavigationState>().annulla,
                onAvvia: _avviaNavigazione,
              ),
            ),

          // Modalità normale senza percorso: invito al Turismo.
          if (!app.isTourism && !nav.haPercorso && !nav.caricando)
            Positioned(
              left: 16,
              right: 16,
              bottom: 24,
              child: _TourismCta(onOpenTourism: widget.onOpenTourism),
            ),

          // Modalità Turismo: bottom sheet trascinabile con la lista tappe.
          if (app.isTourism)
            DraggableScrollableSheet(
              initialChildSize: 0.32,
              minChildSize: 0.14,
              maxChildSize: 0.85,
              builder: (context, scrollController) {
                return Container(
                  decoration: const BoxDecoration(
                    color: AppColors.cream,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                    boxShadow: [
                      BoxShadow(color: Colors.black26, blurRadius: 12),
                    ],
                  ),
                  child: ItinerarySheet(
                    itinerary: itinerary,
                    scrollController: scrollController,
                    selectedStopNumero: app.selectedStopIndex + 1,
                    onStopTap: (stop) => _openGuide(context, stop),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _PallinoPosizione extends StatelessWidget {
  const _PallinoPosizione();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.fuel,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: const [
          BoxShadow(color: Colors.black38, blurRadius: 4),
        ],
      ),
    );
  }
}

class _Caricamento extends StatelessWidget {
  const _Caricamento();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6)],
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 10),
          Text('Calcolo il percorso…'),
        ],
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  final bool tourism;
  final String? testo;
  final VoidCallback? onTap;
  final VoidCallback onExitTourism;

  const _SearchBar({
    required this.tourism,
    required this.testo,
    required this.onTap,
    required this.onExitTourism,
  });

  @override
  Widget build(BuildContext context) {
    final etichetta = tourism
        ? 'Modalità Turismo · La Via del Chianti'
        : (testo ?? 'Dove vuoi andare?');

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      elevation: 4,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            children: [
              Icon(
                tourism ? Icons.explore : Icons.search,
                color: AppColors.muted,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  etichetta,
                  style: TextStyle(
                    color: testo == null ? AppColors.muted : AppColors.charcoal,
                    fontSize: 15,
                    fontWeight:
                        testo == null ? FontWeight.normal : FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (tourism)
                TextButton(
                  onPressed: onExitTourism,
                  style:
                      TextButton.styleFrom(foregroundColor: AppColors.chiantiRed),
                  child: const Text('Esci'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TourismCta extends StatelessWidget {
  final VoidCallback onOpenTourism;

  const _TourismCta({required this.onOpenTourism});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 4,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onOpenTourism,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.oliveGreen,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.headphones, color: Colors.white),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Fai un viaggio con la guida',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: AppColors.charcoal,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Attiva la modalità Turismo e ascolta i racconti',
                      style: TextStyle(color: AppColors.muted, fontSize: 13),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.muted),
            ],
          ),
        ),
      ),
    );
  }
}
