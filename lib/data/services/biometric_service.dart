import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth/error_codes.dart' as auth_error;

/// Ergebnis der Biometrie-Authentifizierung.
///
/// Wir benutzen ein sealed-Result-Pattern statt boolean + Exceptions,
/// damit die Aufrufer die Faelle unterscheiden koennen, ohne den
/// generischen `catch (Object)` von vorher zu wiederholen.
sealed class BiometricResult {
  const BiometricResult();
}

class BiometricSuccess extends BiometricResult {
  const BiometricSuccess();
}

/// Nutzer hat den Prompt aktiv abgebrochen.
class BiometricCancelled extends BiometricResult {
  const BiometricCancelled();
}

/// Biometrie ist auf dem Geraet nicht verfuegbar oder nicht eingerichtet.
class BiometricNotAvailable extends BiometricResult {
  const BiometricNotAvailable(this.reason);
  final String reason;
}

/// OS hat Biometrie temporaer gesperrt (z. B. zu viele Fehlversuche).
class BiometricLockedOut extends BiometricResult {
  const BiometricLockedOut({required this.permanent});
  final bool permanent;
}

/// Etwas anderes ist schiefgelaufen. [code] ist der OS-Fehlercode,
/// falls vorhanden.
class BiometricFailure extends BiometricResult {
  const BiometricFailure({required this.code, this.message});
  final String code;
  final String? message;
}

/// Wrapper um `LocalAuthentication`. Abstrahiert von local_auth, damit
/// Tests den Service mocken koennen.
abstract class BiometricService {
  /// True, wenn das Geraet Biometrie unterstuetzt UND mindestens ein
  /// Verfahren eingerichtet ist.
  Future<bool> isAvailable();

  /// Loest die System-Auth-Abfrage aus.
  ///
  /// `localizedReason` wird dem Nutzer in der System-UI angezeigt.
  /// `biometricOnly` schaltet den Geraete-PIN-Fallback ab. Default
  /// ist `false`, damit der Nutzer bei Biometrie-Fehlschlag die
  /// Geraete-PIN nutzen kann.
  Future<BiometricResult> authenticate({
    required String localizedReason,
    bool biometricOnly = false,
  });
}

class LocalAuthBiometricService implements BiometricService {
  LocalAuthBiometricService([LocalAuthentication? auth])
      : _auth = auth ?? LocalAuthentication();

  final LocalAuthentication _auth;

  @override
  Future<bool> isAvailable() async {
    try {
      final supported = await _auth.isDeviceSupported();
      if (!supported) return false;
      final canCheck = await _auth.canCheckBiometrics;
      if (!canCheck) return false;
      final available = await _auth.getAvailableBiometrics();
      return available.isNotEmpty;
    } on PlatformException {
      // Auf einigen Geraeten wirft das, wenn Biometrie nicht eingerichtet
      // ist. Wir behandeln das als „nicht verfuegbar".
      return false;
    }
  }

  @override
  Future<BiometricResult> authenticate({
    required String localizedReason,
    bool biometricOnly = false,
  }) async {
    try {
      final ok = await _auth.authenticate(
        localizedReason: localizedReason,
        options: AuthenticationOptions(
          biometricOnly: biometricOnly,
          stickyAuth: true,
          useErrorDialogs: true,
        ),
      );
      return ok ? const BiometricSuccess() : const BiometricCancelled();
    } on PlatformException catch (e) {
      return _mapPlatformException(e);
    }
  }

  BiometricResult _mapPlatformException(PlatformException e) {
    switch (e.code) {
      case auth_error.notAvailable:
      case auth_error.notEnrolled:
        return BiometricNotAvailable(e.message ?? e.code);
      case auth_error.passcodeNotSet:
        return const BiometricNotAvailable(
          'Geraete-PIN ist nicht eingerichtet.',
        );
      case auth_error.lockedOut:
        return const BiometricLockedOut(permanent: false);
      case auth_error.permanentlyLockedOut:
        return const BiometricLockedOut(permanent: true);
      default:
        return BiometricFailure(code: e.code, message: e.message);
    }
  }
}
