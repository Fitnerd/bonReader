import 'package:local_auth/local_auth.dart';

/// Wrapper um `LocalAuthentication`. Abstrahiert von local_auth, damit
/// Tests den Service mocken koennen.
abstract class BiometricService {
  /// True, wenn das Geraet Biometrie unterstuetzt UND mindestens ein
  /// Verfahren eingerichtet ist.
  Future<bool> isAvailable();

  /// Loest die Biometrie-Abfrage aus. Gibt true bei Erfolg zurueck.
  /// `localizedReason` wird dem Nutzer in der System-UI angezeigt.
  Future<bool> authenticate({required String localizedReason});
}

class LocalAuthBiometricService implements BiometricService {
  LocalAuthBiometricService([LocalAuthentication? auth])
      : _auth = auth ?? LocalAuthentication();

  final LocalAuthentication _auth;

  @override
  Future<bool> isAvailable() async {
    try {
      final canCheck = await _auth.canCheckBiometrics;
      final supported = await _auth.isDeviceSupported();
      if (!canCheck || !supported) return false;
      final available = await _auth.getAvailableBiometrics();
      return available.isNotEmpty;
    } on Object {
      // Auf einigen Geraeten wirft das, wenn Biometrie nicht eingerichtet
      // ist. Wir behandeln das als „nicht verfuegbar".
      return false;
    }
  }

  @override
  Future<bool> authenticate({required String localizedReason}) async {
    try {
      return await _auth.authenticate(
        localizedReason: localizedReason,
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
          useErrorDialogs: true,
        ),
      );
    } on Object {
      return false;
    }
  }
}
