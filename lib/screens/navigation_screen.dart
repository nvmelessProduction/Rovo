import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../components/maneuver_icon.dart';
import '../state/navigation_session.dart';
import '../theme/app_theme.dart';

/// Navigazione attiva a schermo intero: banner della manovra in alto,
/// mappa che segue l'utente, barra con tempo/distanza/arrivo in basso.
class NavigationScreen extends StatefulWidget {
  const NavigationScreen({super.key});

  @override
  State<NavigationScreen> createState() => _NavigationScreenState();
}

class _NavigationScreenState extends State<NavigationScreen> {
  final MapController _mapController = MapController();
  bool _seguiUtente = true;
  LatLng? _ultimaPosizioneSeguita;

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  /// Tiene la mappa centrata sull'utente mentre si muove.
  void _seguiSeNecessario(NavigationSession nav) {
    if (!_seguiUtente) return;
    final pos = nav.posizione;
    if (pos == null || pos == _ultimaPosizioneSeguita) return;
    _ultimaPosizioneSeguita = pos;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _mapController.move(pos, 16.5);
    });
  }

  Future<void> _esci(NavigationSession nav) async {
    await nav.termina();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final nav = context.watch<NavigationSession>();
    _seguiSeNecessario(nav);

    final percorso = nav.percorso;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _esci(nav);
      },
      child: Scaffold(
        body: Stack(
          children: [
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: nav.posizione ?? const LatLng(41.9028, 12.4964),
                initialZoom: 16.5,
                minZoom: 4,
                maxZoom: 19,
                // Se l'utente sposta la mappa a mano, smettiamo di seguirlo.
                onPointerDown: (event, point) =>
                    setState(() => _seguiUtente = false),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.rova.app',
                ),
                if (percorso != null)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: percorso.polyline,
                        strokeWidth: 8,
                        color: AppColors.fuel,
                      ),
                    ],
                  ),
                MarkerLayer(
                  markers: [
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
                    if (nav.posizione != null)
                      Marker(
                        point: nav.posizione!,
                        width: 34,
                        height: 34,
                        child: Transform.rotate(
                          angle: nav.direzione * 3.14159 / 180,
                          child: const _FrecciaUtente(),
                        ),
                      ),
                  ],
                ),
              ],
            ),

            // Banner della manovra.
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: _BannerManovra(nav: nav),
                ),
              ),
            ),

            if (nav.ricalcolando)
              const Positioned(
                top: 140,
                left: 0,
                right: 0,
                child: Center(child: _Pillola(testo: 'Ricalcolo il percorso…')),
              ),

            if (!_seguiUtente)
              Positioned(
                right: 16,
                bottom: 150,
                child: FloatingActionButton.small(
                  heroTag: 'ricentra',
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.chiantiRed,
                  onPressed: () => setState(() => _seguiUtente = true),
                  child: const Icon(Icons.my_location),
                ),
              ),

            // Barra inferiore con i dati del viaggio.
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _BarraViaggio(nav: nav, onEsci: () => _esci(nav)),
            ),
          ],
        ),
      ),
    );
  }
}

class _BannerManovra extends StatelessWidget {
  final NavigationSession nav;

  const _BannerManovra({required this.nav});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.charcoal,
      borderRadius: BorderRadius.circular(18),
      elevation: 8,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: nav.ripetiIstruzione,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              ManeuverIcon(step: nav.prossimaManovra, size: 46),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      nav.distanzaManovraLabel,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      nav.istruzione,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: nav.alternaVoce,
                tooltip: nav.vocePresente ? 'Silenzia' : 'Attiva voce',
                icon: Icon(
                  nav.vocePresente ? Icons.volume_up : Icons.volume_off,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BarraViaggio extends StatelessWidget {
  final NavigationSession nav;
  final VoidCallback onEsci;

  const _BarraViaggio({required this.nav, required this.onEsci});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 12)],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _Dato(
                      valore: nav.durataRimanenteLabel,
                      etichetta: 'mancano',
                      forte: true,
                    ),
                    _Dato(
                      valore: nav.distanzaRimanenteLabel,
                      etichetta: 'distanza',
                    ),
                    _Dato(valore: nav.arrivoLabel, etichetta: 'arrivo'),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                onPressed: onEsci,
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.chiantiRed,
                ),
                icon: const Icon(Icons.close),
                tooltip: 'Termina navigazione',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Dato extends StatelessWidget {
  final String valore;
  final String etichetta;
  final bool forte;

  const _Dato({
    required this.valore,
    required this.etichetta,
    this.forte = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
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

class _FrecciaUtente extends StatelessWidget {
  const _FrecciaUtente();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.fuel,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 5)],
      ),
      child: const Icon(Icons.navigation, color: Colors.white, size: 18),
    );
  }
}

class _Pillola extends StatelessWidget {
  final String testo;

  const _Pillola({required this.testo});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6)],
      ),
      child: Text(testo),
    );
  }
}
