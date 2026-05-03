import 'package:flutter/foundation.dart';

/// Monats-Budget pro Kategorie.
///
/// Es gibt **kein** separates Gesamtbudget – das Gesamtbudget ergibt
/// sich aus der Summe der Kategorie-Budgets (Anforderung des Nutzers).
///
/// Der Betrag ist immer in **Cent** (int), nie in Euro (double).
@immutable
class Budget {
  const Budget({
    required this.id,
    required this.categoryId,
    required this.amountCents,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String categoryId;
  final int amountCents;
  final DateTime createdAt;
  final DateTime updatedAt;

  Budget copyWith({
    int? amountCents,
    DateTime? updatedAt,
  }) {
    return Budget(
      id: id,
      categoryId: categoryId,
      amountCents: amountCents ?? this.amountCents,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Budget && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
