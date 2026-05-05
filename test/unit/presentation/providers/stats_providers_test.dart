import 'package:bonbudget/core/providers/data_providers.dart';
import 'package:bonbudget/data/repositories/category_repository_impl.dart';
import 'package:bonbudget/data/repositories/expense_repository_impl.dart';
import 'package:bonbudget/domain/repositories/expense_repository.dart';
import 'package:bonbudget/presentation/providers/expenses_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/in_memory_database.dart';

/// Tests fuer die abgeleiteten Statistik-Provider:
/// monthlyTotalsProvider, periodOverPeriodProvider, dailyAverageCentsProvider,
/// topCategoriesInSelectedRangeProvider.
///
/// Pagination-Migration: Provider sind jetzt FutureProvider mit Repo-
/// Aggregaten — Tests warten via `.future` auf die Aufloesung.
void main() {
  group('Stats-Provider', () {
    late ProviderContainer container;
    late ExpenseRepositoryImpl repo;
    late String catFood;
    late String catFuel;
    late String catLeisure;

    setUp(() async {
      final db = await openInMemoryTestDb();
      repo = ExpenseRepositoryImpl(db);
      final catRepo = CategoryRepositoryImpl(db);
      addTearDown(db.close);

      catFood = (await catRepo.create(
        name: 'Lebensmittel', colorValue: 0xFF14B8A6, iconCodePoint: 0xe000,
      )).id;
      catFuel = (await catRepo.create(
        name: 'Tanken', colorValue: 0xFFEF4444, iconCodePoint: 0xe001,
      )).id;
      catLeisure = (await catRepo.create(
        name: 'Freizeit', colorValue: 0xFF8B5CF6, iconCodePoint: 0xe002,
      )).id;

      container = ProviderContainer(overrides: <Override>[
        expenseRepositoryProvider.overrideWith((_) async => repo),
      ]);
      addTearDown(container.dispose);

      // Monat fixieren auf Mai 2026 fuer reproduzierbare Tests.
      container.read(selectedDateRangeProvider.notifier).state =
          DateRange.calendarMonth(DateTime(2026, 5));
    });

    Future<void> add({
      required String catId,
      required int cents,
      required DateTime when,
      String merchant = 'Test',
    }) async {
      await container.read(expensesProvider.notifier).addExpense(ExpenseDraft(
            categoryId: catId,
            totalCents: cents,
            merchant: merchant,
            occurredAt: when,
          ));
    }

    test('monthlyTotalsProvider liefert exakt 12 Monate, chronologisch',
        () async {
      final list = await container.read(monthlyTotalsProvider.future);
      expect(list, hasLength(12));
      // chronologisch: aelteste zuerst, juengste = ausgewaehlter Monat
      expect(list.first.month, DateTime(2025, 6));
      expect(list.last.month, DateTime(2026, 5));
    });

    test('monthlyTotalsProvider summiert pro Monat korrekt', () async {
      await add(catId: catFood, cents: 1000, when: DateTime(2026, 5, 5));
      await add(catId: catFood, cents: 2000, when: DateTime(2026, 5, 20));
      await add(catId: catFood, cents: 5000, when: DateTime(2026, 4, 15));
      await add(catId: catFood, cents: 7000, when: DateTime(2025, 12, 24));

      final list = await container.read(monthlyTotalsProvider.future);
      final byMonth = <DateTime, int>{
        for (final t in list) t.month: t.totalCents,
      };
      expect(byMonth[DateTime(2026, 5)], 3000);
      expect(byMonth[DateTime(2026, 4)], 5000);
      expect(byMonth[DateTime(2025, 12)], 7000);
      // Monate ohne Ausgaben → 0
      expect(byMonth[DateTime(2026, 3)], 0);
    });

    test('periodOverPeriodProvider berechnet Differenz und %', () async {
      await add(catId: catFood, cents: 8000, when: DateTime(2026, 5, 1));
      await add(catId: catFood, cents: 4000, when: DateTime(2026, 4, 10));

      final mom = await container.read(periodOverPeriodProvider.future);
      expect(mom.currentCents, 8000);
      expect(mom.previousCents, 4000);
      expect(mom.diffCents, 4000);
      expect(mom.diffPercent, 100.0);
    });

    test('periodOverPeriodProvider gibt diffPercent=null bei prev=0', () async {
      await add(catId: catFood, cents: 8000, when: DateTime(2026, 5, 1));

      final mom = await container.read(periodOverPeriodProvider.future);
      expect(mom.previousCents, 0);
      expect(mom.diffPercent, isNull);
      expect(mom.diffCents, 8000);
    });

    test('topCategoriesInSelectedRangeProvider sortiert absteigend', () async {
      await add(catId: catFood, cents: 1500, when: DateTime(2026, 5, 5));
      await add(catId: catFuel, cents: 6000, when: DateTime(2026, 5, 12));
      await add(catId: catLeisure, cents: 4000, when: DateTime(2026, 5, 18));

      final top =
          await container.read(topCategoriesInSelectedRangeProvider.future);
      expect(
        top.map((c) => c.categoryId),
        <String>[catFuel, catLeisure, catFood],
      );
      expect(top.first.totalCents, 6000);
    });

    test('dailyAverageCentsProvider teilt durch Tage des Monats fuer Vormonate',
        () async {
      // Mai hat 31 Tage → 3100 Cent / 31 = 100 Cent pro Tag
      // ABER der ausgewaehlte Monat (Mai 2026) ist evtl. der aktuelle Monat
      // im Test. Wir setzen daher explizit auf einen Vormonat (April 2026).
      container.read(selectedDateRangeProvider.notifier).state =
          DateRange.calendarMonth(DateTime(2026, 4)); // April hat 30 Tage
      await add(catId: catFood, cents: 3000, when: DateTime(2026, 4, 10));

      final avg = await container.read(dailyAverageCentsProvider.future);
      // 3000 / 30 = 100
      expect(avg, 100);
    });
  });
}
