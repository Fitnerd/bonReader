import 'package:bonbudget/data/repositories/auth_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fake_password_hasher.dart';
import '../../../helpers/fake_secure_storage.dart';
import '../../../helpers/in_memory_database.dart';

/// Tests fuer das Zusammenspiel von DB, Secure Storage und Hasher.
/// Echtes Argon2 wird hier durch den [FakePasswordHasher] ersetzt –
/// die Crypto-Korrektheit wird auf Geraet via Integration-Test
/// abgedeckt.
void main() {
  group('AuthRepositoryImpl', () {
    late AuthRepositoryImpl repo;
    late FakeSecureStorageService storage;

    setUp(() async {
      final db = await openInMemoryTestDb();
      addTearDown(db.close);
      storage = FakeSecureStorageService();
      repo = AuthRepositoryImpl(
        db: db,
        storage: storage,
        hasher: FakePasswordHasher(),
      );
    });

    test('hasAccount false bevor Account angelegt wird', () async {
      expect(await repo.hasAccount(), isFalse);
    });

    test('createAccount legt Hash + Salt in Storage und DB ab', () async {
      await repo.createAccount('geheim123');
      expect(await repo.hasAccount(), isTrue);
      expect(await storage.readAuthHash(), isNotNull);
      expect(await storage.readAuthSalt(), isNotNull);

      final auth = await repo.getAuth();
      expect(auth, isNotNull);
      expect(auth!.passwordHash.isNotEmpty, isTrue);
      expect(auth.passwordSalt.isNotEmpty, isTrue);
    });

    test('createAccount weigert sich bei zu kurzem Passwort', () async {
      expect(
        () => repo.createAccount('1234'),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('createAccount weigert sich, wenn Account schon existiert', () async {
      await repo.createAccount('geheim123');
      expect(
        () => repo.createAccount('andereeingabe'),
        throwsA(isA<StateError>()),
      );
    });

    test('verifyPassword: korrekte Eingabe → true', () async {
      await repo.createAccount('geheim123');
      expect(await repo.verifyPassword('geheim123'), isTrue);
    });

    test('verifyPassword: falsche Eingabe → false', () async {
      await repo.createAccount('geheim123');
      expect(await repo.verifyPassword('falsch456'), isFalse);
    });

    test('verifyPassword: ohne Account → false (kein crash)', () async {
      expect(await repo.verifyPassword('egal'), isFalse);
    });

    test('changePassword aktualisiert Hash und Salt', () async {
      await repo.createAccount('alt12345');
      final oldHash = await storage.readAuthHash();

      await repo.changePassword(
        oldPassword: 'alt12345',
        newPassword: 'neu67890',
      );

      final newHash = await storage.readAuthHash();
      expect(newHash, isNot(oldHash));
      expect(await repo.verifyPassword('neu67890'), isTrue);
      expect(await repo.verifyPassword('alt12345'), isFalse);
    });

    test('changePassword schlaegt fehl bei falschem alten Passwort', () async {
      await repo.createAccount('alt12345');
      expect(
        () => repo.changePassword(
          oldPassword: 'falsch',
          newPassword: 'neu67890',
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('setBiometricEnabled persistiert Flag', () async {
      await repo.createAccount('geheim123');
      await repo.setBiometricEnabled(enabled: true);
      final auth = await repo.getAuth();
      expect(auth!.biometricEnabled, isTrue);
      expect(await storage.readBiometricEnabled(), isTrue);
    });

    test('resetAccount loescht alles bei korrektem Passwort', () async {
      await repo.createAccount('geheim123');
      await repo.resetAccount('geheim123');

      expect(await repo.hasAccount(), isFalse);
      expect(await storage.readAuthHash(), isNull);
    });

    test('resetAccount weigert sich bei falschem Passwort', () async {
      await repo.createAccount('geheim123');
      expect(
        () => repo.resetAccount('falsch'),
        throwsA(isA<StateError>()),
      );
      // Account ist noch da:
      expect(await repo.hasAccount(), isTrue);
    });
  });
}
