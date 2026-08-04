import 'package:flutter/material.dart';

import '../data/seed.dart';
import '../models/fuel_station.dart';
import '../theme/app_theme.dart';

/// Schermata Carburante: lista dei distributori (mock in M1).
/// Il più economico per la benzina è evidenziato in alto.
class FuelScreen extends StatelessWidget {
  const FuelScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Ordina per prezzo benzina crescente: il primo è il più economico.
    final stations = [...fuelStationsMock]
      ..sort((a, b) => a.prezzoBenzina.compareTo(b.prezzoBenzina));
    final cheapestId = stations.first.id;

    return Scaffold(
      appBar: AppBar(title: const Text('Carburante')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: stations.length,
        separatorBuilder: (context, index) => const SizedBox(height: 10),
        itemBuilder: (context, i) => _FuelCard(
          station: stations[i],
          cheapest: stations[i].id == cheapestId,
        ),
      ),
    );
  }
}

class _FuelCard extends StatelessWidget {
  final FuelStation station;
  final bool cheapest;

  const _FuelCard({required this.station, required this.cheapest});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cheapest ? AppColors.success.withValues(alpha: 0.12) : AppColors.sand,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: cheapest ? AppColors.success : Colors.transparent,
          width: cheapest ? 2 : 0,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: cheapest ? AppColors.success : AppColors.fuel,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.local_gas_station, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        station.nome,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    if (cheapest)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.success,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'PIÙ ECONOMICO',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  station.indirizzo,
                  style: const TextStyle(color: AppColors.muted, fontSize: 13),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _PriceChip(
                      label: 'Benzina',
                      price: station.prezzoBenzina,
                      highlight: cheapest,
                    ),
                    const SizedBox(width: 10),
                    _PriceChip(
                      label: 'Gasolio',
                      price: station.prezzoGasolio,
                      highlight: false,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PriceChip extends StatelessWidget {
  final String label;
  final double price;
  final bool highlight;

  const _PriceChip({
    required this.label,
    required this.price,
    required this.highlight,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label ',
            style: const TextStyle(color: AppColors.muted, fontSize: 12),
          ),
          Text(
            '${price.toStringAsFixed(3)} €',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: highlight ? AppColors.success : AppColors.charcoal,
            ),
          ),
        ],
      ),
    );
  }
}
