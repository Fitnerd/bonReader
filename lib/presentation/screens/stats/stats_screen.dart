import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:bonbudget/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/currency_formatter.dart';
import '../../../domain/entities/category.dart';
import '../../providers/budgets_state.dart';
import '../../providers/categories_state.dart';
import '../../providers/expenses_state.dart';

/// Statistik-Ueberblick:
///  - Monats-Trend (Linie, letzte 12 Monate)
///  - Top-Kategorien (Donut)
///  - Kategorie-Ausgaben vs. Budgets (horizontale Balken)
///  - Monatsvergleich (aktuell vs. Vormonat)
///  - Tagesdurchschnitt
class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  /// Kurze Monatsnamen aus den Lokalisierungen.
  /// Index 0 = Januar.
  static List<String> _monthShortLabels(AppLocalizations l10n) => <String>[
        l10n.statsMonthJan,
        l10n.statsMonthFeb,
        l10n.statsMonthMar,
        l10n.statsMonthApr,
        l10n.statsMonthMay,
        l10n.statsMonthJun,
        l10n.statsMonthJul,
        l10n.statsMonthAug,
        l10n.statsMonthSep,
        l10n.statsMonthOct,
        l10n.statsMonthNov,
        l10n.statsMonthDec,
      ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final monthShort = _monthShortLabels(l10n);
    final asyncCats = ref.watch(categoriesProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.statsTitle)),
      body: asyncCats.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(l10n.commonErrorWithDetail('$e'))),
        data: (categories) {
          final byId = <String, Category>{
            for (final c in categories) c.id: c,
          };
          // Aggregate kommen jetzt als FutureProvider aus dem Repo.
          // Bei lokaler SQLite typischerweise binnen eines Frames da;
          // bis dahin Fallback auf neutrale Defaults statt Spinner —
          // sonst flackert die ganze Seite bei jedem Range-Wechsel.
          final trend = ref.watch(monthlyTotalsProvider).valueOrNull ??
              const <MonthlyTotal>[];
          final mom = ref.watch(periodOverPeriodProvider).valueOrNull ??
              const PeriodOverPeriod(currentCents: 0, previousCents: 0);
          final dailyAvg =
              ref.watch(dailyAverageCentsProvider).valueOrNull ?? 0;
          final top =
              ref.watch(topCategoriesInSelectedRangeProvider).valueOrNull ??
                  const <CategorySpend>[];
          final spent =
              ref.watch(totalSpentInSelectedRangeProvider).valueOrNull ?? 0;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: <Widget>[
              _PeriodOverPeriodCard(
                  mom: mom, dailyAvgCents: dailyAvg, theme: theme),
              const SizedBox(height: 16),
              _SectionHeader(label: l10n.statsTrendTitle, theme: theme),
              SizedBox(
                height: 220,
                child: _TrendLineChart(
                  trend: trend,
                  theme: theme,
                  monthShort: monthShort,
                  emptyLabel: l10n.statsNoData,
                ),
              ),
              const SizedBox(height: 24),
              _SectionHeader(
                label: l10n.statsTopCategoriesTitle,
                theme: theme,
              ),
              if (top.isEmpty || spent == 0)
                _empty(theme, l10n.statsNoDataInRange)
              else
                SizedBox(
                  height: 240,
                  child: _CategoryDonut(
                    top: top,
                    byId: byId,
                    totalCents: spent,
                    theme: theme,
                    restLabel: l10n.statsRest,
                  ),
                ),
              if (top.isNotEmpty && spent != 0) ...<Widget>[
                const SizedBox(height: 12),
                for (final c in top.take(5))
                  _CategoryLegendRow(
                    category: byId[c.categoryId],
                    cents: c.totalCents,
                    totalCents: spent,
                  ),
              ],
              const SizedBox(height: 24),
              _SectionHeader(
                label: l10n.statsCategoryVsBudgetTitle,
                theme: theme,
              ),
              _CategoryVsBudget(theme: theme),
            ],
          );
        },
      ),
    );
  }

  Widget _empty(ThemeData theme, String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Text(
          text,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label, required this.theme});

  final String label;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _PeriodOverPeriodCard extends StatelessWidget {
  const _PeriodOverPeriodCard({
    required this.mom,
    required this.dailyAvgCents,
    required this.theme,
  });

  final PeriodOverPeriod mom;
  final int dailyAvgCents;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final pct = mom.diffPercent;
    final isUp = mom.diffCents > 0;
    final indicatorColor = mom.diffCents == 0
        ? theme.colorScheme.onSurfaceVariant
        : isUp
            ? theme.colorScheme.error
            : theme.colorScheme.primary;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    l10n.statsCurrentPeriod,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    CurrencyFormatter.formatCents(mom.currentCents),
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: <Widget>[
                      Icon(
                        mom.diffCents == 0
                            ? Icons.remove_rounded
                            : isUp
                                ? Icons.arrow_upward_rounded
                                : Icons.arrow_downward_rounded,
                        size: 16,
                        color: indicatorColor,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          pct == null
                              ? CurrencyFormatter.formatCents(
                                  mom.diffCents.abs())
                              : '${pct >= 0 ? '+' : ''}${pct.toStringAsFixed(1)} %  '
                                  '(${CurrencyFormatter.formatCents(mom.diffCents.abs())})',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: indicatorColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.statsPreviousPeriod(
                      CurrencyFormatter.formatCents(mom.previousCents),
                    ),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 1, height: 64,
              color: theme.colorScheme.outlineVariant,
              margin: const EdgeInsets.symmetric(horizontal: 12),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    l10n.statsDailyAverageTitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    CurrencyFormatter.formatCents(dailyAvgCents),
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.statsDailyAverageSubtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
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

class _TrendLineChart extends StatelessWidget {
  const _TrendLineChart({
    required this.trend,
    required this.theme,
    required this.monthShort,
    required this.emptyLabel,
  });

  final List<MonthlyTotal> trend;
  final ThemeData theme;
  final List<String> monthShort;
  final String emptyLabel;

  @override
  Widget build(BuildContext context) {
    if (trend.isEmpty) {
      return Center(
        child: Text(
          emptyLabel,
          style: theme.textTheme.bodySmall,
        ),
      );
    }
    final maxCents = trend
        .fold<int>(0, (m, t) => t.totalCents > m ? t.totalCents : m);
    final hasData = maxCents > 0;
    final maxY = hasData ? (maxCents / 100).ceilToDouble() : 100.0;
    final niceMax = maxY <= 0 ? 100.0 : _niceCeil(maxY);

    return LineChart(
      LineChartData(
        minY: 0,
        maxY: niceMax,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: niceMax / 4,
          getDrawingHorizontalLine: (_) => FlLine(
            color: theme.colorScheme.outlineVariant,
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 24,
              interval: 1,
              getTitlesWidget: (double value, TitleMeta meta) {
                final i = value.round();
                if (i < 0 || i >= trend.length) return const SizedBox.shrink();
                // Nur jeden zweiten Monatslabel zeigen, sonst zu eng.
                if (i.isOdd) return const SizedBox.shrink();
                final m = trend[i].month;
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    monthShort[m.month - 1],
                    style: theme.textTheme.labelSmall,
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 48,
              interval: niceMax / 4,
              getTitlesWidget: (double value, TitleMeta meta) => Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Text(
                  '${value.toStringAsFixed(0)} €',
                  style: theme.textTheme.labelSmall,
                ),
              ),
            ),
          ),
        ),
        lineBarsData: <LineChartBarData>[
          LineChartBarData(
            isCurved: true,
            curveSmoothness: 0.2,
            spots: <FlSpot>[
              for (int i = 0; i < trend.length; i++)
                FlSpot(i.toDouble(), trend[i].totalCents / 100),
            ],
            color: theme.colorScheme.primary,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, bar, index) =>
                  FlDotCirclePainter(
                radius: 3,
                color: theme.colorScheme.primary,
                strokeWidth: 0,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              color: theme.colorScheme.primary.withValues(alpha: 0.12),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (spots) => spots.map((s) {
              final i = s.x.round();
              final m = trend[i].month;
              return LineTooltipItem(
                '${monthShort[m.month - 1]} ${m.year}\n'
                '${CurrencyFormatter.formatCents(trend[i].totalCents)}',
                theme.textTheme.bodySmall ?? const TextStyle(),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  double _niceCeil(double v) {
    // Auf naechste 50, 100, 250, 500, 1000 etc. runden.
    final candidates = <double>[
      50, 100, 250, 500, 1000, 2500, 5000, 10000, 25000, 50000, 100000,
    ];
    for (final c in candidates) {
      if (v <= c) return c;
    }
    return ((v / 1000).ceil() * 1000).toDouble();
  }
}

class _CategoryDonut extends StatelessWidget {
  const _CategoryDonut({
    required this.top,
    required this.byId,
    required this.totalCents,
    required this.theme,
    required this.restLabel,
  });

  final List<CategorySpend> top;
  final Map<String, Category> byId;
  final int totalCents;
  final ThemeData theme;
  final String restLabel;

  @override
  Widget build(BuildContext context) {
    return PieChart(
      PieChartData(
        sectionsSpace: 2,
        centerSpaceRadius: 60,
        sections: <PieChartSectionData>[
          for (int i = 0; i < top.length && i < 5; i++)
            PieChartSectionData(
              value: top[i].totalCents.toDouble(),
              color: byId[top[i].categoryId]?.color ??
                  theme.colorScheme.primary,
              title: '${((top[i].totalCents / totalCents) * 100).round()}%',
              radius: 60,
              titleStyle: theme.textTheme.labelMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          if (top.length > 5)
            PieChartSectionData(
              value: top
                  .skip(5)
                  .fold<int>(0, (s, c) => s + c.totalCents)
                  .toDouble(),
              color: theme.colorScheme.outline,
              title: restLabel,
              radius: 50,
              titleStyle: theme.textTheme.labelSmall?.copyWith(
                color: Colors.white,
              ),
            ),
        ],
      ),
    );
  }
}

class _CategoryLegendRow extends StatelessWidget {
  const _CategoryLegendRow({
    required this.category,
    required this.cents,
    required this.totalCents,
  });

  final Category? category;
  final int cents;
  final int totalCents;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final pct = totalCents == 0 ? 0 : (cents * 100 / totalCents).round();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: <Widget>[
          Container(
            width: 12, height: 12,
            decoration: BoxDecoration(
              color: category?.color ?? theme.colorScheme.outline,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              category?.name ?? l10n.statsUnknown,
              style: theme.textTheme.bodyMedium,
            ),
          ),
          Text(
            '${CurrencyFormatter.formatCents(cents)}  ($pct %)',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// Horizontaler „Bar"-Vergleich: Ausgaben vs. Budget pro Kategorie.
/// Wir zeichnen eine LinearProgressIndicator pro Kategorie und sortieren
/// Ueberzogene zuerst – das ist visuell klarer als ein BarChart und
/// nachvollziehbar fuer den Nutzer.
class _CategoryVsBudget extends ConsumerWidget {
  const _CategoryVsBudget({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final cats = ref.watch(categoriesProvider).valueOrNull ?? const <Category>[];
    final byCat =
        ref.watch(spentByCategoryInSelectedRangeProvider).valueOrNull ??
            const <String, int>{};
    final visible = cats.where((c) => !c.isHidden).toList();
    if (visible.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Text(
          l10n.statsNoVisibleCategories,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    // Bauen: list of (cat, spent, budget) und sortieren nach Auslastung
    final rows = <_CatBudgetRow>[];
    for (final c in visible) {
      final budget =
          ref.watch(budgetByCategoryProvider(c.id))?.amountCents ?? 0;
      final spent = byCat[c.id] ?? 0;
      rows.add(_CatBudgetRow(category: c, spentCents: spent, budgetCents: budget));
    }
    rows.sort((a, b) {
      final ar = a.budgetCents == 0 ? 0.0 : a.spentCents / a.budgetCents;
      final br = b.budgetCents == 0 ? 0.0 : b.spentCents / b.budgetCents;
      return br.compareTo(ar);
    });

    return Column(
      children: <Widget>[
        for (final r in rows) r,
      ],
    );
  }
}

class _CatBudgetRow extends StatelessWidget {
  const _CatBudgetRow({
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
            : ratio > 0.85
                ? Colors.amber
                : category.color;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(category.icon, color: category.color, size: 16),
              const SizedBox(width: 6),
              Expanded(child: Text(category.name)),
              Text(
                hasBudget
                    ? '${CurrencyFormatter.formatCents(spentCents)} / '
                        '${CurrencyFormatter.formatCents(budgetCents)}'
                    : CurrencyFormatter.formatCents(spentCents),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: overspent ? theme.colorScheme.error : null,
                  fontWeight: overspent ? FontWeight.w600 : FontWeight.normal,
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
              semanticsLabel: l10n.statsCategoryUsageLabel,
              semanticsValue: hasBudget
                  ? l10n.dashboardPercentSpoken((ratio * 100).round())
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}
