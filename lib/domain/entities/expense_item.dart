import 'package:flutter/foundation.dart';

import '../../core/constants/app_constants.dart';

/// Eine einzelne Position auf einem Bon (z. B. „Brot 1,99 €").
///
/// Wird vom OCR-Parser erzeugt oder vom Nutzer manuell eingegeben.
/// Gehoert immer zu genau einer [Expense] (ueber [expenseId]).
@immutable
class ExpenseItem {
  const ExpenseItem({
    required this.id,
    required this.expenseId,
    required this.name,
    required this.quantityMilli,
    required this.unitPriceCents,
    required this.totalCents,
  });

  final String id;
  final String expenseId;
  final String name;

  /// Stueckzahl in Milli-Einheiten. 1000 = 1 Stueck, 1500 = 1,5 Stueck.
  /// Integer statt Double, damit IEEE-754-Rundungsfehler ausgeschlossen
  /// sind. Anzeige geht ueber [QuantityFormatter].
  final int quantityMilli;

  final int unitPriceCents;
  final int totalCents;

  /// Komfort-Getter fuer UI-Code, der mit Dezimal-Werten rechnet.
  double get quantityAsDouble =>
      quantityMilli / AppConstants.quantityMilliPerUnit;

  ExpenseItem copyWith({
    String? name,
    int? quantityMilli,
    int? unitPriceCents,
    int? totalCents,
  }) {
    return ExpenseItem(
      id: id,
      expenseId: expenseId,
      name: name ?? this.name,
      quantityMilli: quantityMilli ?? this.quantityMilli,
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
