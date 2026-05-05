import 'package:flutter/material.dart';
import 'package:bonbudget/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/currency_formatter.dart';
import '../../../domain/entities/category.dart';
import '../../../domain/entities/expense.dart';
import '../../providers/categories_state.dart';
import '../../providers/expenses_state.dart';
import '../../widgets/range_picker_sheet.dart';
import 'expense_form_screen.dart';
import 'receipt_scan_screen.dart';

/// Liste aller Ausgaben des aktuell ausgewaehlten Zeitraums.
///
/// Nutzt den `pagedExpensesProvider`: erste Page (`kExpensesPageSize`)
/// kommt direkt, weitere Pages werden ueber den `ScrollController`
/// nachgeladen, sobald sich der Nutzer dem Listenende naehert.
class ExpensesListScreen extends ConsumerStatefulWidget {
  const ExpensesListScreen({super.key});

  @override
  ConsumerState<ExpensesListScreen> createState() =>
      _ExpensesListScreenState();
}

class _ExpensesListScreenState extends ConsumerState<ExpensesListScreen> {
  /// Vorlaufdistanz zum Listenende, ab der die naechste Page geladen wird.
  /// 200 px sind ungefaehr 3-4 ListTiles — fuehlt sich nahtlos an, ohne
  /// auf jedem Frame zu triggern.
  static const double _loadMoreThresholdPx = 200;

  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - _loadMoreThresholdPx) {
      ref.read(pagedExpensesProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final asyncCats = ref.watch(categoriesProvider);
    final asyncPaged = ref.watch(pagedExpensesProvider);
    final asyncTotal = ref.watch(totalSpentInSelectedRangeProvider);
    final selectedRange = ref.watch(selectedDateRangeProvider);
    final selectedRangeLabel = ref.watch(selectedDateRangeLabelProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.expensesListTitle),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.qr_code_scanner_rounded),
            tooltip: l10n.actionScanReceipt,
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute<void>(
                builder: (_) => const ReceiptScanScreen(),
              ));
            },
          ),
          IconButton(
            icon: const Icon(Icons.calendar_month_rounded),
            tooltip: l10n.actionPickRange,
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
        label: Text(l10n.commonNew),
      ),
      body: asyncPaged.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(l10n.commonErrorWithDetail('$e'))),
        data: (paged) => asyncCats.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) =>
              Center(child: Text(l10n.commonErrorWithDetail('$e'))),
          data: (categories) {
            final byCatId = <String, Category>{
              for (final c in categories) c.id: c,
            };
            // Total kommt aus dem Repo-Aggregat. Wenn es noch laedt
            // fallback auf bisherige Page-Summe (visuell stabil).
            final totalCents = asyncTotal.maybeWhen(
              data: (v) => v,
              orElse: () => paged.items.fold<int>(
                0,
                (sum, e) => sum + e.totalCents,
              ),
            );

            return Column(
              children: <Widget>[
                _RangeHeader(
                  rangeLabel: selectedRangeLabel,
                  totalCents: totalCents,
                  count: paged.total,
                  theme: theme,
                ),
                const Divider(height: 1),
                Expanded(
                  child: paged.items.isEmpty
                      ? const _EmptyState()
                      : ListView.separated(
                          controller: _scrollController,
                          // +1 fuer den Footer (Spinner / Ende-Marker)
                          itemCount: paged.items.length + 1,
                          separatorBuilder: (_, int i) =>
                              i < paged.items.length - 1
                                  ? const Divider(height: 1)
                                  : const SizedBox.shrink(),
                          itemBuilder: (BuildContext ctx, int i) {
                            if (i == paged.items.length) {
                              return _ListFooter(
                                loadingMore: paged.loadingMore,
                                hasMore: paged.hasMore,
                                shownCount: paged.items.length,
                                totalCount: paged.total,
                              );
                            }
                            final e = paged.items[i];
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
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: Text(l10n.expenseDeleteTitle),
        content: Text(
          l10n.expenseDeleteBody(
            e.merchant.isEmpty ? l10n.expenseFallbackName : e.merchant,
            CurrencyFormatter.formatCents(e.totalCents),
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.commonDelete),
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
    final l10n = AppLocalizations.of(context)!;
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
            l10n.expensesCount(count),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _ListFooter extends StatelessWidget {
  const _ListFooter({
    required this.loadingMore,
    required this.hasMore,
    required this.shownCount,
    required this.totalCount,
  });

  final bool loadingMore;
  final bool hasMore;
  final int shownCount;
  final int totalCount;

  @override
  Widget build(BuildContext context) {
    if (loadingMore) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }
    // Wenn alles geladen ist und mehr als eine Page noetig war, eine
    // dezente "Ende"-Markierung — bei einer einzigen Page nicht noetig.
    if (!hasMore && shownCount > 0 && totalCount > shownCount) {
      // Sollte mit hasMore=false eigentlich nicht eintreten, aber
      // defensiv kein Footer.
      return const SizedBox.shrink();
    }
    return const SizedBox.shrink();
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
    final l10n = AppLocalizations.of(context)!;
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
          expense.merchant.isEmpty
              ? (cat?.name ?? l10n.expenseFallbackName)
              : expense.merchant,
        ),
        subtitle: Text(<String>[
          dateLabel,
          if (cat != null) cat.name,
          if (expense.items.isNotEmpty)
            l10n.expenseItemsCount(expense.items.length),
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
    final l10n = AppLocalizations.of(context)!;
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
              l10n.expensesListEmpty,
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.expensesListEmptyHint,
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
