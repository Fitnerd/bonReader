/// Ergebnis einer Passwort-Validierung.
class PasswordValidation {
  const PasswordValidation({
    required this.isValid,
    required this.hasMinLength,
    required this.hasLetter,
    required this.hasDigit,
    this.errorMessage,
  });

  final bool isValid;
  final bool hasMinLength;
  final bool hasLetter;
  final bool hasDigit;
  final String? errorMessage;

  /// Gibt die Staerke als Wert zwischen 0.0 und 1.0 zurueck.
  double get strength {
    if (!hasMinLength) return 0.0;
    var score = 0.0;
    if (hasMinLength) score += 0.34;
    if (hasLetter) score += 0.33;
    if (hasDigit) score += 0.33;
    return score.clamp(0.0, 1.0);
  }
}

/// Validiert ein Passwort gegen die App-Regeln.
///
/// Anforderungen:
/// - Mindestens 8 Zeichen
/// - Mindestens 1 Buchstabe (a-z oder A-Z)
/// - Mindestens 1 Ziffer (0-9)
class PasswordValidator {
  const PasswordValidator._();

  static const int minLength = 8;

  static PasswordValidation validate(String password) {
    final hasMinLength = password.length >= minLength;
    final hasLetter = RegExp(r'[a-zA-ZäöüÄÖÜß]').hasMatch(password);
    final hasDigit = RegExp(r'\d').hasMatch(password);

    final isValid = hasMinLength && hasLetter && hasDigit;

    String? error;
    if (!hasMinLength) {
      error = 'Mindestens $minLength Zeichen erforderlich.';
    } else if (!hasLetter) {
      error = 'Mindestens 1 Buchstabe erforderlich.';
    } else if (!hasDigit) {
      error = 'Mindestens 1 Ziffer erforderlich.';
    }

    return PasswordValidation(
      isValid: isValid,
      hasMinLength: hasMinLength,
      hasLetter: hasLetter,
      hasDigit: hasDigit,
      errorMessage: error,
    );
  }
}
