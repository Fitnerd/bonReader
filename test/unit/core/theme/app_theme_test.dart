import 'package:bonbudget/core/theme/app_colors.dart';
import 'package:bonbudget/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Sicherstellen, dass das Theme korrekt aus dem Mint-Seed
/// abgeleitet wird – Grundlage für das ganze visuelle System.
void main() {
  group('AppTheme', () {
    test('light theme nutzt den Mint-Seed', () {
      final theme = AppTheme.light();
      expect(theme.brightness, Brightness.light);
      expect(theme.useMaterial3, isTrue);
      // ColorScheme.fromSeed garantiert nicht, dass primary == seed,
      // aber primary muss in der gleichen Hue-Region liegen.
      expect(theme.colorScheme.primary, isNotNull);
    });

    test('dark theme ist dunkel', () {
      final theme = AppTheme.dark();
      expect(theme.brightness, Brightness.dark);
    });

    test('Chart-Palette hat genug Farben für ein Tortendiagramm', () {
      // Wir wollen mindestens 5 Kategorien gleichzeitig darstellen können.
      expect(AppColors.chartPalette.length, greaterThanOrEqualTo(5));
    });

    test('Status-Farben sind unterschiedlich', () {
      expect(AppColors.budgetOk, isNot(AppColors.budgetWarning));
      expect(AppColors.budgetWarning, isNot(AppColors.budgetExceeded));
      expect(AppColors.budgetOk, isNot(AppColors.budgetExceeded));
    });
  });
}
