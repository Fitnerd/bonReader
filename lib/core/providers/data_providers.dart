import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

import '../../data/datasources/database/app_database.dart';
import '../../data/datasources/database/database_passphrase_service.dart';
import '../../data/datasources/secure_storage_service.dart';
import '../../data/repositories/budget_repository_impl.dart';
import '../../data/repositories/category_repository_impl.dart';
import '../../data/repositories/expense_repository_impl.dart';
import '../../domain/repositories/budget_repository.dart';
import '../../domain/repositories/category_repository.dart';
import '../../domain/repositories/expense_repository.dart';

/// Riverpod-Provider-Tree fuer die Daten-Schicht.
///
/// In Tests werden einzelne Provider per `overrideWith` ersetzt,
/// damit der echte SQLCipher / Secure Storage nicht hochgefahren wird.

final secureStorageProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService();
});

final databasePassphraseProvider = Provider<DatabasePassphraseService>((ref) {
  return DatabasePassphraseService(ref.watch(secureStorageProvider));
});

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase(ref.watch(databasePassphraseProvider));
  ref.onDispose(db.close);
  return db;
});

/// Async-Provider, der die DB oeffnet UND die Default-Kategorien seedet.
/// Muss von allen Repositories abgewartet werden.
final databaseProvider = FutureProvider<Database>((ref) async {
  final appDb = ref.watch(appDatabaseProvider);
  final db = await appDb.open();
  // Default-Kategorien beim ersten Start seeden:
  final tempCategoryRepo = CategoryRepositoryImpl(db);
  await tempCategoryRepo.seedDefaultsIfNeeded();
  return db;
});

final categoryRepositoryProvider = FutureProvider<CategoryRepository>((ref) async {
  final db = await ref.watch(databaseProvider.future);
  return CategoryRepositoryImpl(db);
});

final budgetRepositoryProvider = FutureProvider<BudgetRepository>((ref) async {
  final db = await ref.watch(databaseProvider.future);
  return BudgetRepositoryImpl(db);
});

final expenseRepositoryProvider = FutureProvider<ExpenseRepository>((ref) async {
  final db = await ref.watch(databaseProvider.future);
  return ExpenseRepositoryImpl(db);
});
