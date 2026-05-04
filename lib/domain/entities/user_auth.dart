import 'package:flutter/foundation.dart';

/// Auth-Datensatz des einzigen lokalen Nutzers.
///
/// Markiert nur, dass das Setup abgeschlossen ist. Die eigentliche
/// Authentifizierung passiert ueber das Betriebssystem (Biometrie /
/// Geraete-PIN), das den Zugriff auf die im Secure Storage gebundene
/// DB-Passphrase autorisiert.
@immutable
class UserAuth {
  const UserAuth({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserAuth copyWith({DateTime? updatedAt}) {
    return UserAuth(
      id: id,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
