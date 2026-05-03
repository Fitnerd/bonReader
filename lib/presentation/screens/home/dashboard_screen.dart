import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../domain/entities/category.dart';
import '../../../domain/entities/expense.dart';
import '../../providers/auth_state.dart';
import '../../providers/budgets_state.dart';
import '../../providers/categories_state.dart';
import '../../providers/expenses_state.dart';
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
    final asyncCats = ref.watch(categoriesProvider);
    final asyncExpenses = ref.watch(expensesProvider);
    final selectedMonth = ref.watch(selectedMonthProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.appName),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.bar_chart_rounded),
            tooltip: 'Statistik',
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute<void>(
                builder: (_) => const StatsScreen(),
              ));
            },
          ),
          IconButton(
            icon: const Icon(Icons.calendar_month_rounded),
            tooltip: 'Monat waehlen',
            onPressed: () => _pickMonth(context, ref, selectedMonth),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Abmelden',
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
        label: const Text('Bon scannen'),
      ),
      body: asyncCats.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Fehler: $e')),
        data: (categories) => asyncExpenses.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Fehler: $e')),
          data: (_) {
            final totalBudget = ref.watch(totalBudgetCentsProvider);
            final spent = ref.watch(totalSpentInSelectedMonthProvider);
            final byCat = ref.watch(spentByCategoryInSelectedMonthProvider);
            final monthExpenses = ref.watch(expensesInSelectedMonthProvider);
            final visible = categories.where((c) => !c.isHidden).toList();

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              children: <Widget>[
                _BudgetRingCard(
                  month: selectedMonth,
                  totalBudgetCents: totalBudget,
                  spentCents: spent,
                  theme: theme,
                ),
                const SizedBox(height: 24),
                _SectionTitle(label: 'Kategorien', theme: theme, action: TextButton(
                  onPressed: () {
                    Navigator.of(context).push(MaterialPageRoute<void>(
                      builder: (_) => const BudgetScreen(),
                    ));
                  },
                  child: const Text('Budgets bearbeiten'),
                )),
                if (visible.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'Keine Kategorien sichtbar.',
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
                  label: 'Letzte Ausgaben',
                  theme: theme,
                  action: TextButton(
                    onPressed: () {
                      Navigator.of(context).push(MaterialPageRoute<void>(
                        builder: (_) => const ExpensesListScreen(),
                      ));
                    },
                    child: const Text('Alle ansehen'),
                  ),
                ),
                if (monthExpenses.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'Noch keine Ausgaben in diesem Monat.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  )
                else
                  for (final e in monthExpenses.take(5))
                    _RecentExpenseTile(
                      expense: e,
                      category: _findCat(categories, e.categoryId),
                      onTap: () {
                        Navigator.of(context).push(MaterialPageRoute<void>(
                          builder: (_) => ExpenseFormScreen(existing: e),
                        ));
                      },
                    ),
              ],
            );
          },
        ),
      ),
    );
  }

  Category? _findCat(List<Category> all, String id) {
    for (final c in all) {
      if (c.id == id) return c;
    }
    return null;
  }

  Future<void> _pickMonth(
    BuildContext context,
    WidgetRef ref,
    DateTime current,
  ) async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      initialDate: current,
      helpText: 'Beliebigen Tag im gewuenschten Monat waehlen',
    );
    if (picked != null) {
      ref.read(selectedMonthProvider.notifier).state =
          DateTime(picked.year, picked.month);
    }
  }
}

/// Kreis-Diagramm fuer das Restbudget.
class _BudgetRingCard extends StatelessWidget {
  const _BudgetRingCard({
    required this.month,
    required this.totalBudgetCents,
    required this.spentCents,
    required this.theme,
  });

  final DateTime month;
  final int totalBudgetCents;
  final int spentCents;
  final ThemeData theme;

  static const _monthNames = <String>[
    'Januar', 'Februar', 'Maerz', 'April', 'Mai', 'Juni',
    'Juli', 'August', 'September', 'Oktober', 'November', 'Dezember',
  ];

  @override
  Widget build(BuildContext context) {
    final remaining = totalBudgetCents - spentCents;
    final hasBudget = totalBudgetCents > 0;
    final ratio = hasBudget
        ? (spentCents / totalBudgetCents).clamp(0.0, 1.5)
        : 0.0;

    final ringColor = !hasBudget
        ? theme.colorScheme.outlineVariant
        : ratio > 1.0
            ? theme.colorScheme.error
            : ratio > 0.85
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
                    '${_monthNames[month.month - 1]} ${month.year}',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    hasBudget
                        ? CurrencyFormatter.formatCents(remaining)
                        : 'Kein Budget gesetzt',
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
                    hasBudget ? 'verbleibend' : 'Tippe "Budgets bearbeiten"',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (hasBudget)
                    Text(
                      'Ausgegeben: '
                      '${CurrencyFormatter.formatCents(spentCents)} '
                      'von ${CurrencyFormatter.formatCents(totalBudgetCents)}',
                      style: theme.textTheme.bodySmall,
                    )
                  else
                    Text(
                      'Ausgegeben: '
                      '${CurrencyFormatter.formatCents(spentCents)}',
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
    final hasBudget = budgetCents > 0;
    final ratio = hasBudget ? (spentCents / budgetCents).clamp(0.0, 1.5) : 0.0;
    final overspent = ratio > 1.0;
    final color = !hasBudget
        ? theme.colorScheme.outlineVariant
        : overspent
            ? theme.colorScheme.error
            : ratio > 0.85
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
        expense.merchant.isEmpty ? (cat?.name ?? 'Ausgabe') : expense.merchant,
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
              title: const Text('Bon scannen'),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(MaterialPageRoute<void>(
                  builder: (_) => const ReceiptScanScreen(),
                ));
              },
            ),
            ListTile(
              leading: const Icon(Icons.receipt_long_rounded),
              title: const Text('Ausgaben'),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(MaterialPageRoute<void>(
                  builder: (_) => const ExpensesListScreen(),
                ));
              },
            ),
            ListTile(
              leading: const Icon(Icons.account_balance_wallet_rounded),
              title: const Text('Budgets'),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(MaterialPageRoute<void>(
                  builder: (_) => const BudgetScreen(),
                ));
              },
            ),
            ListTile(
              leading: const Icon(Icons.bar_chart_rounded),
              title: const Text('Statistik'),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(MaterialPageRoute<void>(
                  builder: (_) => const StatsScreen(),
                ));
              },
            ),
            ListTile(
              leading: const Icon(Icons.category_rounded),
              title: const Text('Kategorien'),
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
              title: const Text('Einstellungen'),
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
