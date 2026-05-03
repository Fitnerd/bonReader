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
