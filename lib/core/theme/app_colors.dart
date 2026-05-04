import 'package:flutter/material.dart';

/// Farbpalette für BonBudget.
///
/// Primärfarbe ist ein modernes Mint-Grün. Aus dem Seed generiert
/// Material 3 (`ColorScheme.fromSeed`) automatisch eine harmonische
/// Palette für hellen und dunklen Modus.
///
/// Wenn du den Mint-Ton anpassen möchtest, ändere ausschließlich
/// [seedMint] – alle anderen Farben werden daraus abgeleitet.
class AppColors {
  AppColors._();

  /// Seed-Farbe für das Material-3-Theme. Mint-Teal.
  static const Color seedMint = Color(0xFF14B8A6);

  /// Akzentvarianten für eigene Diagramme.
  /// Bewusst nicht aus dem ColorScheme abgeleitet, damit Charts
  /// auch in beiden Themes konsistent aussehen.
  static const List<Color> chartPalette = <Color>[
    Color(0xFF14B8A6), // Mint
    Color(0xFF0EA5E9), // Sky
    Color(0xFF8B5CF6), // Violet
    Color(0xFFF59E0B), // Amber
    Color(0xFFEF4444), // Red
    Color(0xFF10B981), // Emerald
    Color(0xFFEC4899), // Pink
    Color(0xFF64748B), // Slate
  ];

  /// Statusfarben für Budget-Indikatoren.
  static const Color budgetOk = Color(0xFF10B981);
  static const Color budgetWarning = Color(0xFFF59E0B);
  static const Color budgetExceeded = Color(0xFFEF4444);
}
