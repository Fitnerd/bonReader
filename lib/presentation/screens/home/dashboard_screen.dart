import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../domain/entities/category.dart';
import '../../../domain/entities/expense.dart';
import '../../providers/auth_state.dart';
import '../../providers/budgets_state.dart';
import '../../providers/categories_state.dart';
import '../../providers/expenses_state.dart';
import '../../widgets/range_picker_sheet.dart';
import '../budget/budget_screen.dart';
import '../categories/categories_screen.dart';
import '../expense/expense_form_screen.dart';
import '../expense/expenses_list_screen.dart';
import '../expense/receipt_scan_screen.dart';
import '../settings/settings_screen.dart';
import '../stats/stats_screen.dart';

/// Echte Startseite. Zeigt:
///  - Restbudget oben (Ring + Auslastungs-Prozent)
///  - Pro Kategorie eine Status-Zeile (ausgegeben / Budget)
///  - Letzte Ausgaben (max. 5)
///  - FAB fuer „Bon scannen" (haeufigster Workflow)
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final asyncCats = ref.watch(categoriesProvider);
    final asyncPaged = ref.watch(pagedExpensesProvider);
    final selectedRange = ref.watch(selectedDateRangeProvider);
    final selectedRangeLabel = ref.watch(selectedDateRangeLabelProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.appName),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.bar_chart_rounded),
            tooltip: l10n.actionStats,
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute<void>(
                builder: (_) => const StatsScreen(),
              ));
            },
          ),
          IconButton(
            icon: const Icon(Icons.calendar_month_rounded),
            tooltip: l10n.actionPickRange,
            onPressed: () => _pickRange(context, ref, selectedRange),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: l10n.actionLogout,
            onPressed: () => ref.read(authStateProvider.notifier).logout(),
          ),
        ],
      ),
      drawer: const _DashboardDrawer(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(MaterialPageRoute<void>(
            builder: (_) => const ReceiptScanScreen(),
          ));
        },
        icon: const Icon(Icons.qr_code_scanner_rounded),
        label: Text(l10n.actionScanReceipt),
      ),
      body: asyncCats.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(l10n.commonErrorWithDetail('$e'))),
        data: (categories) => asyncPaged.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) =>
              Center(child: Text(l10n.commonErrorWithDetail('$e'))),
          data: (paged) {
            final totalBudget = ref.watch(totalBudgetCentsProvider);
            // Aggregate als FutureProvider — solange sie laden, fallen
            // wir auf 0/leer zurueck. Bei lokaler SQLite ist das in
            // der Praxis ein einzelner Frame.
            final spent =
                ref.watch(totalSpentInSelectedRangeProvider).valueOrNull ?? 0;
            final byCat = ref
                    .watch(spentByCategoryInSelectedRangeProvider)
                    .valueOrNull ??
                const <String, int>{};
            // "Letzte 5" liest aus der ersten Page (DESC nach Datum).
            final monthExpenses = paged.items;
            final visible = categories.where((c) => !c.isHidden).toList();

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              children: <Widget>[
                _BudgetRingCard(
                  rangeLabel: selectedRangeLabel,
                  totalBudgetCents: totalBudget,
                  spentCents: spent,
                  theme: theme,
                ),
                const SizedBox(height: 24),
                _SectionTitle(
                  label: l10n.actionCategories,
                  theme: theme,
                  action: TextButton(
                    onPressed: () {
                      Navigator.of(context).push(MaterialPageRoute<void>(
                        builder: (_) => const BudgetScreen(),
                      ));
                    },
                    child: Text(l10n.dashboardEditBudgets),
                  ),
                ),
                if (visible.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      l10n.dashboardNoVisibleCategories,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  )
                else
                  for (final c in visible)
                    _CategoryStatusTile(
                      category: c,
                      spentCents: byCat[c.id] ?? 0,
                      budgetCents:
                          ref.watch(budgetByCategoryProvider(c.id))?.amountCents ??
                              0,
                    ),
                const SizedBox(height: 24),
                _SectionTitle(
                  label: l10n.dashboardRecentExpensesTitle,
                  theme: theme,
                  action: TextButton(
                    onPressed: () {
                      Navigator.of(context).push(MaterialPageRoute<void>(
                        builder: (_) => const ExpensesListScreen(),
                      ));
                    },
                    child: Text(l10n.dashboardSeeAll),
                  ),
                ),
                if (monthExpenses.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      l10n.dashboardNoExpensesThisMonth,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  )
                else ...<Widget>[
                  // Map-Lookup statt linearer Suche pro Eintrag.
                  Builder(builder: (_) {
                    final byId = <String, Category>{
                      for (final c in categories) c.id: c,
                    };
                    return Column(
                      children: <Widget>[
                        for (final e in monthExpenses.take(5))
                          _RecentExpenseTile(
                            expense: e,
                            category: byId[e.categoryId],
                            onTap: () {
                              Navigator.of(context)
                                  .push(MaterialPageRoute<void>(
                                builder: (_) =>
                                    ExpenseFormScreen(existing: e),
                              ));
                            },
                          ),
                      ],
                    );
                  }),
                ],
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
}

/// Kreis-Diagramm fuer das Restbudget.
class _BudgetRingCard extends StatelessWidget {
  const _BudgetRingCard({
    required this.rangeLabel,
    required this.totalBudgetCents,
    required this.spentCents,
    required this.theme,
  });

  final String rangeLabel;
  final int totalBudgetCents;
  final int spentCents;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final remaining = totalBudgetCents - spentCents;
    final hasBudget = totalBudgetCents > 0;
    final ratio = hasBudget
        ? (spentCents / totalBudgetCents).clamp(0.0, 1.5)
        : 0.0;

    final ringColor = !hasBudget
        ? theme.colorScheme.outlineVariant
        : ratio > 1.0
            ? theme.colorScheme.error
            : ratio > AppConstants.budgetWarningThreshold
                ? Colors.amber
                : theme.colorScheme.primary;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: <Widget>[
            SizedBox(
              width: 110,
              height: 110,
              child: CustomPaint(
                painter: _RingPainter(
                  ratio: ratio.clamp(0.0, 1.0),
                  color: ringColor,
                  trackColor: theme.colorScheme.surfaceContainerHigh,
                  strokeWidth: 12,
                ),
                child: Center(
                  child: Text(
                    hasBudget
                        ? '${(ratio * 100).round()}%'
                        : '–',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
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
                    hasBudget
                        ? CurrencyFormatter.formatCents(remaining)
                        : l10n.dashboardNoBudgetSet,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: !hasBudget
                          ? theme.colorScheme.onSurfaceVariant
                          : remaining < 0
                              ? theme.colorScheme.error
                              : theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    hasBudget
                        ? l10n.dashboardRemaining
                        : l10n.dashboardTipEditBudgets,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (hasBudget)
                    Text(
                      l10n.dashboardSpentOfTotal(
                        CurrencyFormatter.formatCents(spentCents),
                        CurrencyFormatter.formatCents(totalBudgetCents),
                      ),
                      style: theme.textTheme.bodySmall,
                    )
                  else
                    Text(
                      l10n.dashboardSpent(
                        CurrencyFormatter.formatCents(spentCents),
                      ),
                      style: theme.textTheme.bodySmall,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Custom-Painter fuer den Budget-Ring.
class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.ratio,
    required this.color,
    required this.trackColor,
    required this.strokeWidth,
  });

  final double ratio;
  final Color color;
  final Color trackColor;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - strokeWidth / 2;

    final track = Paint()
      ..color = trackColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, radius, track);

    final foreground = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final sweep = 2 * math.pi * ratio;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweep,
      false,
      foreground,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.ratio != ratio ||
      old.color != color ||
      old.trackColor != trackColor ||
      old.strokeWidth != strokeWidth;
}

/// Eine Zeile pro Kategorie mit Mini-Progress-Bar.
class _CategoryStatusTile extends StatelessWidget {
  const _CategoryStatusTile({
    required this.category,
    required this.spentCents,
    required this.budgetCents,
  });

  final Category category;
  final int spentCents;
  final int budgetCents;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final hasBudget = budgetCents > 0;
    final ratio = hasBudget ? (spentCents / budgetCents).clamp(0.0, 1.5) : 0.0;
    final overspent = ratio > 1.0;
    final color = !hasBudget
        ? theme.colorScheme.outlineVariant
        : overspent
            ? theme.colorScheme.error
            : ratio > AppConstants.budgetWarningThreshold
                ? Colors.amber
                : category.color;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: <Widget>[
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: category.color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(category.icon, color: category.color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        category.name,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                    Text(
                      hasBudget
                          ? '${CurrencyFormatter.formatCents(spentCents)} / '
                              '${CurrencyFormatter.formatCents(budgetCents)}'
                          : CurrencyFormatter.formatCents(spentCents),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: overspent
                            ? theme.colorScheme.error
                            : theme.colorScheme.onSurfaceVariant,
                        fontWeight:
                            overspent ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: hasBudget ? ratio.clamp(0.0, 1.0) : 0,
                    minHeight: 6,
                    backgroundColor: theme.colorScheme.surfaceContainerHigh,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                    semanticsLabel: l10n.dashboardBudgetUsageLabel,
                    semanticsValue: hasBudget
                        ? l10n.dashboardPercentSpoken((ratio * 100).round())
                        : null,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentExpenseTile extends StatelessWidget {
  const _RecentExpenseTile({
    required this.expense,
    required this.category,
    required this.onTap,
  });

  final Expense expense;
  final Category? category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final cat = category;
    final dateLabel =
        '${expense.occurredAt.day.toString().padLeft(2, '0')}.${expense.occurredAt.month.toString().padLeft(2, '0')}.';
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color:
              (cat?.color ?? theme.colorScheme.primary).withValues(alpha: 0.15),
          shape: BoxShape.circle,
        ),
        child: Icon(
          cat?.icon ?? Icons.receipt_long_rounded,
          color: cat?.color ?? theme.colorScheme.primary,
          size: 18,
        ),
      ),
      title: Text(
        expense.merchant.isEmpty
            ? (cat?.name ?? l10n.expenseFallbackName)
            : expense.merchant,
      ),
      subtitle: Text('$dateLabel${cat == null ? '' : ' · ${cat.name}'}'),
      trailing: Text(
        CurrencyFormatter.formatCents(expense.totalCents),
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      onTap: onTap,
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.label,
    required this.theme,
    this.action,
  });

  final String label;
  final ThemeData theme;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (action != null) action!,
        ],
      ),
    );
  }
}

class _DashboardDrawer extends StatelessWidget {
  const _DashboardDrawer();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Drawer(
      child: SafeArea(
        child: ListView(
          children: <Widget>[
            const DrawerHeader(
              child: Center(
                child: Text(
                  AppConstants.appName,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.qr_code_scanner_rounded),
              title: Text(l10n.actionScanReceipt),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(MaterialPageRoute<void>(
                  builder: (_) => const ReceiptScanScreen(),
                ));
              },
            ),
            ListTile(
              leading: const Icon(Icons.receipt_long_rounded),
              title: Text(l10n.actionExpenses),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(MaterialPageRoute<void>(
                  builder: (_) => const ExpensesListScreen(),
                ));
              },
            ),
            ListTile(
              leading: const Icon(Icons.account_balance_wallet_rounded),
              title: Text(l10n.actionBudgets),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(MaterialPageRoute<void>(
                  builder: (_) => const BudgetScreen(),
                ));
              },
            ),
            ListTile(
              leading: const Icon(Icons.bar_chart_rounded),
              title: Text(l10n.actionStats),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(MaterialPageRoute<void>(
                  builder: (_) => const StatsScreen(),
                ));
              },
            ),
            ListTile(
              leading: const Icon(Icons.category_rounded),
              title: Text(l10n.actionCategories),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(MaterialPageRoute<void>(
                  builder: (_) => const CategoriesScreen(),
                ));
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.settings_rounded),
              title: Text(l10n.actionSettings),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(MaterialPageRoute<void>(
                  builder: (_) => const SettingsScreen(),
                ));
              },
            ),
          ],
        ),
      ),
    );
  }
}
