import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../providers/auth_state.dart';
import '../../providers/budgets_state.dart';
import '../../providers/expenses_state.dart';
import '../budget/budget_screen.dart';
import '../categories/categories_screen.dart';
import '../expense/expenses_list_screen.dart';
import '../expense/receipt_scan_screen.dart';

/// Platzhalter-Startseite. Wird in Schritt 7 durch das echte
/// Dashboard mit Restbudget, Letzte-Ausgaben-Liste und
/// Kategorie-Status ersetzt.
class HomePlaceholderScreen extends ConsumerWidget {
  const HomePlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final totalBudget = ref.watch(totalBudgetCentsProvider);
    // FutureProvider — bis das Repo-Aggregat da ist, fallen wir auf 0
    // zurueck (in der Praxis nur ein Frame).
    final spent =
        ref.watch(totalSpentInSelectedRangeProvider).valueOrNull ?? 0;
    final remaining = totalBudget - spent;

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.appName),
        actions: <Widget>[
          IconButton(
            tooltip: l10n.actionLogout,
            icon: const Icon(Icons.logout_rounded),
            onPressed: () => ref.read(authStateProvider.notifier).logout(),
          ),
        ],
      ),
      drawer: const _AppDrawer(),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: <Widget>[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Text(
                      totalBudget == 0
                          ? l10n.homeNoBudgetSet
                          : l10n.homeRemainingThisMonth,
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      CurrencyFormatter.formatCents(
                        totalBudget == 0 ? 0 : remaining,
                      ),
                      style: theme.textTheme.displaySmall?.copyWith(
                        color: remaining < 0
                            ? theme.colorScheme.error
                            : theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (totalBudget > 0) ...<Widget>[
                      const SizedBox(height: 4),
                      Text(
                        l10n.homeSpentOfTotal(
                          CurrencyFormatter.formatCents(spent),
                          CurrencyFormatter.formatCents(totalBudget),
                        ),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            _NavTile(
              icon: Icons.qr_code_scanner_rounded,
              title: l10n.actionScanReceipt,
              subtitle: l10n.homeScanReceiptSubtitle,
              onTap: () {
                Navigator.of(context).push(MaterialPageRoute<void>(
                  builder: (_) => const ReceiptScanScreen(),
                ));
              },
            ),
            _NavTile(
              icon: Icons.receipt_long_rounded,
              title: l10n.actionExpenses,
              subtitle: l10n.homeExpensesSubtitle,
              onTap: () {
                Navigator.of(context).push(MaterialPageRoute<void>(
                  builder: (_) => const ExpensesListScreen(),
                ));
              },
            ),
            _NavTile(
              icon: Icons.account_balance_wallet_rounded,
              title: l10n.actionBudgets,
              subtitle: l10n.homeBudgetsSubtitle,
              onTap: () {
                Navigator.of(context).push(MaterialPageRoute<void>(
                  builder: (_) => const BudgetScreen(),
                ));
              },
            ),
            _NavTile(
              icon: Icons.category_rounded,
              title: l10n.actionCategories,
              subtitle: l10n.homeCategoriesSubtitle,
              onTap: () {
                Navigator.of(context).push(MaterialPageRoute<void>(
                  builder: (_) => const CategoriesScreen(),
                ));
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _AppDrawer extends StatelessWidget {
  const _AppDrawer();

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
              leading: const Icon(Icons.category_rounded),
              title: Text(l10n.actionCategories),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(MaterialPageRoute<void>(
                  builder: (_) => const CategoriesScreen(),
                ));
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  const _NavTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: onTap,
      ),
    );
  }
}
