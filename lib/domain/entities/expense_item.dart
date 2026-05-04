import 'package:flutter/foundation.dart';

/// Eine einzelne Position auf einem Bon (z. B. „Brot 1,99 €").
///
/// Wird vom OCR-Parser erzeugt oder vom Nutzer manuell eingegeben.
/// Gehört immer zu genau einer [Expense] (über [expenseId]).
@immutable
class ExpenseItem {
  const ExpenseItem({
    required this.id,
    required this.expenseId,
    required this.name,
    required this.quantity,
    required this.unitPriceCents,
    required this.totalCents,
  });

  final String id;
  final String expenseId;
  final String name;
  /// Stueckzahl. Default 1. Bei Gewichten ist das eine Naeherung
  /// (z. B. 1.250 kg → quantity = 1, totalCents enthaelt den Endpreis).
  final double quantity;
  final int unitPriceCents;
  final int totalCents;

  ExpenseItem copyWith({
    String? name,
    double? quantity,
    int? unitPriceCents,
    int? totalCents,
  }) {
    return ExpenseItem(
      id: id,
      expenseId: expenseId,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      unitPriceCents: unitPriceCents ?? this.unitPriceCents,
      totalCents: totalCents ?? this.totalCents,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is ExpenseItem && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
