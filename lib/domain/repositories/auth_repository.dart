import '../entities/user_auth.dart';

/// Vertrag fuer Auth-Operationen. Implementierung in `data/`.
///
/// Biometrie-Only-Modell: kein App-Passwort. Zugriff auf die DB wird
/// durch das Betriebssystem autorisiert (Biometrie / Geraete-PIN), das
/// die DB-Passphrase aus dem Secure Storage freigibt.
abstract class AuthRepository {
  /// True, wenn das Setup bereits durchgelaufen ist.
  Future<bool> isSetupComplete();

  /// Schliesst das initiale Setup ab und legt den Auth-Datensatz an.
  /// Wirft [StateError], wenn schon gesetzt ist.
  Future<UserAuth> completeSetup();

  /// Liest den Auth-Datensatz (oder null wenn keiner existiert).
  Future<UserAuth?> getAuth();

  /// Loescht den Account und alle damit verbundenen Daten.
  ///
  /// Komplett-Wipe: Tabellen, Secure-Storage-Eintraege, DB-Passphrase.
  /// Anschliessend startet die App wieder mit Setup.
  Future<void> resetAccount();
}
