import 'package:bonbudget/core/providers/data_providers.dart';
import 'package:bonbudget/data/repositories/category_repository_impl.dart';
import 'package:bonbudget/data/repositories/expense_repository_impl.dart';
import 'package:bonbudget/domain/repositories/expense_repository.dart';
import 'package:bonbudget/presentation/providers/expenses_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/in_memory_database.dart';

/// Tests fuer den ExpensesNotifier und die abgeleiteten Monats-Provider.
void main() {
  group('ExpensesNotifier + Monats-Provider', () {
    late ProviderContainer container;
    late ExpenseRepositoryImpl repo;
    late String catFood;
    late String catFuel;

    setUp(() async {
      final db = await openInMemoryTestDb();
      repo = ExpenseRepositoryImpl(db);
      final catRepo = CategoryRepositoryImpl(db);
      addTearDown(db.close);

      final c1 = await catRepo.create(
        name: 'Lebensmittel', colorValue: 0xFF14B8A6, iconCodePoint: 0xe000,
      );
      final c2 = await catRepo.create(
        name: 'Tanken', colorValue: 0xFFEF4444, iconCodePoint: 0xe001,
      );
      catFood = c1.id;
      catFuel = c2.id;

      container = ProviderContainer(overrides: <Override>[
        expenseRepositoryProvider.overrideWith((_) async => repo),
      ]);
      addTearDown(container.dispose);
    });

    test('build liefert leere Liste, wenn keine Ausgaben existieren', () async {
      final list = await container.read(expensesProvider.future);
      expect(list, isEmpty);
    });

    test('addExpense legt Ausgabe an und invalidiert State', () async {
      final notifier = container.read(expensesProvider.notifier);
      final draft = ExpenseDraft(
        categoryId: catFood,
        totalCents: 1599,
        merchant: 'Rewe',
        occurredAt: DateTime(2026, 5, 3),
      );
      await notifier.addExpense(draft);

      final list = await container.read(expensesProvider.future);
      expect(list, hasLength(1));
      expect(list.first.merchant, 'Rewe');
      expect(list.first.totalCents, 1599);
    });

    test('addExpense mit Positionen persistiert items', () async {
      final notifier = container.read(expensesProvider.notifier);
      final draft = ExpenseDraft(
        categoryId: catFood,
        totalCents: 350,
        merchant: 'Aldi',
        occurredAt: DateTime(2026, 5, 3),
        items: <ExpenseItemDraft>[
          ExpenseItemDraft(name: 'Brot', totalCents: 199, unitPriceCents: 199),
          ExpenseItemDraft(name: 'Milch', totalCents: 151, unitPriceCents: 151),
        ],
      );
      await notifier.addExpense(draft);

      final list = await container.read(expensesProvider.future);
      expect(list.first.items, hasLength(2));
      expect(list.first.items.map((i) => i.name), containsAll(['Brot', 'Milch']));
    });

    test('updateExpense aendert Felder', () async {
      final notifier = container.read(expensesProvider.notifier);
      final created = await notifier.addExpense(ExpenseDraft(
        categoryId: catFood,
        totalCents: 500,
        merchant: 'X',
        occurredAt: DateTime(2026, 5, 3),
      ));
      await notifier.updateExpense(
        created.copyWith(merchant: 'Edeka', totalCents: 800),
      );

      final list = await container.read(expensesProvider.future);
      expect(list.first.merchant, 'Edeka');
      expect(list.first.totalCents, 800);
    });

    test('deleteExpense loescht Ausgabe', () async {
      final notifier = container.read(expensesProvider.notifier);
      final created = await notifier.addExpense(ExpenseDraft(
        categoryId: catFood,
        totalCents: 500,
        merchant: 'X',
        occurredAt: DateTime(2026, 5, 3),
      ));
      await notifier.deleteExpense(created.id);

      final list = await container.read(expensesProvider.future);
      expect(list, isEmpty);
    });

    test('expensesInSelectedRangeProvider filtert nach Monatsgrenze', () async {
      final notifier = container.read(expensesProvider.notifier);
      // Mai 2026
      await notifier.addExpense(ExpenseDraft(
        categoryId: catFood,
        totalCents: 1000,
        merchant: 'Mai',
        occurredAt: DateTime(2026, 5, 15),
      ));
      // April 2026 (letzter Tag)
      await notifier.addExpense(ExpenseDraft(
        categoryId: catFood,
        totalCents: 2000,
        merchant: 'April',
        occurredAt: DateTime(2026, 4, 30, 23, 59),
      ));
      // Juni 2026 (erster Tag)
      await notifier.addExpense(ExpenseDraft(
        categoryId: catFood,
        totalCents: 3000,
        merchant: 'Juni',
        occurredAt: DateTime(2026, 6, 1, 0, 0),
      ));

      // Mai auswaehlen
      container.read(selectedDateRangeProvider.notifier).state =
          DateRange.calendarMonth(DateTime(2026, 5));
      await container.read(expensesProvider.future);

      final mai = container.read(expensesInSelectedRangeProvider);
      expect(mai, hasLength(1));
      expect(mai.first.merchant, 'Mai');

      expect(container.read(totalSpentInSelectedRangeProvider), 1000);
    });

    test('spentByCategoryInSelectedRangeProvider summiert pro Kategorie',
        () async {
      final notifier = container.read(expensesProvider.notifier);
      await notifier.addExpense(ExpenseDraft(
        categoryId: catFood,
        totalCents: 1500,
        merchant: 'Rewe',
        occurredAt: DateTime(2026, 5, 5),
      ));
      await notifier.addExpense(ExpenseDraft(
        categoryId: catFood,
        totalCents: 2500,
        merchant: 'Aldi',
        occurredAt: DateTime(2026, 5, 10),
      ));
      await notifier.addExpense(ExpenseDraft(
        categoryId: catFuel,
        totalCents: 6500,
        merchant: 'Aral',
        occurredAt: DateTime(2026, 5, 12),
      ));

      container.read(selectedDateRangeProvider.notifier).state =
          DateRange.calendarMonth(DateTime(2026, 5));
      await container.read(expensesProvider.future);

      final byCat = container.read(spentByCategoryInSelectedRangeProvider);
      expect(byCat[catFood], 4000);
      expect(byCat[catFuel], 6500);
    });
  });
}
