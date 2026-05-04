import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/providers/auth_providers.dart';
import '../../core/providers/data_providers.dart';

/// Aktueller Anmelde-Status.
enum AuthStatus {
  /// Beim ersten Start – wir wissen noch nicht, ob ein Account existiert.
  unknown,

  /// Es gibt noch keinen Account → Registrierung anzeigen.
  noAccount,

  /// Account existiert, aber nicht eingeloggt.
  loggedOut,

  /// Login laeuft (z. B. Argon2-Hashing).
  authenticating,

  /// Eingeloggt.
  authenticated,
}

@immutable
class AuthState {
  const AuthState({
    required this.status,
    this.errorMessage,
    this.failedAttempts = 0,
    this.cooldownUntil,
  });

  final AuthStatus status;
  final String? errorMessage;
  final int failedAttempts;
  final DateTime? cooldownUntil;

  bool get inCooldown {
    final until = cooldownUntil;
    return until != null && until.isAfter(DateTime.now());
  }

  AuthState copyWith({
    AuthStatus? status,
    String? errorMessage,
    int? failedAttempts,
    DateTime? cooldownUntil,
    bool clearError = false,
    bool clearCooldown = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      failedAttempts: failedAttempts ?? this.failedAttempts,
      cooldownUntil:
          clearCooldown ? null : (cooldownUntil ?? this.cooldownUntil),
    );
  }
}

class AuthNotifier extends AsyncNotifier<AuthState> {
  @override
  Future<AuthState> build() async {
    final repo = await ref.watch(authRepositoryProvider.future);
    final has = await repo.hasAccount();

    // Persistierte Brute-Force-Daten laden.
    final storage = ref.read(secureStorageProvider);
    final attempts = await storage.readFailedAttempts();
    final cooldown = await storage.readCooldownUntil();

    return AuthState(
      status: has ? AuthStatus.loggedOut : AuthStatus.noAccount,
      failedAttempts: attempts,
      cooldownUntil: cooldown,
    );
  }

  Future<void> register(String password) async {
    state = const AsyncValue.data(AuthState(status: AuthStatus.authenticating));
    final repo = await ref.read(authRepositoryProvider.future);
    try {
      await repo.createAccount(password);
      state = const AsyncValue.data(
        AuthState(status: AuthStatus.authenticated),
      );
    } catch (e, st) {
      state = AsyncValue.data(AuthState(
        status: AuthStatus.noAccount,
        errorMessage: _humanize(e),
      ));
      // Stack trace wird nur intern geloggt, nicht im UI gezeigt.
      debugPrintStack(stackTrace: st, label: 'register');
    }
  }

  Future<bool> loginWithPassword(String password) async {
    final current = state.value ?? const AuthState(status: AuthStatus.loggedOut);
    if (current.inCooldown) {
      state = AsyncValue.data(current.copyWith(
        errorMessage:
            'Zu viele Fehlversuche. Bitte kurz warten.',
      ));
      return false;
    }

    state = AsyncValue.data(current.copyWith(
      status: AuthStatus.authenticating,
      clearError: true,
    ));

    final repo = await ref.read(authRepositoryProvider.future);
    final ok = await repo.verifyPassword(password);

    final storage = ref.read(secureStorageProvider);

    if (ok) {
      // Erfolgreicher Login → Zaehler zuruecksetzen + Zeitstempel merken.
      await storage.clearLoginAttempts();
      await storage.writeLastPasswordLogin(DateTime.now());
      state = const AsyncValue.data(
        AuthState(status: AuthStatus.authenticated),
      );
      return true;
    }

    final attempts = current.failedAttempts + 1;

    Duration? cooldownDuration;
    DateTime? cooldown;
    if (attempts >= AppConstants.maxLoginAttempts) {
      // Exponentielles Backoff: Berechne den Cooldown-Zyklus.
      // Zyklus 0 = erster Cooldown, Zyklus 1 = zweiter, usw.
      final cycle =
          (attempts ~/ AppConstants.maxLoginAttempts) - 1;
      final multipliers = AppConstants.cooldownMultipliers;
      final multiplier =
          multipliers[cycle.clamp(0, multipliers.length - 1)];
      cooldownDuration = AppConstants.loginCooldown * multiplier;
      cooldown = DateTime.now().add(cooldownDuration);
    }

    // Fehlversuche und Cooldown persistent speichern, damit ein App-Neustart
    // den Zaehler nicht zuruecksetzt.
    await storage.writeFailedAttempts(attempts);
    await storage.writeCooldownUntil(cooldown);

    state = AsyncValue.data(AuthState(
      status: AuthStatus.loggedOut,
      errorMessage: cooldown != null
          ? 'Zu viele Fehlversuche. ${cooldownDuration!.inMinutes} Min Pause.'
          : 'Falsches Passwort.',
      failedAttempts: attempts,
      cooldownUntil: cooldown,
    ));
    return false;
  }

  Future<bool> loginWithBiometric() async {
    final repo = await ref.read(authRepositoryProvider.future);
    final auth = await repo.getAuth();
    if (auth == null || !auth.biometricEnabled) return false;

    // Pruefen, ob seit dem letzten Passwort-Login mehr als 72h vergangen
    // sind. Wenn ja, muss das Passwort eingegeben werden (wie Banking-Apps).
    final storage = ref.read(secureStorageProvider);
    final lastPwLogin = await storage.readLastPasswordLogin();
    if (lastPwLogin != null) {
      final elapsed = DateTime.now().difference(lastPwLogin);
      if (elapsed > AppConstants.biometricPasswordRequiredAfter) {
        state = AsyncValue.data(
          (state.value ?? const AuthState(status: AuthStatus.loggedOut))
              .copyWith(
            errorMessage:
                'Aus Sicherheitsgruenden bitte Passwort eingeben '
                '(letzte Eingabe vor mehr als '
                '${AppConstants.biometricPasswordRequiredAfter.inHours}h).',
          ),
        );
        return false;
      }
    }

    final biometric = ref.read(biometricServiceProvider);
    final ok = await biometric.authenticate(
      localizedReason: 'Mit Biometrie anmelden',
    );
    if (ok) {
      // Erfolgreicher Login → Zaehler zuruecksetzen.
      await storage.clearLoginAttempts();
      state = const AsyncValue.data(
        AuthState(status: AuthStatus.authenticated),
      );
    }
    return ok;
  }

  void logout() {
    state = const AsyncValue.data(AuthState(status: AuthStatus.loggedOut));
  }

  Future<void> setBiometricEnabled({required bool enabled}) async {
    final repo = await ref.read(authRepositoryProvider.future);
    await repo.setBiometricEnabled(enabled: enabled);
  }

  String _humanize(Object e) {
    if (e is StateError) return e.message;
    if (e is ArgumentError) return e.message?.toString() ?? 'Ungueltige Eingabe';
    return 'Es ist ein Fehler aufgetreten.';
  }
}

final authStateProvider =
    AsyncNotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);
