import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Marker toccabile di un distributore di carburante.
/// Se [cheapest] è true viene evidenziato in verde (prezzo più basso).
class FuelMarker extends StatelessWidget {
  final bool cheapest;
  final VoidCallback onTap;

  const FuelMarker({
    super.key,
    required this.onTap,
    this.cheapest = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = cheapest ? AppColors.success : AppColors.fuel;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: const [
            BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
          ],
        ),
        child: const Icon(
          Icons.local_gas_station,
          color: Colors.white,
          size: 18,
        ),
      ),
    );
  }
}
