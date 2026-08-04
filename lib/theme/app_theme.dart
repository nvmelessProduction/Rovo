import 'package:flutter/material.dart';

/// Tema centrale di Rova: colori e tipografia in un unico posto.
/// Il design definitivo si rifinisce qui, senza toccare le schermate.
class AppColors {
  // Palette "toscana": vino Chianti, verde oliva, panna, antracite.
  static const Color chiantiRed = Color(0xFF7B2D3B); // primario
  static const Color oliveGreen = Color(0xFF6B7F4B); // accento
  static const Color cream = Color(0xFFF6F1E7); // sfondo
  static const Color sand = Color(0xFFEDE4D0); // superfici/card
  static const Color charcoal = Color(0xFF2E2A28); // testo
  static const Color muted = Color(0xFF8A8078); // testo secondario
  static const Color success = Color(0xFF3E7C4A); // prezzo più basso
  static const Color fuel = Color(0xFF2F6DB0); // marker carburante
}

class AppTheme {
  static ThemeData get light {
    final base = ThemeData.light(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.cream,
      colorScheme: base.colorScheme.copyWith(
        primary: AppColors.chiantiRed,
        secondary: AppColors.oliveGreen,
        surface: AppColors.cream,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.chiantiRed,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      textTheme: base.textTheme
          .copyWith(
            headlineSmall: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.charcoal,
            ),
            titleLarge: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.charcoal,
            ),
            titleMedium: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.charcoal,
            ),
            bodyLarge: const TextStyle(
              fontSize: 16,
              height: 1.5,
              color: AppColors.charcoal,
            ),
            bodyMedium: const TextStyle(
              fontSize: 14,
              height: 1.45,
              color: AppColors.charcoal,
            ),
            labelLarge: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          )
          .apply(bodyColor: AppColors.charcoal, displayColor: AppColors.charcoal),
      cardTheme: CardThemeData(
        color: AppColors.sand,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.chiantiRed,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.chiantiRed,
        unselectedItemColor: AppColors.muted,
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
      ),
    );
  }

  // Spaziature standard, per coerenza tra le schermate.
  static const double gap = 16;
  static const double radius = 16;
}
