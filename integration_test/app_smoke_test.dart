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
/// 1. App starten → Splash → Register-Screen.
/// 2. Account anlegen mit „testpasswort1".
/// 3. Auf Dashboard, „Bon scannen"-FAB sichtbar.
/// 4. In Budgets navigieren, ein Budget setzen.
/// 5. Eine Ausgabe manuell erfassen.
/// 6. Auf Dashboard zurueck und pruefen, dass Restbudget-Anzeige passt.
///
/// Hinweis: Der Test nutzt das echte Argon2 (auf dem Geraet ist das OK),
/// die echte SQLCipher-DB und Secure Storage. Daher MUESSEN diese
/// Tests am Ende den Account zuruecksetzen, sonst startet der naechste
/// Lauf von einem bestehenden Account aus.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Happy Path: Register → Budget setzen → Ausgabe → Dashboard',
      (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: BonBudgetApp()),
    );

    // Splash → Register (weil noch kein Account existiert).
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // Falls schon ein Account existiert, koennen wir hier abbrechen –
    // die Annahme „leeres Geraet" ist Vorbedingung.
    expect(find.text('Willkommen bei ${AppConstants.appName}'), findsOneWidget);

    // Passwort eingeben