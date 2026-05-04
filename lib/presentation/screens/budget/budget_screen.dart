import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/currency_formatter.dart';
import '../../../domain/entities/budget.dart';
import '../../../domain/entities/category.dart';
import '../../providers/budgets_state.dart';
import '../../providers/categories_state.dart';

/// Bildschirm zum Setzen der Monats-Budgets pro Kategorie.
/// Das Gesamtbudget oben ergibt sich aus der Summe.
class BudgetScreen extends ConsumerStatefulWidget {
  const BudgetScreen({super.key});

  @override
  ConsumerState<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends ConsumerState<BudgetScreen> {
  /// Aktuell editierte Eingaben pro Kategorie-ID.
  /// Wird beim Speichern in DB persistiert.
  final Map<String, TextEditingController> _controllers = {};
  bool _initialized = false;
  bool _saving = false;

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _initControllersIfNeeded(
    List<Category> cats,
    List<Budget> budgets,
  ) {
    if (_initialized) return;
    final byCat = {for (final b in budgets) b.categoryId: b};
    for (final c in cats) {
      final cents = byCat[c.id]?.amountCents ?? 0;
      _controllers[c.id] = TextEditingController(
        text: cents == 0 ? '' : (cents / 100).toStringAsFixed(2).replaceAll('.', ','),
      );
    }
    _initialized = true;
  }

  int _liveTotalCents() {
    var sum = 0;
    for (final ctrl in _controllers.values) {
      sum += CurrencyFormatter.parseToCents(ctrl.text) ?? 0;
    }
    return sum;
  }

  Future<void> _saveAll() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.budgetSaveDialogTitle),
        content: Text(
          l10n.budgetSaveDialogBody(
            CurrencyFormatter.formatCents(_liveTotalCents()),
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.commonSave),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _saving = true);
    final notifier = ref.read(budgetsProvider.notifier);
    for (final entry in _controllers.entries) {
      final cents = CurrencyFormatter.parseToCents(entry.value.text) ?? 0;
      if (cents <= 0) {
        await notifier.remove(entry.key);
      } else {
        await notifier.setForCategory(
          categoryId: entry.key,
          amountCents: cents,
        );
      }
    }
    if (mounted) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.budgetSavedSnack)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final asyncCats = ref.watch(visibleCategoriesProvider);
    final asyncBudgets = ref.watch(budgetsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.budgetTitle)),
      body: asyncCats.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(l10n.commonErrorWithDetail('$e'))),
        data: (cats) => asyncBudgets.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) =>
              Center(child: Text(l10n.commonErrorWithDetail('$e'))),
          data: (budgets) {
            _initControllersIfNeeded(cats, budgets);

            return Column(
              children: <Widget>[
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: <Widget>[
                      Icon(
                        Icons.account_balance_wallet_rounded,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              l10n.budgetTotal,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onPrimaryContainer,
                              ),
                            ),
                            Text(
                              CurrencyFormatter.formatCents(_liveTotalCents()),
                              style: theme.textTheme.headlineSmall?.copyWith(
                                color: theme.colorScheme.onPrimaryContainer,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: cats.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (BuildContext ctx, int i) {
                      final c = cats[i];
                      return _BudgetRow(
                        category: c,
                        controller: _controllers[c.id]!,
                        onChanged: () => setState(() {}),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: FilledButton(
                    onPressed: _saving ? null : _saveAll,
                    child: _saving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(l10n.budgetSaveButton),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _BudgetRow extends StatelessWidget {
  const _BudgetRow({
    required this.category,
    required this.controller,
    required this.onChanged,
  });

  final Category category;
  final TextEditingController controller;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: <Widget>[
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: category.color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(category.icon, color: category.color),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(category.name)),
            SizedBox(
              width: 120,
              child: TextField(
                controller: controller,
                textAlign: TextAlign.end,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  hintText: '0,00',
                  suffixText: '€',
                  isDense: true,
                ),
                onChanged: (_) => onChanged(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
