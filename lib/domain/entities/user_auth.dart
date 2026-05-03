/// Auth-Datensatz des einzigen lokalen Nutzers.
///
/// Hält den Argon2id-Hash + Salt und ein Flag, ob Biometrie aktiv ist.
/// Liegt in der DB-Tabelle `auth`. Es gibt immer höchstens einen Datensatz.
class UserAuth {
  const UserAuth({
    required this.id,
    required this.passwordHash,
    required this.passwordSalt,
    required this.biometricEnabled,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final String passwordHash; // Base64-kodierter Argon2id-Hash
  final String passwordSalt; // Base64-kodierter Salt
  final bool biometricEnabled;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserAuth copyWith({
    String? passwordHash,
    String? passwordSalt,
    bool? biometricEnabled,
    DateTime? updatedAt,
  }) {
    return UserAuth(
      id: id,
      passwordHash: passwordHash ?? this.passwordHash,
      passwordSalt: passwordSalt ?? this.passwordSalt,
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
