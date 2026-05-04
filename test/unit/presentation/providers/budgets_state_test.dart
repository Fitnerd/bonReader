import 'package:bonbudget/core/providers/data_providers.dart';
import 'package:bonbudget/data/repositories/budget_repository_impl.dart';
import 'package:bonbudget/data/repositories/category_repository_impl.dart';
import 'package:bonbudget/domain/repositories/budget_repository.dart';
import 'package:bonbudget/presentation/providers/budgets_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/in_memory_database.dart';

/// Tests fuer den BudgetsNotifier und die abgeleiteten Provider
/// (`totalBudgetCentsProvider`, `budgetByCategoryProvider`).
void main() {
  group('BudgetsNotifier', () {
    late ProviderContainer container;
    late BudgetRepositoryImpl repo;
    late String catId1;
    late String catId2;

    setUp(() async {
      final db = await openInMemoryTestDb();
      repo = BudgetRepositoryImpl(db);
      final catRepo = CategoryRepositoryImpl(db);
      addTearDown(db.close);

      final c1 = await catRepo.create(
        name: 'Lebensmittel', colorValue: 0xFF14B8A6, iconCodePoint: 0xe000,
      );
      final c2 = await catRepo.create(
        name: 'Tanken', colorValue: 0xFFEF4444, iconCodePoint: 0xe001,
      );
      catId1 = c1.id;
      catId2 = c2.id;

      container = ProviderContainer(overrides: <Override>[
        budgetRepositoryProvider.overrideWith(
          (_) async => repo as BudgetRepository,
        ),
      ]);
      addTearDown(container.dispose);
    });

    test('build liefert leere Liste, wenn keine Budgets gesetzt sind', () async {
      final budgets = await container.read(budgetsProvider.future);
      expect(budgets, isEmpty);
    });

    test('setForCategory legt Budget an und invalidiert State', () async {
      final notifier = container.read(budgetsProvider.notifier);
      await notifier.setForCategory(categoryId: catId1, amountCents: 30000);

      final budgets = await container.read(budgetsProvider.future);
      expect(budgets, hasLength(1));
      expect(budgets.first.amountCents, 30000);
    });

    test('setForCategory ueberschreibt vorhandenes Budget (nicht doppelt)',
        () async {
      final notifier = container.read(budgetsProvider.notifier);
      await notifier.setForCategory(categoryId: catId1, amountCents: 30000);
      await notifier.setForCategory(categoryId: catId1, amountCents: 50000);

      final budgets = await container.read(budgetsProvider.future);
      expect(budgets, hasLength(1));
      expect(budgets.first.amountCents, 50000);
    });

    test('remove loescht Budget', () async {
      final notifier = container.read(budgetsProvider.notifier);
      await notifier.setForCategory(categoryId: catId1, amountCents: 30000);
      await notifier.remove(catId1);

      final budgets = await container.read(budgetsProvider.future);
      expect(budgets, isEmpty);
    });

    test('totalBudgetCentsProvider summiert alle Kategorie-Budgets', () async {
      final notifier = container.read(budgetsProvider.notifier);
      await notifier.setForCategory(categoryId: catId1, amountCents: 30000);
      await notifier.setForCategory(categoryId: catId2, amountCents: 20000);

      // Provider auswerten (laedt vorher den AsyncProvider auf):
      await container.read(budgetsProvider.future);
      expect(container.read(totalBudgetCentsProvider), 50000);
    });

    test('budgetByCategoryProvider liefert null, wenn nichts gesetzt', () async {
      await container.read(budgetsProvider.future);
      expect(container.read(budgetByCategoryProvider(catId1)), isNull);
    });

    test('budgetByCategoryProvider liefert das gesetzte Budget', () async {
      final notifier = container.read(budgetsProvider.notifier);
      await notifier.setForCategory(categoryId: catId1, amountCents: 12345);
      await container.read(budgetsProvider.future);

      final b = container.read(budgetByCategoryProvider(catId1));
      expect(b, isNotNull);
      expect(b!.amountCents, 12345);
    });
  });
}
