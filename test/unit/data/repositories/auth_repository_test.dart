import 'package:bonbudget/data/datasources/database/schema.dart';
import 'package:bonbudget/data/repositories/auth_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fake_secure_storage.dart';
import '../../../helpers/in_memory_database.dart';

/// Tests fuer das neue Biometrie-Only-AuthRepository.
///
/// Es gibt kein Passwort mehr — die Methoden sind:
/// `isSetupComplete`, `completeSetup`, `getAuth`, `resetAccount`.
/// Echte Biometrie-Pruefung passiert ausserhalb des Repos
/// (im AuthNotifier, mit `BiometricService`).
void main() {
  group('AuthRepositoryImpl (Biometrie-Only)', () {
    late AuthRepositoryImpl repo;
    late FakeSecureStorageService storage;

    setUp(() async {
      final db = await openInMemoryTestDb();
      addTearDown(db.close);
      storage = FakeSecureStorageService();
      repo = AuthRepositoryImpl(db: db, storage: storage);
    });

    test('isSetupComplete = false bevor irgendetwas passiert', () async {
      expect(await repo.isSetupComplete(), isFalse);
    });

    test('completeSetup legt einen Auth-Datensatz und Setup-Marker an',
        () async {
      final auth = await repo.completeSetup();
      expect(auth.id, isNonZero);
      expect(await repo.isSetupComplete(), isTrue);
      expect(await storage.readSetupComplete(), isTrue);
    });

    test('completeSetup wirft, wenn schon gesetzt', () async {
      await repo.completeSetup();
      expect(repo.completeSetup, throwsA(isA<StateError>()));
    });

    test('getAuth liest den Datensatz nach Setup', () async {
      final created = await repo.completeSetup();
      final read = await repo.getAuth();
      expect(read, isNotNull);
      expect(read!.id, created.id);
      // Vergleich ueber millisecondsSinceEpoch, weil die Round-trip-
      // Persistenz nur Millisekunden-Praezision hat (DateTime.now()
      // hat aber Mikrosekunden).
      expect(
        read.createdAt.millisecondsSinceEpoch,
        created.createdAt.millisecondsSinceEpoch,
      );
    });

    test('getAuth gibt null wenn kein Datensatz existiert', () async {
      expect(await repo.getAuth(), isNull);
    });

    test('resetAccount loescht alle Tabellen und den Secure Storage',
        () async {
      // Setup + Beispieldaten anlegen
      await repo.completeSetup();
      // Kategorie-Zeile, damit wir was zum Loeschen haben
      final db = await openInMemoryTestDb();
      addTearDown(db.close);
      await db.insert(DbTables.categories, <String, Object?>{
        CategoryCols.id: 'c1',
        CategoryCols.name: 'X',
        CategoryCols.colorValue: 0,
        CategoryCols.iconCodePoint: 0xe000,
        CategoryCols.isDefault: 0,
        CategoryCols.isHidden: 0,
        CategoryCols.createdAt: 0,
      });

      await repo.resetAccount();

      expect(await repo.isSetupComplete(), isFalse);
      expect(await repo.getAuth(), isNull);
      expect(await storage.readSetupComplete(), isFalse);
      expect(await storage.readDbPassphrase(), isNull);
    });

    test('isSetupComplete pruft Marker UND DB-Zeile', () async {
      // Marker im Storage, aber keine Zeile in der DB → unvollstaendig.
      await storage.writeSetupComplete(complete: true);
      expect(await repo.isSetupComplete(), isFalse);
    });
  });
}
