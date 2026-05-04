/// Tabellen- und Spaltennamen zentral, damit Tippfehler in SQL-Strings
/// nicht erst zur Laufzeit auffallen.
class DbTables {
  DbTables._();
  static const String auth = 'auth';
  static const String categories = 'categories';
  static const String budgets = 'budgets';
  static const String expenses = 'expenses';
  static const String expenseItems = 'expense_items';
}

class AuthCols {
  AuthCols._();
  static const String id = 'id';
  static const String createdAt = 'created_at';
  static const String updatedAt = 'updated_at';
}

class CategoryCols {
  CategoryCols._();
  static const String id = 'id';
  static const String name = 'name';
  static const String colorValue = 'color_value';
  static const String iconCodePoint = 'icon_code_point';
  static const String isDefault = 'is_default';
  static const String isHidden = 'is_hidden';
  static const String createdAt = 'created_at';
}

class BudgetCols {
  BudgetCols._();
  static const String id = 'id';
  static const String categoryId = 'category_id';
  static const String amountCents = 'amount_cents';
  static const String createdAt = 'created_at';
  static const String updatedAt = 'updated_at';
}

class ExpenseCols {
  ExpenseCols._();
  static const String id = 'id';
  static const String categoryId = 'category_id';
  static const String totalCents = 'total_cents';
  static const String merchant = 'merchant';
  static const String occurredAt = 'occurred_at';
  static const String note = 'note';
  static const String createdAt = 'created_at';
}

class ExpenseItemCols {
  ExpenseItemCols._();
  static const String id = 'id';
  static const String expenseId = 'expense_id';
  static const String name = 'name';

  /// Stueckzahl als Integer mit Faktor 1000 (1500 = 1,5 Stueck).
  /// Vermeidet die IEEE-754-Rundungsfehler des alten REAL-Felds.
  static const String quantityMilli = 'quantity_milli';
  static const String unitPriceCents = 'unit_price_cents';
  static const String totalCents = 'total_cents';
}
