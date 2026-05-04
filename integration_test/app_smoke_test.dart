import 'package:bonbudget/app.dart';
import 'package:bonbudget/core/constants/app_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// E2E Happy-Path. Laeuft auf echtem Geraet / Emulator.
///
/// Vorbedingung: Auf dem Geraet darf KEIN BonBudget-Account existieren.
/// (Falls doch, erst manuell deinstallieren oder den Account-Reset
/// ueber Einstellungen machen.)
///
/// Schritte:
/// 1. App starten → Splash → Setup-Screen.
/// 2. Setup mit Biometrie-Prompt durchlaufen (Tester muss am Geraet
///    den Prompt bestaetigen).
/// 3. Auf Dashboard, „Bon scannen"-FAB sichtbar.
/// 4. In Budgets navigieren, ein Budget setzen.
/// 5. Eine Ausgabe manuell erfassen.
/// 6. Auf Dashboard zurueck und pruefen, dass Restbudget-Anzeige passt.
///
/// Hinweis: Der Test loest echte Biometrie-Prompts aus. Auf dem CI
/// muss daher entweder ein Geraete-Profil mit aufgezeichneter
/// Biometrie-Antwort oder ein Override des `biometricServiceProvider`
/// genutzt werden.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
      'Happy Path: Setup → Budget setzen → Ausgabe → Dashboard',
      (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: BonBudgetApp()),
    );

    // Splash → Setup (weil noch kein Account existiert).
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // Falls schon ein Account existiert, koennen wir hier abbrechen –
    // die Annahme „leeres Geraet" ist Vorbedingung.
    expect(find.text('Willkommen bei ${AppConstants.appName}'),
        findsOneWidget);

    // Setup-Button antippen. Der echte Biometrie-Prompt muss am Geraet
    // bestaetigt werden – `pumpAndSettle` wartet auf die Antwort.
    await tester.tap(find.text('Mit Biometrie einrichten'));
    await tester.pumpAndSettle(const Duration(seconds: 10));

    // Jetzt sollten wir auf dem Dashboard sein.
    expect(find.text(AppConstants.appName), findsWidgets);
    expect(find.text('Bon scannen'), findsWidgets);

    // Drawer oeffnen, „Budgets" antippen.
    await tester.tap(find.byTooltip('Open navigation menu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Budgets').last);
    await tester.pumpAndSettle();

    // Erste Kategorie bekommt 100,00 € Budget.
    final budgetField = find.byType(TextField).first;
    await tester.enterText(budgetField, '100,00');
    await tester.tap(find.text('Budgets speichern'));
    await tester.pumpAndSettle(const Duration(seconds: 1));

    // Zurueck zum Dashboard.
    await tester.pageBack();
    await tester.pumpAndSettle();

    // Bon scannen wuerde Camera oeffnen – stattdessen erfassen wir manuell
    // ueber Drawer → Ausgaben → FAB „Neu".
    await tester.tap(find.byTooltip('Open navigation menu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ausgaben').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Neu'));
    await tester.pumpAndSettle();

    // Haendler + Betrag eingeben.
    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'Test-Markt');
    // Felder: 0=Haendler, 1=Gesamtbetrag (wenn keine Positionen)
    await tester.enterText(fields.at(1), '15,00');
    await tester.tap(find.text('Ausgabe anlegen'));
    await tester.pumpAndSettle(const Duration(seconds: 1));

    // Zurueck zum Dashboard pruefen wir, dass Restbudget = 85,00 ist
    // (oder zumindest nicht 100,00).
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.textContaining('85'), findsWidgets);
  }, skip: false);
}
