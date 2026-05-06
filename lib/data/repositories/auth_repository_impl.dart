import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

import '../../core/constants/app_constants.dart';
import '../../domain/entities/user_auth.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/database/schema.dart';
import '../datasources/secure_storage_service.dart';

/// Resolver fuer die SQLCipher-Datei der App. Existiert ausschliesslich
/// als Konstruktor-Hook, damit Unit-Tests, die mit einer In-Memory-DB
/// laufen, beim Reset keinen path_provider-Channel brauchen — sie
/// uebergeben einfach `() async => null`.
typedef DatabaseFileResolver = Future<File?> Function();

Future<File?> _defaultDatabaseFileResolver() async {
  final dir = await getApplicationDocumentsDirectory();
  return File(p.join(dir.path, AppConstants.databaseFileName));
}

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
    DatabaseFileResolver? databaseFileResolver,
  })  : _db = db,
        _storage = storage,
        _databaseFileResolver =
            databaseFileResolver ?? _defaultDatabaseFileResolver;

  final Database _db;
  final SecureStorageService _storage;
  final DatabaseFileResolver _databaseFileResolver;

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
    // 1. DB schliessen, damit das Filehandle frei ist und Schritt 3 die
    //    Datei tatsaechlich loeschen kann. `appDatabaseProvider` haelt
    //    dieselbe `Database`-Instanz; sein `onDispose(db.close)` ist
    //    nach `ref.invalidate(...)` durch den `db.isOpen`-Check
    //    idempotent.
    if (_db.isOpen) {
      await _db.close();
    }
    // 2. Secure Storage zuerst wipen — Setup-Marker und DB-Passphrase
    //    sind weg, bevor die DB-Datei geloescht wird. Stirbt der Prozess
    //    hier dazwischen, fuehrt der naechste Start sauber durchs Setup;
    //    die alte (mit alter Passphrase verschluesselte) Datei kann nicht
    //    mehr fuer „setup ist ja schon durch" gehalten werden.
    await _storage.wipeAll();
    // 3. DB-Datei vom Disk loeschen. Best-effort: bei Fehlern hier hat
    //    Schritt 2 bereits den Setup-Marker entfernt; der naechste
    //    Setup-Flow generiert eine neue Passphrase und der Anwender ist
    //    nicht im "App ist gebricked"-Zustand.
    try {
      final file = await _databaseFileResolver();
      if (file != null && await file.exists()) {
        await file.delete();
      }
    } catch (_) {
      // bewusst geschluckt: Reset-UI hat schon das Wichtigste erledigt.
    }
  }
}
