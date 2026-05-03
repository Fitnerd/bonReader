import 'package:flutter/foundation.dart';

import 'expense_item.dart';

/// Eine Ausgabe (z. B. ein Einkauf bei Rewe).
///
/// Eine Ausgabe gehoert zu **einer** Kategorie. Sie kann mehrere
/// [ExpenseItem]s haben (einzelne Positionen vom Bon). [totalCents]
/// ist die Summe der Positionen oder – wenn keine Positionen erfasst
/// sind – der vom Nutzer / OCR erkannte Gesamtbetrag.
@immutable
class Expense {
  const Expense({
    required this.id,
    required this.categoryId,
    required this.totalCents,
    required this.merchant,
    required this.occurredAt,
    required this.note,
    required this.createdAt,
    this.items = const <ExpenseItem>[],
  });

  final String id;
  final String categoryId;
  final int totalCents;
  final String merchant;
  /// Datum/Uhrzeit auf dem Bon (kann vom OCR uebernommen werden,
  /// faellt sonst auf [createdAt] zurueck).
  final DateTime occurredAt;
  final String note;
  final DateTime createdAt;
  final List<ExpenseItem> items;

  Expense copyWith({
    String? categoryId,
    int? totalCents,
    String? merchant,
    DateTime? occurredAt,
    String? note,
    List<ExpenseItem>? items,
  }) {
    return Expense(
      id: id,
      categoryId: categoryId ?? this.categoryId,
      totalCents: totalCents ?? this.totalCents,
      merchant: merchant ?? this.merchant,
      occurredAt: occurredAt ?? this.occurredAt,
      note: note ?? this.note,
      createdAt: createdAt,
      items: items ?? this.items,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Expense && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
