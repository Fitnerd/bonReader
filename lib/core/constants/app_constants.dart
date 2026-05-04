/// Anwendungsweite Konstanten.
///
/// Magic Numbers / Strings sollen nirgends im Code auftauchen,
/// sondern hier zentral gepflegt werden.
class AppConstants {
  AppConstants._();

  /// App-Name (wird in der UI angezeigt).
  static const String appName = 'BonBudget';

  /// Default-Waehrung. Spaeter per Einstellungen aenderbar.
  static const String defaultCurrencyCode = 'EUR';
  static const String defaultLocale = 'de_DE';

  /// Auto-Logout nach Inaktivitaet (in Minuten). Spaeter konfigurierbar.
  static const int defaultAutoLogoutMinutes = 5;

  /// Erlaubter Bereich fuer Auto-Logout (in Minuten).
  static const int minAutoLogoutMinutes = 1;
  static const int maxAutoLogoutMinutes = 30;

  /// Argon2id-Parameter werden NUR noch fuer den Legacy-Migrations-Pfad
  /// gebraucht (alte Installationen, die noch ein App-Passwort hatten).
  /// In neuen Setups gibt es kein Passwort mehr; die DB-Passphrase wird
  /// durch das Betriebssystem (Biometrie / Geraete-PIN) freigegeben.
  static const int argon2Iterations = 3;
  static const int argon2MemoryKb = 65536; // 64 MB
  static const int argon2Parallelism = 4;
  static const int argon2HashLength = 32;
  static const int argon2SaltLength = 16;

  /// Schluessel fuer Secure Storage. NICHT die Werte selbst, nur die Keys.
  static const String secureKeyDbPassphrase = 'bonbudget.db.passphrase';

  /// Marker, dass das Biometrie-Setup abgeschlossen ist. Damit weiss die
  /// App beim Start, ob sie zum Setup-Screen oder zum Unlock-Screen muss,
  /// ohne die DB oeffnen zu muessen.
  static const String secureKeySetupComplete = 'bonbudget.setup.complete';

  /// Auto-Logout-Timeout (Minuten als String).
  static const String secureKeyAutoLogoutMin = 'bonbudget.auth.autologout.min';

  // ──────────────────────────────────────────────────────────────────
  // Legacy-Keys (nur Lesen / Loeschen waehrend Migration v3)
  // ──────────────────────────────────────────────────────────────────
  /// LEGACY: Argon2id-Hash des alten App-Passworts.
  static const String secureKeyAuthHash = 'bonbudget.auth.hash';

  /// LEGACY: Salt fuer den Argon2id-Hash.
  static const String secureKeyAuthSalt = 'bonbudget.auth.salt';

  /// LEGACY: Brute-Force- und Banking-72h-Reste, werden bei Migration
  /// und Reset einfach mit weggewischt.
  static const String secureKeyBiometricEnabled = 'bonbudget.auth.biometric';
  static const String secureKeyFailedAttempts = 'bonbudget.auth.failed_attempts';
  static const String secureKeyCooldownUntil = 'bonbudget.auth.cooldown_until';
  static const String secureKeyLastPasswordLogin =
      'bonbudget.auth.last_password_login';

  /// Datenbankname (wird im App-internen Documents-Ordner gespeichert).
  static const String databaseFileName = 'bonbudget.db';

  /// Datenbank-Versionierung.
  /// V1: initiales Schema.
  /// V2: expense_items.total_cents darf negativ sein (Pfand/Leergut).
  /// V3: Auth-Tabelle ohne Passwort-Hash (Biometrie-Only).
  /// V4: expense_items.quantity REAL → quantity_milli INTEGER
  ///     (IEEE-754-Rundungsfehler eliminieren).
  static const int databaseVersion = 4;

  /// Aufloesung des Quantity-Felds. 1000 = "ein Stueck".
  /// 1500 entspricht 1,5 Stueck / 1,5 kg / 1,5 l.
  static const int quantityMilliPerUnit = 1000;

  // ──────────────────────────────────────────────────────────────────
  // UI-Schwellenwerte (vorher als Magic Numbers ueber den Code verteilt)
  // ──────────────────────────────────────────────────────────────────

  /// Ab wann ein Budget-Balken als „kritisch ausgereizt" markiert wird
  /// (Anteil 0.0–1.0). Im Dashboard: Farbwechsel auf Warn-Farbe.
  static const double budgetWarningThreshold = 0.85;

  /// Plausibilitaets-Obergrenze fuer einzelne Bon-Positionen in Cent.
  /// Werte darueber werden vom Receipt-Parser verworfen, weil das fast
  /// immer ein OCR-Fehler ist (z. B. ein als Preis erkanntes Datum).
  static const int receiptParserMaxCents = 100000;
}
