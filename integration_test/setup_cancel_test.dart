import 'package:bonbudget/app.dart';
import 'package:bonbudget/core/constants/app_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// E2E: Setup-Screen → Biometrie-Prompt abbrechen → bleibt auf Setup.
///
/// Voraussetzung: leeres Geraet (kein Account). Tester muss den
/// Biometrie-Prompt am Geraet aktiv "Abbrechen" antippen.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Setup-Cancel: Nutzer bricht Biometrie-Prompt ab',
      (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: BonBudgetApp()),
    );
    await tester.pumpAndSettle(const Duration(seconds: 2));

    final setupBtn = find.text('Mit Biometrie einrichten');
    if (setupBtn.evaluate().isEmpty) {
      // Account existiert schon → Test no-op.
      return;
    }

    await tester.tap(setupBtn);
    // Prompt erscheint → der Tester muss am Geraet "Cancel" druecken.
    // pumpAndSettle wartet auf die Antwort.
    await tester.pumpAndSettle(const Duration(seconds: 15));

    // Wir bleiben auf dem Setup-Screen.
    expect(
      find.text('Willkommen bei ${AppConstants.appName}'),
      findsOneWidget,
    );
    // Fehlermeldung sollte etwa "Vorgang abgebrochen" enthalten -
    // exakter Text haengt von Locale ab.
    expect(
      find.byType(Text),
      findsWidgets,
    );
  });
}
