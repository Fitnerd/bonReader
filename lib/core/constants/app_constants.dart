/// Anwendungsweite Konstanten.
///
/// Magic Numbers / Strings sollen nirgends im Code auftauchen,
/// sondern hier zentral gepflegt werden.
class AppConstants {
  AppConstants._();

  /// App-Name (wird in der UI angezeigt).
  static const String appName = 'BonBudget';

  /// Default-Währung. Später per Einstellungen änderbar.
  static const String defaultCurrencyCode = 'EUR';
  static const String defaultLocale = 'de_DE';

  /// Auto-Logout nach Inaktivität (in Minuten). Später konfigurierbar.
  static const int defaultAutoLogoutMinutes = 5;

  /// Maximale Anzahl Login-Fehlversuche, bevor eine Pause erzwungen wird.
  static const int maxLoginAttempts = 5;

  /// Pause nach zu vielen Fehlversuchen.
  static const Duration loginCooldown = Duration(minutes: 1);

  /// Argon2id-Parameter (RFC 9106 empfiehlt mindestens diese Werte
  /// für interaktive Anmeldung auf mobilen Geräten).
  static const int argon2Iterations = 3;
  static const int argon2MemoryKb = 65536; // 64 MB
  static const int argon2Parallelism = 4;
  static const int argon2HashLength = 32;
  static const int argon2SaltLength = 16;

  /// Schlüssel für Secure Storage. NICHT die Werte selbst, nur die Keys.
  static const String secureKeyDbPassphrase = 'bonbudget.db.passphrase';
  static const String secureKeyAuthHash = 'bonbudget.auth.hash';
  static const String secureKeyAuthSalt = 'bonbudget.auth.salt';
  static const String secureKeyBiometricEnabled = 'bonbudget.auth.biometric';

  /// Datenbankname (wird im App-internen Documents-Ordner gespeichert).
  static const String databaseFileName = 'bonbudget.db';
  static const int databaseVersion = 1;
}
