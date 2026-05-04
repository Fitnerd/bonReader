import 'package:bonbudget/data/services/biometric_service.dart';

/// Konfigurierbarer Doppelgaenger fuer [BiometricService].
///
/// Tests koennen [available], [nextResult] und [authCallCount] nutzen,
/// um Biometrie-Verhalten zu simulieren ohne echtes local_auth.
class FakeBiometricService implements BiometricService {
  FakeBiometricService({
    this.available = true,
    BiometricResult? nextResult,
  }) : _nextResult = nextResult ?? const BiometricSuccess();

  bool available;
  BiometricResult _nextResult;
  int authCallCount = 0;
  int isAvailableCallCount = 0;
  String? lastReason;
  bool? lastBiometricOnly;

  /// Setzt das Ergebnis fuer den naechsten [authenticate]-Aufruf.
  void setNextResult(BiometricResult result) {
    _nextResult = result;
  }

  @override
  Future<bool> isAvailable() async {
    isAvailableCallCount++;
    return available;
  }

  @override
  Future<BiometricResult> authenticate({
    required String localizedReason,
    bool biometricOnly = false,
  }) async {
    authCallCount++;
    lastReason = localizedReason;
    lastBiometricOnly = biometricOnly;
    return _nextResult;
  }
}
