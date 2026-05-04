import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/auth_repository_impl.dart';
import '../../data/services/biometric_service.dart';
import '../../data/services/password_hasher.dart';
import '../../domain/repositories/auth_repository.dart';
import 'data_providers.dart';

final passwordHasherProvider = Provider<PasswordHasher>((ref) {
  return const Argon2PasswordHasher();
});

final biometricServiceProvider = Provider<BiometricService>((ref) {
  return LocalAuthBiometricService();
});

final authRepositoryProvider = FutureProvider<AuthRepository>((ref) async {
  final db = await ref.watch(databaseProvider.future);
  final storage = ref.watch(secureStorageProvider);
  final hasher = ref.watch(passwordHasherProvider);
  return AuthRepositoryImpl(db: db, storage: storage, hasher: hasher);
});
