import '../entities/expense.dart';
import '../entities/expense_item.dart';

class ExpenseDraft {
  ExpenseDraft({
    required this.categoryId,
    required this.totalCents,
    required this.merchant,
    required this.occurredAt,
    this.note = '',
    this.items = const <ExpenseItemDraft>[],
  });

  final String categoryId;
  final int totalCents;
  final String merchant;
  final DateTime occurredAt;
  final String note;
  final List<ExpenseItemDraft> items;
}

class ExpenseItemDraft {
  ExpenseItemDraft({
    required this.name,
    required this.totalCents,
    this.quantity = 1,
    this.unitPriceCents = 0,
  });

  final String name;
  final double quantity;
  final int unitPriceCents;
  final int totalCents;
}

abstract class ExpenseRepository {
  Future<List<Expense>> getAll({int? limit});

  Future<List<Expense>> getInRange(DateTime from, DateTime to);

  /// Alle Ausgaben im Zeitraum gruppiert nach Kategorie-ID.
  /// Wert: Summe in Cent.
  Future<Map<String, int>> getTotalsByCategory(DateTime from, DateTime to);

  Future<Expense?> getById(String id);

  Future<Expense> create(ExpenseDraft draft);

  Future<Expense> update(Expense expense);

  Future<void> delete(String id);

  /// Summe aller Ausgaben im Zeitraum in Cent.
  Future<int> getTotalCents(DateTime from, DateTime to);
}
