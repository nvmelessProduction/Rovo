import 'package:flutter/material.dart';

import '../models/route_step.dart';

/// Freccia che rappresenta graficamente la manovra da eseguire.
class ManeuverIcon extends StatelessWidget {
  final RouteStep? step;
  final double size;
  final Color color;

  const ManeuverIcon({
    super.key,
    required this.step,
    this.size = 44,
    this.color = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Icon(_icona, size: size, color: color);
  }

  IconData get _icona {
    final s = step;
    if (s == null) return Icons.straight;
    if (s.isArrivo) return Icons.flag;

    switch (s.tipo) {
      case 'depart':
        return Icons.navigation;
      case 'roundabout':
      case 'rotary':
      case 'roundabout turn':
        return Icons.roundabout_right;
      case 'merge':
        return Icons.merge;
      case 'on ramp':
      case 'off ramp':
        return s.modificatore == 'left' || s.modificatore == 'slight left'
            ? Icons.ramp_left
            : Icons.ramp_right;
      case 'fork':
        return s.modificatore != null && s.modificatore!.contains('left')
            ? Icons.fork_left
            : Icons.fork_right;
    }

    switch (s.modificatore) {
      case 'right':
        return Icons.turn_right;
      case 'left':
        return Icons.turn_left;
      case 'slight right':
        return Icons.turn_slight_right;
      case 'slight left':
        return Icons.turn_slight_left;
      case 'sharp right':
        return Icons.turn_sharp_right;
      case 'sharp left':
        return Icons.turn_sharp_left;
      case 'uturn':
        return Icons.u_turn_left;
      default:
        return Icons.straight;
    }
  }
}
