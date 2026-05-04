import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/auth_providers.dart';
import '../../core/providers/data_providers.dart';
import '../../data/services/biometric_service.dart';

/// Aktueller Anmelde-Status.
enum AuthStatus {
  /// Beim ersten Start - wir wissen noch nicht, ob ein Account existiert.
  unknown,

  /// Es gibt noch keinen Account → Setup-Screen anzeigen.
  needsSetup,

  /// Eine alte Installation (Argon2-Passwort) existiert. Der Nutzer muss
  /// einmal das Passwort eingeben, dann stellen wir auf Biometrie um.
  needsLegacyMigration,

  /// Account existiert, App ist gesperrt → Unlock-Screen anzeigen.
  locked,

  /// Biometrie-Prompt laeuft.
  unlocking,

  /// Eingeloggt - Home-Bereich freigeschaltet.
  unlocked,
}

@immutable
class AuthState {
  const AuthState({
    required this.status,
    this.errorMessage,
  });

  final AuthStatus status;
  final String? errorMessage;

  AuthState copyWith({
    AuthStatus? status,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class AuthNotifier extends AsyncNotifier<AuthState> {
  @override
  Future<AuthState> build() async {
    final storage = ref.read(secureStorageProvider);

    // Legacy erkennen: alter Argon2-Hash liegt noch im Secure Storage.
    final legacyHash = await storage.readAuthHash();
    if (legacyHash != null && legacyHash.isNotEmpty) {
      return const AuthState(status: AuthStatus.needsLegacyMigration);
    }

    final setupDone = await storage.readSetupComplete();
    return AuthState(
      status: setupDone ? AuthStatus.locked : AuthStatus.needsSetup,
    );
  }

  /// Erst-Einrichtung. Loest Biometrie-Prompt aus, oeffnet die DB
  /// (was beim ersten Mal die Passphrase generiert) und legt den
  /// Auth-Marker in der DB an.
  Future<void> setup() async {
    state = const AsyncValue.data(AuthState(status: AuthStatus.unlocking));
    final biometric = ref.read(biometricServiceProvider);
    final result = await biometric.authenticate(
      localizedReason: 'BonBudget einrichten',
    );
    if (result is! BiometricSuccess) {
      state = AsyncValue.data(AuthState(
        status: AuthStatus.needsSetup,
        errorMessage: _humanizeBiometric(result),
      ));
      return;
    }
    try {
      final repo = await ref.read(authRepositoryProvider.future);
      // Doppelte Sicherheit: falls in der DB bereits ein Auth-Eintrag
      // existiert (z. B. nach unsauberem Abbruch), nicht neu anlegen.
      if (!await repo.isSetupComplete()) {
        await repo.completeSetup();
      }
      state = const AsyncValue.data(AuthState(status: AuthStatus.unlocked));
    } catch (e, st) {
      debugPrintStack(stackTrace: st, label: 'auth.setup');
      state = const AsyncValue.data(AuthState(
        status: AuthStatus.needsSetup,
        errorMessage: 'Einrichtung fehlgeschlagen.',
      ));
    }
  }

  /// App entsperren. Loest Biometrie-Prompt aus.
  Future<void> unlock() async {
    state = const AsyncValue.data(AuthState(status: AuthStatus.unlocking));
    final biometric = ref.read(biometricServiceProvider);
    final result = await biometric.authenticate(
      localizedReason: 'BonBudget entsperren',
    );
    if (result is! BiometricSuccess) {
      state = AsyncValue.data(AuthState(
        status: AuthStatus.locked,
        errorMessage: _humanizeBiometric(result),
      ));
      return;
    }
    try {
      // DB triggern (oeffnet sich, Default-Kategorien werden geseedet).
      await ref.read(databaseProvider.future);
      state = const AsyncValue.data(AuthState(status: AuthStatus.unlocked));
    } catch (e, st) {
      debugPrintStack(stackTrace: st, label: 'auth.unlock');
      state = const AsyncValue.data(AuthState(
        status: AuthStatus.locked,
        errorMessage: 'Entsperren fehlgeschlagen.',
      ));
    }
  }

  /// Migration aus dem alten Passwort-Modell. Verlangt einmal das alte
  /// Passwort, oeffnet die DB damit (Schema-Migration v3 laeuft mit),
  /// loescht die Legacy-Eintraege und stellt auf Biometrie-Only um.
  Future<bool> migrateFromLegacy(String oldPassword) async {
    state = const AsyncValue.data(
      AuthState(status: AuthStatus.unlocking),
    );

    final storage = ref.read(secureStorageProvider);
    final hash = await storage.readAuthHash();
    final salt = await storage.readAuthSalt();
    if (hash == null || salt == null) {
      // Sollte nicht passieren - der Pfad wird nur betreten, wenn der
      // Hash existiert. Aber Robustheit kostet nichts.
      state = const AsyncValue.data(
        AuthState(status: AuthStatus.needsSetup),
      );
      return false;
    }

    final verifier = ref.read(legacyPasswordVerifierProvider);
    final ok = await verifier.verify(
      password: oldPassword,
      storedHashBase64: hash,
      storedSaltBase64: salt,
    );
    if (!ok) {
      state = const AsyncValue.data(AuthState(
        status: AuthStatus.needsLegacyMigration,
        errorMessage: 'Passwort falsch.',
      ));
      return false;
    }

    // Biometrie absichern, bevor wir migrieren - sonst stellen wir
    // sehenden Auges auf eine Methode um, die der Nutzer nicht hat.
    final biometric = ref.read(biometricServiceProvider);
    if (!await biometric.isAvailable()) {
      state = const AsyncValue.data(AuthState(
        status: AuthStatus.needsLegacyMigration,
        errorMessage:
            'Auf diesem Geraet ist keine Biometrie eingerichtet. '
            'Bitte zuerst einrichten.',
      ));
      return false;
    }
    final bioResult = await biometric.authenticate(
      localizedReason: 'Auf Biometrie umstellen',
    );
    if (bioResult is! BiometricSuccess) {
      state = AsyncValue.data(AuthState(
        status: AuthStatus.needsLegacyMigration,
        errorMessage: _humanizeBiometric(bioResult),
      ));
      return false;
    }

    try {
      // DB oeffnen → laesst Schema-Migration auf v3 laufen.
      await ref.read(databaseProvider.future);
      // Legacy-Eintraege wegraeumen.
      await storage.deleteLegacyAuth();
      // Setup-Marker setzen, damit beim naechsten Start direkt
      // der Unlock-Flow greift.
      await storage.writeSetupComplete(complete: true);
      state = const AsyncValue.data(AuthState(status: AuthStatus.unlocked));
      return true;
    } catch (e, st) {
      debugPrintStack(stackTrace: st, label: 'auth.migrate');
      state = const AsyncValue.data(AuthState(
        status: AuthStatus.needsLegacyMigration,
        errorMessage: 'Migration fehlgeschlagen.',
      ));
      return false;
    }
  }

  void logout() {
    state = const AsyncValue.data(AuthState(status: AuthStatus.locked));
  }

  /// Komplett-Wipe. Danach steht der User wieder am Anfang.
  Future<void> resetAccount() async {
    try {
      final repo = await ref.read(authRepositoryProvider.future);
      await repo.resetAccount();
    } catch (e, st) {
      debugPrintStack(stackTrace: st, label: 'auth.reset');
    }
    // Nach Wipe muss der ganze Provider-Tree (DB!) neu aufgebaut werden.
    ref.invalidate(databaseProvider);
    ref.invalidate(appDatabaseProvider);
    state = const AsyncValue.data(AuthState(status: AuthStatus.needsSetup));
  }

  String _humanizeBiometric(BiometricResult r) {
    return switch (r) {
      BiometricCancelled() => 'Vorgang abgebrochen.',
      BiometricNotAvailable(reason: final reason) =>
        'Biometrie nicht verfuegbar: $reason',
      BiometricLockedOut(permanent: final permanent) => permanent
          ? 'Biometrie ist dauerhaft gesperrt. '
              'Bitte ueber die Geraete-Einstellungen freischalten.'
          : 'Biometrie ist temporaer gesperrt. Bitte spaeter erneut versuchen.',
      BiometricFailure() => 'Biometrie-Fehler.',
      BiometricSuccess() => '',
    };
  }
}

final authStateProvider =
    AsyncNotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);
