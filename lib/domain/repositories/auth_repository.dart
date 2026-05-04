import '../entities/user_auth.dart';

/// Vertrag fuer Auth-Operationen. Implementierung in `data/`.
///
/// Trennt Domain von konkreter Speicherung (Argon2 + Secure Storage)
/// damit Tests die Logik ohne echte Crypto-/Storage-Abhaengigkeit
/// pruefen koennen.
abstract class AuthRepository {
  /// True, wenn schon ein Account existiert.
  Future<bool> hasAccount();

  /// Legt einen neuen Account an. Nur erlaubt, wenn noch keiner existiert.
  /// Wirft [StateError], wenn bereits ein Account vorhanden ist.
  Future<UserAuth> createAccount(String password);

  /// Prueft das Passwort. Gibt true zurueck, wenn korrekt.
  /// Verwendet konstantzeitigen Vergleich.
  Future<bool> verifyPassword(String password);

  /// Liest den Auth-Datensatz (oder null wenn keiner existiert).
  Future<UserAuth?> getAuth();

  /// Setzt das Biometrie-Flag.
  Future<void> setBiometricEnabled({required bool enabled});

  /// Aendert das Passwort. Verlangt das alte Passwort zur Verifikation.
  /// Wirft [StateError], wenn das alte Passwort falsch ist.
  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  });

  /// Loescht den Account und alle damit verbundenen Daten.
  /// Erfordert Bestaetigung durch das aktuelle Passwort.
  Future<void> resetAccount(String password);
}
