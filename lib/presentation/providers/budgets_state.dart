import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/data_providers.dart';
import '../../domain/entities/budget.dart';

class BudgetsNotifier extends AsyncNotifier<List<Budget>> {
  @override
  Future<List<Budget>> build() async {
    final repo = await ref.watch(budgetRepositoryProvider.future);
    return repo.getAll();
  }

  Future<void> setForCategory({
    required String categoryId,
    required int amountCents,
  }) async {
    final repo = await ref.read(budgetRepositoryProvider.future);
    await repo.setForCategory(
      categoryId: categoryId,
      amountCents: amountCents,
    );
    ref.invalidateSelf();
  }

  Future<void> remove(String categoryId) async {
    final repo = await ref.read(budgetRepositoryProvider.future);
    await repo.remove(categoryId);
    ref.invalidateSelf();
  }
}

final budgetsProvider =
    AsyncNotifierProvider<BudgetsNotifier, List<Budget>>(BudgetsNotifier.new);

/// Bequemer Lookup: Budget per Kategorie-ID (oder null).
final budgetByCategoryProvider =
    Provider.family<Budget?, String>((ref, categoryId) {
  final budgets = ref.watch(budgetsProvider).valueOrNull ?? const <Budget>[];
  for (final b in budgets) {
    if (b.categoryId == categoryId) return b;
  }
  return null;
});

/// Gesamtbudget = Summe aller Kategorie-Budgets.
final totalBudgetCentsProvider = Provider<int>((ref) {
  final budgets = ref.watch(budgetsProvider).valueOrNull ?? const <Budget>[];
  return budgets.fold<int>(0, (sum, b) => sum + b.amountCents);
});
