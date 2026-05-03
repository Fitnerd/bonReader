import 'package:bonbudget/app.dart';
import 'package:bonbudget/core/constants/app_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// E2E-Smoke-Test: läuft auf einem echten Gerät / Emulator.
/// Prüft, dass die initiale Route geladen wird und der Übergang
/// Splash → Login klappt. Wird in späteren Schritten erweitert
/// (Login → Home → Ausgabe erfassen → Budget aktualisiert).
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Splash leitet automatisch zum Login weiter', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: BonBudgetApp()),
    );

    // Direkt nach Start sehen wir den Splash.
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // Die Weiterleitung im Splash ist auf 300 ms gesetzt.
    await tester.pumpAndSettle(const Duration(seconds: 1));

    // Jetzt sollten wir auf dem Login-Platzhalter sein.
    expect(find.text('Willkommen bei ${AppConstants.appName}'), findsOneWidget);
    expect(find.text('Weiter (Platzhalter)'), findsOneWidget);
  });

  testWidgets('Login-Platzhalter führt zur Home-Seite', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: BonBudgetApp()),
    );

    await tester.pumpAndSettle(const Duration(seconds: 1));

    await tester.tap(find.text('Weiter (Platzhalter)'));
    await tester.pumpAndSettle();

    // Home zeigt den AppBar-Titel mit dem App-Namen.
    expect(find.text(AppConstants.appName), findsWidgets);
    expect(find.text('Restbudget diesen Monat'), findsOneWidget);
  });
}
