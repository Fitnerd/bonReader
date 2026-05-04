import 'package:bonbudget/data/services/biometric_service.dart';
import 'package:bonbudget/presentation/screens/auth/setup_screen.dart';
import 'package:bonbudget/presentation/screens/auth/unlock_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bonbudget/core/providers/auth_providers.dart';

import '../helpers/fake_biometric_service.dart';

/// Pflanzt einen [FakeBiometricService] in den Provider-Tree, sodass
/// die Screens ohne echtes local_auth getestet werden koennen.
ProviderScope _withFakeBiometric(
  Widget child,
  FakeBiometricService biometric,
) {
  return ProviderScope(
    overrides: <Override>[
      biometricServiceProvider.overrideWithValue(biometric),
    ],
    child: MaterialApp(
      localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('de'),
      home: child,
    ),
  );
}

void main() {
  group('SetupScreen', () {
    testWidgets('zeigt den Einrichten-Button bei verfuegbarer Biometrie',
        (tester) async {
      final fake = FakeBiometricService(available: true);
      await tester.pumpWidget(_withFakeBiometric(const SetupScreen(), fake));
      // Initialer FutureBuilder fuer isAvailable() laeuft.
      await tester.pump();

      expect(find.text('Mit Biometrie einrichten'), findsOneWidget);
      expect(find.byIcon(Icons.fingerprint_rounded), findsAtLeastNWidgets(1));
    });

    testWidgets('zeigt Hinweis wenn Biometrie nicht verfuegbar',
        (tester) async {
      final fake = FakeBiometricService(available: false);
      await tester.pumpWidget(_withFakeBiometric(const SetupScreen(), fake));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(
        find.textContaining('keine Biometrie eingerichtet'),
        findsOneWidget,
      );
    });

    testWidgets('Einrichten-Button ist disabled solange isAvailable laeuft',
        (tester) async {
      final fake = FakeBiometricService(available: true);
      await tester.pumpWidget(_withFakeBiometric(const SetupScreen(), fake));
      // Noch kein pump() -> isAvailable() noch nicht aufgeloest.
      final button = tester.widget<FilledButton>(
        find.byType(FilledButton).first,
      );
      expect(button.onPressed, isNull);
    });
  });

  group('UnlockScreen', () {
    testWidgets('zeigt Entsperren-Button und Reset-Option', (tester) async {
      final fake = FakeBiometricService(
        available: true,
        nextResult: const BiometricCancelled(),
      );
      await tester.pumpWidget(_withFakeBiometric(const UnlockScreen(), fake));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('Entsperren'), findsOneWidget);
      expect(find.text('Account zuruecksetzen'), findsOneWidget);
    });

    testWidgets('Reset-Dialog erscheint und kann abgebrochen werden',
        (tester) async {
      final fake = FakeBiometricService(
        available: true,
        nextResult: const BiometricCancelled(),
      );
      await tester.pumpWidget(_withFakeBiometric(const UnlockScreen(), fake));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      await tester.tap(find.text('Account zuruecksetzen'));
      await tester.pumpAndSettle();

      expect(find.text('Wirklich zuruecksetzen?'), findsOneWidget);
      expect(find.text('Abbrechen'), findsOneWidget);

      await tester.tap(find.text('Abbrechen'));
      await tester.pumpAndSettle();

      // Dialog ist weg
      expect(find.text('Wirklich zuruecksetzen?'), findsNothing);
    });
  });
}
