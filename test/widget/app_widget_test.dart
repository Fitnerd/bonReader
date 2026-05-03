import 'package:bonbudget/app.dart';
import 'package:bonbudget/core/constants/app_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Widget-Tests prüfen einzelne UI-Komponenten in Isolation.
/// Hier: die App startet ohne Crash und der Splash zeigt den App-Namen.
void main() {
  testWidgets('App startet und zeigt Splash mit App-Namen', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: BonBudgetApp()),
    );

    // Splash-Screen ist die initiale Route.
    expect(find.text(AppConstants.appName), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('App nutzt Material 3', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: BonBudgetApp()),
    );

    final BuildContext context = tester.element(find.byType(Scaffold).first);
    final ThemeData theme = Theme.of(context);
    expect(theme.useMaterial3, isTrue);
  });
}
