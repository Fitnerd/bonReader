import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/auth_repository_impl.dart';
import '../../data/services/biometric_service.dart';
import '../../data/services/legacy_password_verifier.dart';
import '../../domain/repositories/auth_repository.dart';
import 'data_providers.dart';

final biometricServiceProvider = Provider<BiometricService>((ref) {
  return LocalAuthBiometricService();
});

/// Wird nur fuer den einmaligen Migrations-Flow aus dem Legacy-Passwort
/// gebraucht. Nach Migration kann der Provider und die zugehoerige
/// Klasse entfernt werden.
final legacyPasswordVerifierProvider = Provider<LegacyPasswordVerifier>((ref) {
  return const LegacyPasswordVerifier();
});

final authRepositoryProvider = FutureProvider<AuthRepository>((ref) async {
  final db = await ref.watch(databaseProvider.future);
  final storage = ref.watch(secureStorageProvider);
  return AuthRepositoryImpl(db: db, storage: storage);
});
