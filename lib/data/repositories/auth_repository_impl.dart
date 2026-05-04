import 'package:sqflite_sqlcipher/sqflite.dart';

import '../../domain/entities/user_auth.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/database/schema.dart';
import '../datasources/secure_storage_service.dart';

/// Auth-Repository-Implementierung im Biometrie-Only-Modell.
///
/// Es gibt kein App-Passwort mehr. „Setup" bedeutet nur, dass die
/// DB-Passphrase im Secure Storage liegt und die `auth`-Tabelle einen
/// Marker-Datensatz hat. Die eigentliche Authentifizierung passiert
/// ueber das Betriebssystem (Biometrie / Geraete-PIN), das den Zugriff
/// auf die Passphrase im Secure Storage autorisiert.
class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required Database db,
    required SecureStorageService storage,
  })  : _db = db,
        _storage = storage;

  final Database _db;
  final SecureStorageService _storage;

  @override
  Future<bool> isSetupComplete() async {
    if (!await _storage.readSetupComplete()) return false;
    // Defence-in-Depth: Marker im Secure Storage UND ein Datensatz in
    // der DB. Falls eines fehlt, ist das Setup unvollstaendig.
    final rows = await _db.query(DbTables.auth, limit: 1);
    return rows.isNotEmpty;
  }

  @override
  Future<UserAuth> completeSetup() async {
    final existing = await _db.query(DbTables.auth, limit: 1);
    if (existing.isNotEmpty) {
      throw StateError('Setup ist bereits abgeschlossen.');
    }
    final now = DateTime.now();
    final id = await _db.insert(DbTables.auth, <String, Object?>{
      AuthCols.createdAt: now.millisecondsSinceEpoch,
      AuthCols.updatedAt: now.millisecondsSinceEpoch,
    });
    await _storage.writeSetupComplete(complete: true);

    return UserAuth(
      id: id,
      createdAt: now,
      updatedAt: now,
    );
  }

  @override
  Future<UserAuth?> getAuth() async {
    final rows = await _db.query(DbTables.auth, limit: 1);
    if (rows.isEmpty) return null;
    final row = rows.first;
    final id = row[AuthCols.id];
    final createdAt = row[AuthCols.createdAt];
    final updatedAt = row[AuthCols.updatedAt];
    if (id is! int || createdAt is! int || updatedAt is! int) {
      // DB-Zeile existiert, ist aber unerwartet defekt: lieber null
      // statt Crash. Das Setup wird dann erneut angeboten.
      return null;
    }
    return UserAuth(
      id: id,
      createdAt: DateTime.fromMillisecondsSinceEpoch(createdAt),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(updatedAt),
    );
  }

  @override
  Future<void> resetAccount() async {
    // Alle Daten in einer Transaktion loeschen, damit bei einem Crash
    // dazwischen kein inkonsistenter Zwischenzustand zurueckbleibt.
    await _db.transaction((txn) async {
      await txn.delete(DbTables.expenseItems);
      await txn.delete(DbTables.expenses);
      await txn.delete(DbTables.budgets);
      await txn.delete(DbTables.categories);
      await txn.delete(DbTables.auth);
    });
    // Secure Storage komplett leeren - inklusive DB-Passphrase, sodass
    // beim naechsten Start eine neue erzeugt wird.
    await _storage.wipeAll();
  }
}
