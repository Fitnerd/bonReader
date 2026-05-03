import 'package:bonbudget/data/datasources/database/migrations.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Test-Helper: In-Memory SQLite mit Migrationen.
///
/// Nutzt `sqflite_common_ffi`, damit Tests auf dem Host (Linux/Mac/Win)
/// laufen, ohne Geraet/Emulator. Die echte App nutzt `sqflite_sqlcipher`
/// mit Verschluesselung – fuer Tests irrelevant, das Schema ist gleich.
///
/// `Database` aus `sqflite_common_ffi` und aus `sqflite_sqlcipher`
/// teilen sich denselben Basistyp (`sqflite_common`), die Repositories
/// koennen also mit beiden arbeiten.
///
/// Verwendung:
/// ```dart
/// setUp(() async => db = await openInMemoryTestDb());
/// tearDown(() async => db.close());
/// ```
Future<Database> openInMemoryTestDb() async {
  sqfliteFfiInit();
  final factory = databaseFactoryFfi;
  return factory.openDatabase(
    inMemoryDatabasePath,
    options: OpenDatabaseOptions(
      version: Migrations.latestVersion,
      onCreate: Migrations.onCreate,
      onUpgrade: Migrations.onUpgrade,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON;');
      },
    ),
  );
}
