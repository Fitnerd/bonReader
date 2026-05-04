import 'package:bonbudget/app.dart';
import 'package:bonbudget/core/constants/app_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// E2E: Bestehender Account → Reset-Account-Flow im Unlock-Screen.
///
/// Vorbedingung: Auf dem Geraet existiert ein BonBudget-Account
/// (mindestens einmal Setup durchlaufen). Falls nicht, wird der Test
/// nur das Setup-Screen sehen und korrekt skippen.
///
/// Schritte:
/// 1. App starten → entweder Unlock oder Setup.
/// 2. Bei Unlock-Screen: Reset-Button antippen → Bestaetigungs-Dialog.
/// 3. Loeschen bestaetigen → App geht zurueck auf Setup-Screen.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Unlock → Reset-Dialog → Bestaetigen → Setup-Screen',
      (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: BonBudgetApp()),
    );
    await tester.pumpAndSettle(const Duration(seconds: 2));

    final unlockBtn = find.text('Entsperren');
    if (unlockBtn.evaluate().isEmpty) {
      // Kein Account vorhanden → Test ist no-op.
      // Wir markieren das nicht als skip, damit ein "leeres Geraet"
      // nicht still falsch positiv wird; stattdessen pruefen wir den
      // Setup-Screen explizit.
      expect(
        find.text('Willkommen bei ${AppConstants.appName}'),
        findsOneWidget,
        reason: 'Auf einem leeren Geraet erwarten wir den Setup-Screen.',
      );
      return;
    }

    // Reset-Button antippen.
    await tester.tap(find.text('Account zuruecksetzen'));
    await tester.pumpAndSettle();

    // Bestaetigungs-Dialog erscheint.
    expect(find.text('Wirklich zuruecksetzen?'), findsOneWidget);
    expect(find.text('Loeschen'), findsOneWidget);

    // Bestaetigen.
    await tester.tap(find.text('Loeschen'));
    await tester.pumpAndSettle(const Duration(seconds: 5));

    // Nach Reset: Setup-Screen.
    expect(
      find.text('Willkommen bei ${AppConstants.appName}'),
      findsOneWidget,
    );
  });
}
