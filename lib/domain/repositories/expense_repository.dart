import 'package:flutter/foundation.dart';

import '../entities/expense.dart';

@immutable
class ExpenseDraft {
  const ExpenseDraft({
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

@immutable
class ExpenseItemDraft {
  const ExpenseItemDraft({
    required this.name,
    required this.totalCents,
    this.quantityMilli = 1000,
    this.unitPriceCents = 0,
  });

  final String name;

  /// Stueckzahl in Milli-Einheiten (1000 = 1).
  final int quantityMilli;
  final int unitPriceCents;
  final int totalCents;
}

abstract class ExpenseRepository {
  Future<List<Expense>> getAll({int? limit});

  Future<List<Expense>> getInRange(DateTime from, DateTime to);

  /// Pagination ueber alle Ausgaben (DESC nach Datum). Fuer
  /// haushaltsuebliche Mengen unkritisch, aber sobald jemand mit
  /// >10 000 Eintraegen arbeitet bleibt das UI fluessig.
  Future<List<Expense>> getPage({required int offset, required int limit});

  /// Pagination innerhalb eines Zeitraums.
  Future<List<Expense>> getPageInRange({
    required DateTime from,
    required DateTime to,
    required int offset,
    required int limit,
  });

  /// Anzahl aller Ausgaben (fuer Pagination-UI).
  Future<int> getCount();

  /// Anzahl Ausgaben in einem Zeitraum.
  Future<int> getCountInRange(DateTime from, DateTime to);

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
