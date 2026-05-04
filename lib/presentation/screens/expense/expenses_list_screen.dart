import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/currency_formatter.dart';
import '../../../domain/entities/category.dart';
import '../../../domain/entities/expense.dart';
import '../../providers/categories_state.dart';
import '../../providers/expenses_state.dart';
import '../../widgets/range_picker_sheet.dart';
import 'expense_form_screen.dart';
import 'receipt_scan_screen.dart';

/// Liste aller Ausgaben des aktuell ausgewaehlten Monats.
class ExpensesListScreen extends ConsumerWidget {
  const ExpensesListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final asyncExpenses = ref.watch(expensesProvider);
    final asyncCats = ref.watch(categoriesProvider);
    final monthExpenses = ref.watch(expensesInSelectedRangeProvider);
    final totalCents = ref.watch(totalSpentInSelectedRangeProvider);
    final selectedRange = ref.watch(selectedDateRangeProvider);
    final selectedRangeLabel = ref.watch(selectedDateRangeLabelProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ausgaben'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.qr_code_scanner_rounded),
            tooltip: 'Bon scannen',
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute<void>(
                builder: (_) => const ReceiptScanScreen(),
              ));
            },
          ),
          IconButton(
            icon: const Icon(Icons.calendar_month_rounded),
            tooltip: 'Zeitraum waehlen',
            onPressed: () => _pickRange(context, ref, selectedRange),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(MaterialPageRoute<void>(
            builder: (_) => const ExpenseFormScreen(),
          ));
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text('Neu'),
      ),
      body: asyncExpenses.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Fehler: $e')),
        data: (_) => asyncCats.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Fehler: $e')),
          data: (categories) {
            final byCatId = <String, Category>{
              for (final c in categories) c.id: c,
            };

            return Column(
              children: <Widget>[
                _RangeHeader(
                  rangeLabel: selectedRangeLabel,
                  totalCents: totalCents,
                  count: monthExpenses.length,
                  theme: theme,
                ),
                const Divider(height: 1),
                Expanded(
                  child: monthExpenses.isEmpty
                      ? const _EmptyState()
                      : ListView.separated(
                          itemCount: monthExpenses.length,
                          separatorBuilder: (_, __) =>
                              const Divider(height: 1),
                          itemBuilder: (BuildContext ctx, int i) {
                            final e = monthExpenses[i];
                            final cat = byCatId[e.categoryId];
                            return _ExpenseTile(
                              expense: e,
                              category: cat,
                              onTap: () {
                                Navigator.of(context)
                                    .push(MaterialPageRoute<void>(
                                  builder: (_) =>
                                      ExpenseFormScreen(existing: e),
                                ));
                              },
                              onDelete: () => _confirmDelete(ctx, ref, e),
                            );
                          },
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _pickRange(
    BuildContext context,
    WidgetRef ref,
    DateRange current,
  ) async {
    await showRangePickerSheet(context, ref, current);
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Expense e,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: const Text('Ausgabe loeschen?'),
        content: Text(
          '${e.merchant.isEmpty ? 'Ausgabe' : e.merchant} '
          '(${CurrencyFormatter.formatCents(e.totalCents)}) wird unwiderruflich '
          'geloescht.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Loeschen'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(expensesProvider.notifier).deleteExpense(e.id);
    }
  }
}

class _RangeHeader extends StatelessWidget {
  const _RangeHeader({
    required this.rangeLabel,
    required this.totalCents,
    required this.count,
    required this.theme,
  });

  final String rangeLabel;
  final int totalCents;
  final int count;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      color: theme.colorScheme.surfaceContainerLow,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            rangeLabel,
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            CurrencyFormatter.formatCents(totalCents),
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '$count ${count == 1 ? 'Ausgabe' : 'Ausgaben'}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _ExpenseTile extends StatelessWidget {
  const _ExpenseTile({
    required this.expense,
    required this.category,
    required this.onTap,
    required this.onDelete,
  });

  final Expense expense;
  final Category? category;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cat = category;
    final dateLabel =
        '${expense.occurredAt.day.toString().padLeft(2, '0')}.${expense.occurredAt.month.toString().padLeft(2, '0')}.';
    return Dismissible(
      key: ValueKey<String>('expense-${expense.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        color: theme.colorScheme.errorContainer,
        child: Icon(Icons.delete_outline_rounded,
            color: theme.colorScheme.onErrorContainer),
      ),
      confirmDismiss: (_) async {
        onDelete();
        return false; // wir loeschen ueber den Provider, nicht ueber Dismissible
      },
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: (cat?.color ?? theme.colorScheme.primary)
                .withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(
            cat?.icon ?? Icons.receipt_long_rounded,
            color: cat?.color ?? theme.colorScheme.primary,
          ),
        ),
        title: Text(
          expense.merchant.isEmpty ? (cat?.name ?? 'Ausgabe') : expense.merchant,
        ),
        subtitle: Text(<String>[
          dateLabel,
          if (cat != null) cat.name,
          if (expense.items.isNotEmpty)
            '${expense.items.length} Position${expense.items.length == 1 ? '' : 'en'}',
        ].join(' · ')),
        trailing: Text(
          CurrencyFormatter.formatCents(expense.totalCents),
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        onTap: onTap,
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              Icons.receipt_long_rounded,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'Noch keine Ausgaben in diesem Monat',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Tippe auf "Neu", um eine Ausgabe zu erfassen.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
