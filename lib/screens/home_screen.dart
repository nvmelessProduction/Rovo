import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../components/fuel_marker.dart';
import '../components/itinerary_sheet.dart';
import '../components/numbered_marker.dart';
import '../data/seed.dart';
import '../models/fuel_station.dart';
import '../models/stop.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import 'guide_screen.dart';

/// Schermata principale: mappa OpenStreetMap a tutto schermo.
///
/// - Modalità normale: mappa + barra di ricerca (placeholder) + invito a
///   entrare nella modalità Turismo. Nessun racconto audio.
/// - Modalità Turismo: percorso, tappe numerate e bottom sheet con la lista.
class HomeScreen extends StatelessWidget {
  /// Passa alla scheda "Turismo" (gestita dal RootScaffold).
  final VoidCallback onOpenTourism;

  const HomeScreen({super.key, required this.onOpenTourism});

  static const LatLng _center = LatLng(43.545, 11.300);

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

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
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

    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            options: const MapOptions(
              initialCenter: _center,
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
              MarkerLayer(markers: [...fuelMarkers, ...stopMarkers]),
            ],
          ),

          // Barra di ricerca (placeholder, non ancora funzionale in M1).
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: _SearchBar(
                  tourism: app.isTourism,
                  onExitTourism: context.read<AppState>().exitTourism,
                ),
              ),
            ),
          ),

          // Modalità normale: invito a entrare nel Turismo.
          if (!app.isTourism)
            Positioned(
              left: 16,
              right: 16,
              bottom: 24,
              child: _TourismCta(onOpenTourism: onOpenTourism),
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

class _SearchBar extends StatelessWidget {
  final bool tourism;
  final VoidCallback onExitTourism;

  const _SearchBar({required this.tourism, required this.onExitTourism});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Icon(
            tourism ? Icons.explore : Icons.search,
            color: AppColors.muted,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              tourism ? 'Modalità Turismo · La Via del Chianti' : 'Dove vuoi andare?',
              style: const TextStyle(color: AppColors.muted, fontSize: 15),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (tourism)
            TextButton(
              onPressed: onExitTourism,
              style: TextButton.styleFrom(foregroundColor: AppColors.chiantiRed),
              child: const Text('Esci'),
            ),
        ],
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
