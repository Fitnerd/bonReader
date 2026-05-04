import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

import '../../../core/constants/app_constants.dart';
import 'database_passphrase_service.dart';
import 'migrations.dart';

// Compile-Time-Sicherung: Wenn jemand `databaseVersion` hochzieht ohne
// eine neue `_v...`-Migration anzulegen (oder umgekehrt), schlaegt das
// hier sofort an und nicht erst zur Laufzeit auf Geraeten.
const _kDbVersionMatchesMigrations =
    AppConstants.databaseVersion == _migrationsLatestVersionAtCompile;
const _migrationsLatestVersionAtCompile = 4;
// ignore: unused_element
void _assertDbVersionInSync() {
  assert(
    _kDbVersionMatchesMigrations &&
        AppConstants.databaseVersion == Migrations.latestVersion,
    'AppConstants.databaseVersion (${AppConstants.databaseVersion}) muss zu '
    'Migrations.latestVersion (${Migrations.latestVersion}) passen.',
  );
}

/// Oeffnet die verschluesselte SQLite-Datenbank.
///
/// Verwendet SQLCipher (AES-256 page-level). Die Passphrase kommt
/// aus dem [DatabasePassphraseService] und wird **nie** aus dem
/// Nutzerpasswort abgeleitet (siehe Kommentar dort).
///
/// Foreign-Keys werden explizit aktiviert (`PRAGMA foreign_keys = ON;`),
/// damit `ON DELETE CASCADE` greift.
class AppDatabase {
  AppDatabase(this._passphraseService);

  final DatabasePassphraseService _passphraseService;
  Database? _db;

  Future<Database> open() async {
    _assertDbVersionInSync();
    final existing = _db;
    if (existing != null && existing.isOpen) return existing;

    final dir = await getApplicationDocumentsDirectory();
    final path = p.join(dir.path, AppConstants.databaseFileName);
    final passphrase = await _passphraseService.getOrCreate();

    final db = await openDatabase(
      path,
      password: passphrase,
      version: AppConstants.databaseVersion,
      onCreate: Migrations.onCreate,
      onUpgrade: Migrations.onUpgrade,
      onConfigure: (Database db) async {
        await db.execute('PRAGMA foreign_keys = ON;');
      },
    );

    _db = db;
    return db;
  }

  Future<void> close() async {
    final db = _db;
    if (db != null && db.isOpen) {
      await db.close();
    }
    _db = null;
  }
}
