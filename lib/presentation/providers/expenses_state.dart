import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/data_providers.dart';
import '../../domain/entities/expense.dart';
import '../../domain/repositories/expense_repository.dart';

/// Notifier fuer alle Ausgaben.
///
/// Haelt absichtlich die volle Liste vor (lokal, kein Server, keine Pagination
/// bei haushaltsueblichen Mengen relevant). Abgeleitete Provider filtern dann
/// nach Monat / Kategorie / etc.
class ExpensesNotifier extends AsyncNotifier<List<Expense>> {
  @override
  Future<List<Expense>> build() async {
    final repo = await ref.watch(expenseRepositoryProvider.future);
    return repo.getAll();
  }

  Future<Expense> addExpense(ExpenseDraft draft) async {
    final repo = await ref.read(expenseRepositoryProvider.future);
    final created = await repo.create(draft);
    ref.invalidateSelf();
    return created;
  }

  Future<Expense> updateExpense(Expense expense) async {
    final repo = await ref.read(expenseRepositoryProvider.future);
    final updated = await repo.update(expense);
    ref.invalidateSelf();
    return updated;
  }

  Future<void> deleteExpense(String id) async {
    final repo = await ref.read(expenseRepositoryProvider.future);
    await repo.delete(id);
    ref.invalidateSelf();
  }
}

final expensesProvider =
    AsyncNotifierProvider<ExpensesNotifier, List<Expense>>(
  ExpensesNotifier.new,
);

/// Aktuell ausgewaehlter Monat fuer Dashboard / Statistik.
/// Default: aktueller Monat (auf den Monatsanfang normiert).
final selectedMonthProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month);
});

/// Inklusive Monatsstart, exklusive Anfang Folgemonat.
({DateTime from, DateTime toExclusive}) _monthRange(DateTime month) {
  final from = DateTime(month.year, month.month);
  final toExclusive = DateTime(month.year, month.month + 1);
  return (from: from, toExclusive: toExclusive);
}

/// Ausgaben des ausgewaehlten Monats, neueste zuerst.
final expensesInSelectedMonthProvider = Provider<List<Expense>>((ref) {
  final all = ref.watch(expensesProvider).valueOrNull ?? const <Expense>[];
  final month = ref.watch(selectedMonthProvider);
  final r = _monthRange(month);
  return all
      .where((e) =>
          !e.occurredAt.isBefore(r.from) && e.occurredAt.isBefore(r.toExclusive))
      .toList(growable: false);
});

/// Summe der Ausgaben im ausgewaehlten Monat (in Cent).
final totalSpentInSelectedMonthProvider = Provider<int>((ref) {
  final list = ref.watch(expensesInSelectedMonthProvider);
  return list.fold<int>(0, (sum, e) => sum + e.totalCents);
});

/// Summe pro Kategorie im ausgewaehlten Monat.
final spentByCategoryInSelectedMonthProvider =
    Provider<Map<String, int>>((ref) {
  final list = ref.watch(expensesInSelectedMonthProvider);
  final map = <String, int>{};
  for (final e in list) {
    map[e.categoryId] = (map[e.categoryId] ?? 0) + e.totalCents;
  }
  return map;
});

/// Tagesdurchschnitt im ausgewaehlten Monat.
/// Bezugsgroesse: Anzahl der bisher vergangenen Tage im Monat
/// (im aktuellen Monat) bzw. Tage des Monats (in vergangenen Monaten).
final dailyAverageCentsProvider = Provider<int>((ref) {
  final spent = ref.watch(totalSpentInSelectedMonthProvider);
  final month = ref.watch(selectedMonthProvider);
  final now = DateTime.now();
  final isCurrent = month.year == now.year && month.month == now.month;
  final lastDayOfMonth = DateTime(month.year, month.month + 1, 0).day;
  final divisor = isCurrent ? now.day : lastDayOfMonth;
  if (divisor <= 0) return 0;
  return (spent / divisor).round();
});

/// Eintrag in der Trendliste „letzte N Monate".
class MonthlyTotal {
  const MonthlyTotal({required this.month, required this.totalCents});
  final DateTime month;
  final int totalCents;
}

/// Liste der letzten 12 Monate mit Summe pro Monat,
/// chronologisch (aelteste zuerst).
final monthlyTotalsProvider = Provider<List<MonthlyTotal>>((ref) {
  final all = ref.watch(expensesProvider).valueOrNull ?? const <Expense>[];
  final selected = ref.watch(selectedMonthProvider);
  final months = <DateTime>[
    for (int i = 11; i >= 0; i--)
      DateTime(selected.year, selected.month - i),
  ];
  return <MonthlyTotal>[
    for (final m in months)
      MonthlyTotal(
        month: m,
        totalCents: all
            .where((e) =>
                e.occurredAt.year == m.year && e.occurredAt.month == m.month)
            .fold<int>(0, (sum, e) => sum + e.totalCents),
      ),
  ];
});

/// Vergleich: aktueller vs. Vormonat.
class MonthOverMonth {
  const MonthOverMonth({
    required this.currentCents,
    required this.previousCents,
  });

  final int currentCents;
  final int previousCents;

  int get diffCents => currentCents - previousCents;

  /// Prozentuale Differenz (Vormonat = Basis). Null, wenn Basis == 0.
  double? get diffPercent {
    if (previousCents == 0) return null;
    return (diffCents / previousCents) * 100;
  }
}

final monthOverMonthProvider = Provider<MonthOverMonth>((ref) {
  final all = ref.watch(expensesProvider).valueOrNull ?? const <Expense>[];
  final selected = ref.watch(selectedMonthProvider);
  final prev = DateTime(selected.year, selected.month - 1);

  int sumFor(DateTime m) {
    return all
        .where((e) =>
            e.occurredAt.year == m.year && e.occurredAt.month == m.month)
        .fold<int>(0, (s, e) => s + e.totalCents);
  }

  return MonthOverMonth(
    currentCents: sumFor(selected),
    previousCents: sumFor(prev),
  );
});

/// Top-Kategorien im ausgewaehlten Monat (sortiert, mit cents).
class CategorySpend {
  const CategorySpend({required this.categoryId, required this.totalCents});
  final String categoryId;
  final int totalCents;
}

final topCategoriesInSelectedMonthProvider =
    Provider<List<CategorySpend>>((ref) {
  final byCat = ref.watch(spentByCategoryInSelectedMonthProvider);
  final list = byCat.entries
      .map((e) => CategorySpend(categoryId: e.key, totalCents: e.value))
      .toList()
    ..sort((a, b) => b.totalCents.compareTo(a.totalCents));
  return list;
});
