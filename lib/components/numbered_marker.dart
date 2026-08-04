import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Marker toccabile di una tappa, con il numero al centro.
/// Se [selected] è true viene evidenziato (più grande, verde).
class NumberedMarker extends StatelessWidget {
  final int numero;
  final bool selected;
  final VoidCallback onTap;

  const NumberedMarker({
    super.key,
    required this.numero,
    required this.onTap,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.oliveGreen : AppColors.chiantiRed;
    final size = selected ? 42.0 : 34.0;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: const [
            BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
          ],
        ),
        child: Text(
          '$numero',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: selected ? 18 : 15,
          ),
        ),
      ),
    );
  }
}
