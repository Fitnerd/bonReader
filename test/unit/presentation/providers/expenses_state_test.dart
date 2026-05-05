import 'package:bonbudget/core/providers/data_providers.dart';
import 'package:bonbudget/data/repositories/category_repository_impl.dart';
import 'package:bonbudget/data/repositories/expense_repository_impl.dart';
import 'package:bonbudget/domain/repositories/expense_repository.dart';
import 'package:bonbudget/presentation/providers/expenses_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/in_memory_database.dart';

/// Tests fuer den ExpensesNotifier, den PagedExpensesNotifier und die
/// abgeleiteten Aggregat-Provider.
///
/// Pagination-Migration: `expensesProvider` ist nur noch ein Versions-
/// Counter (Notifier<int>), die eigentlichen Daten kommen ueber den
/// `pagedExpensesProvider` und die Repo-Aggregat-Provider.
void main() {
  group('ExpensesNotifier + Pagination + Range-Aggregate', () {
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

      // Reproduzierbare Range fuer Aggregat-Tests.
      container.read(selectedDateRangeProvider.notifier).state =
          DateRange.calendarMonth(DateTime(2026, 5));
    });

    test('paged build liefert leere Liste, wenn keine Ausgaben existieren',
        () async {
      final paged = await container.read(pagedExpensesProvider.future);
      expect(paged.items, isEmpty);
      expect(paged.total, 0);
      expect(paged.hasMore, isFalse);
      expect(paged.loadingMore, isFalse);
    });

    test('addExpense legt Ausgabe an und invalidiert paged-State', () async {
      // Erstkonsum, damit der Provider initialisiert ist.
      await container.read(pagedExpensesProvider.future);

      final notifier = container.read(expensesProvider.notifier);
      final draft = ExpenseDraft(
        categoryId: catFood,
        totalCents: 1599,
        merchant: 'Rewe',
        occurredAt: DateTime(2026, 5, 3),
      );
      await notifier.addExpense(draft);

      // Versions-Counter wurde inkrementiert.
      expect(container.read(expensesProvider), 1);

      final paged = await container.read(pagedExpensesProvider.future);
      expect(paged.items, hasLength(1));
      expect(paged.items.first.merchant, 'Rewe');
      expect(paged.items.first.totalCents, 1599);
      expect(paged.total, 1);
    });

    test('addExpense mit Positionen persistiert items', () async {
      final notifier = container.read(expensesProvider.notifier);
      final draft = ExpenseDraft(
        categoryId: catFood,
        totalCents: 350,
        merchant: 'Aldi',
        occurredAt: DateTime(2026, 5, 3),
        items: const <ExpenseItemDraft>[
          ExpenseItemDraft(name: 'Brot', totalCents: 199, unitPriceCents: 199),
          ExpenseItemDraft(name: 'Milch', totalCents: 151, unitPriceCents: 151),
        ],
      );
      await notifier.addExpense(draft);

      final paged = await container.read(pagedExpensesProvider.future);
      expect(paged.items.first.items, hasLength(2));
      expect(
        paged.items.first.items.map((i) => i.name),
        containsAll(<String>['Brot', 'Milch']),
      );
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

      final paged = await container.read(pagedExpensesProvider.future);
      expect(paged.items.first.merchant, 'Edeka');
      expect(paged.items.first.totalCents, 800);
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

      final paged = await container.read(pagedExpensesProvider.future);
      expect(paged.items, isEmpty);
      expect(paged.total, 0);
    });

    test('pagedExpensesProvider filtert nach Range', () async {
      final notifier = container.read(expensesProvider.notifier);
      // Mai 2026
      await notifier.addExpense(ExpenseDraft(
        categoryId: catFood,
        totalCents: 1000,
        merchant: 'Mai',
        occurredAt: DateTime(2026, 5, 15),
      ));
      // April 2026 (letzter Tag, kurz vor Mitternacht)
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

      final paged = await container.read(pagedExpensesProvider.future);
      expect(paged.items, hasLength(1));
      expect(paged.items.first.merchant, 'Mai');
      expect(paged.total, 1);

      final total =
          await container.read(totalSpentInSelectedRangeProvider.future);
      expect(total, 1000);
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

      final byCat = await container
          .read(spentByCategoryInSelectedRangeProvider.future);
      expect(byCat[catFood], 4000);
      expect(byCat[catFuel], 6500);
    });

    test('pagedExpensesProvider laedt initial nur die erste Page', () async {
      // pageSize + 5 Eintraege anlegen.
      final notifier = container.read(expensesProvider.notifier);
      const total = kExpensesPageSize + 5;
      for (var i = 1; i <= total; i++) {
        await notifier.addExpense(ExpenseDraft(
          categoryId: catFood,
          totalCents: i * 10,
          merchant: 'M$i',
          occurredAt: DateTime(2026, 5, i % 28 + 1, i % 24, 0),
        ));
      }

      final paged = await container.read(pagedExpensesProvider.future);
      expect(paged.items, hasLength(kExpensesPageSize));
      expect(paged.total, total);
      expect(paged.hasMore, isTrue);
      expect(paged.loadingMore, isFalse);
    });

    test('loadMore haengt naechste Page an und beendet bei hasMore=false',
        () async {
      final notifier = container.read(expensesProvider.notifier);
      const total = kExpensesPageSize + 5;
      for (var i = 1; i <= total; i++) {
        await notifier.addExpense(ExpenseDraft(
          categoryId: catFood,
          totalCents: i * 10,
          merchant: 'M$i',
          occurredAt: DateTime(2026, 5, (i % 28) + 1, i % 24, 0),
        ));
      }

      // Erste Page initial laden.
      var paged = await container.read(pagedExpensesProvider.future);
      expect(paged.items, hasLength(kExpensesPageSize));

      // Naechste Page anfordern.
      await container.read(pagedExpensesProvider.notifier).loadMore();
      paged = container.read(pagedExpensesProvider).requireValue;
      expect(paged.items, hasLength(total));
      expect(paged.hasMore, isFalse);
      expect(paged.loadingMore, isFalse);

      // Weiterer loadMore-Aufruf bei hasMore=false ist Noop.
      await container.read(pagedExpensesProvider.notifier).loadMore();
      paged = container.read(pagedExpensesProvider).requireValue;
      expect(paged.items, hasLength(total));
    });
  });
}
