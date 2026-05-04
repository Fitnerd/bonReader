import '../entities/budget.dart';

abstract class BudgetRepository {
  /// Alle Kategorie-Budgets.
  Future<List<Budget>> getAll();

  /// Budget einer bestimmten Kategorie (oder null wenn keines gesetzt).
  Future<Budget?> getForCategory(String categoryId);

  /// Setzt oder aktualisiert das Budget einer Kategorie.
  Future<Budget> setForCategory({
    required String categoryId,
    required int amountCents,
  });

  /// Entfernt das Budget einer Kategorie (=> kein Limit fuer diese Kategorie).
  Future<void> remove(String categoryId);

  /// Summe aller Kategorie-Budgets in Cent.
  /// Das ist das in der App angezeigte Gesamtbudget.
  Future<int> getTotalBudgetCents();
}
