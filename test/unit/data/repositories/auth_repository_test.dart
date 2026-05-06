import 'dart:io';

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
      repo = AuthRepositoryImpl(
        db: db,
        storage: storage,
        // In-Memory-DB hat keine Datei auf Disk — Resolver gibt null
        // zurueck, damit `resetAccount()` keinen path_provider-Channel
        // braucht (waere im Flutter-Test ohne Stub eine MissingPlugin-
        // Exception).
        databaseFileResolver: () async => null,
      );
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

    test('resetAccount schliesst DB, wiped Secure Storage und ruft den '
        'File-Resolver auf', () async {
      // Setup-Marker und DB-Passphrase setzen, damit wir nach dem Wipe
      // sauber pruefen koennen, dass beides geloescht wurde.
      await repo.completeSetup();
      await storage.writeDbPassphrase('test-passphrase');

      // Eigenen Resolver injizieren, um sicherzustellen, dass `resetAccount`
      // ihn aufruft (das ist die Stelle, an der in Production die DB-Datei
      // vom Disk verschwindet).
      var resolverCalled = 0;
      final repoWithResolver = AuthRepositoryImpl(
        db: await openInMemoryTestDb(),
        storage: storage,
        databaseFileResolver: () async {
          resolverCalled += 1;
          return null;
        },
      );

      await repoWithResolver.resetAccount();

      // Nach Reset: Storage komplett leer.
      expect(await storage.readSetupComplete(), isFalse);
      expect(await storage.readDbPassphrase(), isNull);
      // Der File-Resolver wurde genau einmal aufgerufen (= Production-Pfad
      // wuerde die DB-Datei loeschen).
      expect(resolverCalled, 1);
    });

    test('resetAccount schluckt Fehler aus dem File-Resolver', () async {
      // Production-Verhalten: wenn path_provider in irgendeiner Form
      // schief geht (z. B. Berechtigung), darf der Reset trotzdem nicht
      // werfen — der Storage-Wipe ist die zentrale Sicherheitsmassnahme.
      await repo.completeSetup();

      final repoWithFailingResolver = AuthRepositoryImpl(
        db: await openInMemoryTestDb(),
        storage: storage,
        databaseFileResolver: () async {
          throw const FileSystemException('boom');
        },
      );

      await expectLater(repoWithFailingResolver.resetAccount(), completes);
      expect(await storage.readSetupComplete(), isFalse);
    });

    test('isSetupComplete pruft Marker UND DB-Zeile', () async {
      // Marker im Storage, aber keine Zeile in der DB → unvollstaendig.
      await storage.writeSetupComplete(complete: true);
      expect(await repo.isSetupComplete(), isFalse);
    });
  });
}
