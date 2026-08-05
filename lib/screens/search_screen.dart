import 'dart:async';

import 'package:flutter/material.dart';

import '../models/place.dart';
import '../services/geocoding_service.dart';
import '../theme/app_theme.dart';

/// Schermata di ricerca della destinazione.
/// Restituisce il [Place] scelto tramite Navigator.pop.
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  final _geocoding = GeocodingService();

  Timer? _debounce;
  List<Place> _risultati = [];
  bool _caricando = false;
  String? _errore;
  int _richiestaCorrente = 0;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String testo) {
    // Aspetta che l'utente smetta di digitare prima di cercare.
    _debounce?.cancel();
    if (testo.trim().length < 3) {
      setState(() {
        _risultati = [];
        _errore = null;
        _caricando = false;
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 500), () => _cerca(testo));
  }

  Future<void> _cerca(String testo) async {
    final richiesta = ++_richiestaCorrente;
    setState(() {
      _caricando = true;
      _errore = null;
    });
    try {
      final esiti = await _geocoding.search(testo);
      // Ignora le risposte arrivate in ritardo rispetto all'ultima ricerca.
      if (!mounted || richiesta != _richiestaCorrente) return;
      setState(() {
        _risultati = esiti;
        _caricando = false;
      });
    } catch (_) {
      if (!mounted || richiesta != _richiestaCorrente) return;
      setState(() {
        _errore = 'Ricerca non riuscita. Controlla la connessione.';
        _caricando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dove vuoi andare?')),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _controller,
                autofocus: true,
                textInputAction: TextInputAction.search,
                onChanged: _onChanged,
                onSubmitted: _cerca,
                decoration: InputDecoration(
                  hintText: 'Indirizzo, città o luogo',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _controller.text.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _controller.clear();
                            _onChanged('');
                          },
                        ),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            if (_caricando) const LinearProgressIndicator(minHeight: 2),
            Expanded(child: _buildCorpo()),
          ],
        ),
      ),
    );
  }

  Widget _buildCorpo() {
    if (_errore != null) {
      return _Messaggio(icona: Icons.wifi_off, testo: _errore!);
    }
    if (_risultati.isEmpty) {
      return _Messaggio(
        icona: Icons.place_outlined,
        testo: _controller.text.trim().length < 3
            ? 'Scrivi almeno 3 lettere per cercare.\nEsempi: "Ladispoli", "Colosseo", "Via Roma 12 Siena".'
            : (_caricando ? 'Sto cercando…' : 'Nessun risultato.'),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _risultati.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, i) {
        final p = _risultati[i];
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(vertical: 4),
          leading: const Icon(Icons.place, color: AppColors.chiantiRed),
          title: Text(p.nome, style: Theme.of(context).textTheme.titleMedium),
          subtitle: p.descrizione.isEmpty
              ? null
              : Text(
                  p.descrizione,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.muted, fontSize: 13),
                ),
          onTap: () => Navigator.of(context).pop(p),
        );
      },
    );
  }
}

class _Messaggio extends StatelessWidget {
  final IconData icona;
  final String testo;

  const _Messaggio({required this.icona, required this.testo});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icona, size: 44, color: AppColors.muted),
            const SizedBox(height: 12),
            Text(
              testo,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.muted, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}
