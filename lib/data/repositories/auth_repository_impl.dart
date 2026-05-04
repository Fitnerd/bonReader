import 'package:sqflite_sqlcipher/sqflite.dart';

import '../../core/utils/password_validator.dart';
import '../../domain/entities/user_auth.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/database/schema.dart';
import '../datasources/secure_storage_service.dart';
import '../services/password_hasher.dart';

/// Auth-Repository-Implementierung.
///
/// Hash + Salt werden **doppelt** abgelegt: in der verschluesselten
/// DB (damit alles an einem Ort beim Wipe ist) UND im Secure Storage
/// (damit der Login funktioniert, ohne dass die DB geoeffnet werden
/// muss – die DB-Passphrase liegt eh schon dort).
///
/// Bei Konflikten gilt der Secure-Storage-Wert als Wahrheit –
/// gefuehlt selten relevant, weil wir an beiden Stellen gleichzeitig
/// schreiben.
class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required Database db,
    required SecureStorageService storage,
    required PasswordHasher hasher,
  })  : _db = db,
        _storage = storage,
        _hasher = hasher;

  final Database _db;
  final SecureStorageService _storage;
  final PasswordHasher _hasher;

  @override
  Future<bool> hasAccount() async {
    final hash = await _storage.readAuthHash();
    return hash != null && hash.isNotEmpty;
  }

  @override
  Future<UserAuth> createAccount(String password) async {
    if (await hasAccount()) {
      throw StateError('Account existiert bereits.');
    }
    final validation = PasswordValidator.validate(password);
    if (!validation.isValid) {
      throw ArgumentError.value(
        password.length,
        'password',
        validation.errorMessage ?? 'Passwort erfuellt nicht die Anforderungen',
      );
    }

    final hashed = await _hasher.hashNew(password);
    final now = DateTime.now();

    final id = await _db.insert(DbTables.auth, <String, Object?>{
      AuthCols.passwordHash: hashed.hashBase64,
      AuthCols.passwordSalt: hashed.saltBase64,
      AuthCols.biometricEnabled: 0,
      AuthCols.createdAt: now.millisecondsSinceEpoch,
      AuthCols.updatedAt: now.millisecondsSinceEpoch,
    });

    await _storage.writeAuthHash(hashed.hashBase64);
    await _storage.writeAuthSalt(hashed.saltBase64);
    await _storage.writeBiometricEnabled(enabled: false);

    return UserAuth(
      id: id,
      passwordHash: hashed.hashBase64,
      passwordSalt: hashed.saltBase64,
      biometricEnabled: false,
      createdAt: now,
      updatedAt: now,
    );
  }

  @override
  Future<bool> verifyPassword(String password) async {
    final hash = await _storage.readAuthHash();
    final salt = await _storage.readAuthSalt();
    if (hash == null || salt == null) return false;
    return _hasher.verify(
      password: password,
      storedHashBase64: hash,
      storedSaltBase64: salt,
    );
  }

  @override
  Future<UserAuth?> getAuth() async {
    final rows = await _db.query(DbTables.auth, limit: 1);
    if (rows.isEmpty) return null;
    final row = rows.first;
    return UserAuth(
      id: row[AuthCols.id]! as int,
      passwordHash: row[AuthCols.passwordHash]! as String,
      passwordSalt: row[AuthCols.passwordSalt]! as String,
      biometricEnabled: (row[AuthCols.biometricEnabled]! as int) == 1,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        row[AuthCols.createdAt]! as int,
      ),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
        row[AuthCols.updatedAt]! as int,
      ),
    );
  }

  @override
  Future<void> setBiometricEnabled({required bool enabled}) async {
    await _db.update(
      DbTables.auth,
      <String, Object?>{
        AuthCols.biometricEnabled: enabled ? 1 : 0,
        AuthCols.updatedAt: DateTime.now().millisecondsSinceEpoch,
      },
    );
    await _storage.writeBiometricEnabled(enabled: enabled);
  }

  @override
  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    final ok = await verifyPassword(oldPassword);
    if (!ok) {
      throw StateError('Altes Passwort ist falsch.');
    }
    final validation = PasswordValidator.validate(newPassword);
    if (!validation.isValid) {
      throw ArgumentError.value(
        newPassword.length,
        'newPassword',
        validation.errorMessage ?? 'Passwort erfuellt nicht die Anforderungen',
      );
    }
    final hashed = await _hasher.hashNew(newPassword);
    final now = DateTime.now();

    await _db.update(
      DbTables.auth,
      <String, Object?>{
        AuthCols.passwordHash: hashed.hashBase64,
        AuthCols.passwordSalt: hashed.saltBase64,
        AuthCols.updatedAt: now.millisecondsSinceEpoch,
      },
    );
    await _storage.writeAuthHash(hashed.hashBase64);
    await _storage.writeAuthSalt(hashed.saltBase64);
  }

  @override
  Future<void> resetAccount(String password) async {
    final ok = await verifyPassword(password);
    if (!ok) {
      throw StateError('Passwort falsch – Reset verweigert.');
    }
    // Reihenfolge: erst DB-Inhalte, dann Secure Storage.
    await _db.delete(DbTables.expenseItems);
    await _db.delete(DbTables.expenses);
    await _db.delete(DbTables.budgets);
    await _db.delete(DbTables.categories);
    await _db.delete(DbTables.auth);
    await _storage.wipeAll();
  }
}
