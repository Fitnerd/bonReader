import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/data_providers.dart';
import '../../domain/entities/expense.dart';
import '../../domain/repositories/expense_repository.dart';

/// Page-Size fuer paginiertes Nachladen der Ausgabenliste.
const int kExpensesPageSize = 50;

/// Mutation-Notifier fuer Ausgaben.
///
/// Haelt **keine** Daten mehr im Speicher (vorher: `repo.getAll()`).
/// Stattdessen ist der State eine reine Versions-Nummer, die bei jeder
/// CRUD-Operation hochgezaehlt wird. Abgeleitete Provider (Pagination,
/// Aggregate) beobachten diese Version und re-fetchen sich aus dem Repo.
///
/// Damit bleibt die App auch bei >10 000 Eintraegen fluessig — die UI
/// laedt immer nur die sichtbare Page bzw. die SQL-Aggregate fuer den
/// gewaehlten Zeitraum, nicht mehr die komplette Tabelle in den Speicher.
class ExpensesNotifier extends Notifier<int> {
  @override
  int build() => 0;

  Future<Expense> addExpense(ExpenseDraft draft) async {
    final repo = await ref.read(expenseRepositoryProvider.future);
    final created = await repo.create(draft);
    state = state + 1;
    return created;
  }

  Future<Expense> updateExpense(Expense expense) async {
    final repo = await ref.read(expenseRepositoryProvider.future);
    final updated = await repo.update(expense);
    state = state + 1;
    return updated;
  }

  Future<void> deleteExpense(String id) async {
    final repo = await ref.read(expenseRepositoryProvider.future);
    await repo.delete(id);
    state = state + 1;
  }
}

final expensesProvider =
    NotifierProvider<ExpensesNotifier, int>(ExpensesNotifier.new);

// ─────────────────────────────────────────────────────────────────────
// Datums-Range
// ─────────────────────────────────────────────────────────────────────

/// Halbgeschlossenes Intervall `[from, toExclusive)`. Fuer Kalender-
/// Filter eindeutig (kein Off-by-one am Tagesende).
class DateRange {
  const DateRange({required this.from, required this.toExclusive});

  /// Kompletter Kalendermonat (1. 0:00 bis 1. des Folgemonats 0:00).
  factory DateRange.calendarMonth(DateTime any) => DateRange(
        from: DateTime(any.year, any.month),
        toExclusive: DateTime(any.year, any.month + 1),
      );

  /// Range fuer einen einzelnen Tag (00:00 bis naechster Tag 00:00).
  factory DateRange.singleDay(DateTime day) => DateRange(
        from: DateTime(day.year, day.month, day.day),
        toExclusive: DateTime(day.year, day.month, day.day + 1),
      );

  /// Range aus inklusivem Start- und End-Tag (z. B. aus
  /// `showDateRangePicker`, das `DateTimeRange.start/end` inklusiv liefert).
  factory DateRange.fromInclusive(DateTime startInclusive, DateTime endInclusive) =>
      DateRange(
        from: DateTime(startInclusive.year, startInclusive.month, startInclusive.day),
        toExclusive: DateTime(endInclusive.year, endInclusive.month, endInclusive.day + 1),
      );

  final DateTime from;
  final DateTime toExclusive;

  bool contains(DateTime t) => !t.isBefore(from) && t.isBefore(toExclusive);

  /// Anzahl Tage in der Range (inkl. from, exkl. toExclusive).
  int get days {
    final diffMs = toExclusive.difference(from).inMilliseconds;
    return (diffMs / Duration.millisecondsPerDay).round();
  }

  /// True, wenn die Range exakt einem Kalendermonat entspricht.
  bool get isCalendarMonth =>
      from.day == 1 &&
      toExclusive.day == 1 &&
      ((toExclusive.year - from.year) * 12 + (toExclusive.month - from.month)) == 1;

  /// Ein einziger Tag?
  bool get isSingleDay {
    final next = DateTime(from.year, from.month, from.day + 1);
    return toExclusive == next;
  }

  /// Verschiebt die Range um die eigene Laenge nach hinten - fuer
  /// "Vorperiode"-Vergleiche.
  DateRange shiftedBackByLength() {
    final length = toExclusive.difference(from);
    return DateRange(
      from: from.subtract(length),
      toExclusive: from,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DateRange &&
          other.from == from &&
          other.toExclusive == toExclusive;

  @override
  int get hashCode => Object.hash(from, toExclusive);
}

/// Aktuell ausgewaehlter Bereich. Default: aktueller Kalendermonat.
final selectedDateRangeProvider = StateProvider<DateRange>((ref) {
  return DateRange.calendarMonth(DateTime.now());
});

/// Lesbares Label fuer die aktuelle Range:
/// * Kalendermonat → "Mai 2026"
/// * Einzeltag     → "15.05.2026"
/// * sonst         → "01.05.–15.05.2026"
final selectedDateRangeLabelProvider = Provider<String>((ref) {
  final r = ref.watch(selectedDateRangeProvider);
  const months = <String>[
    'Januar', 'Februar', 'Maerz', 'April', 'Mai', 'Juni',
    'Juli', 'August', 'September', 'Oktober', 'November', 'Dezember',
  ];
  if (r.isCalendarMonth) {
    return '${months[r.from.month - 1]} ${r.from.year}';
  }
  String d2(int n) => n.toString().padLeft(2, '0');
  if (r.isSingleDay) {
    return '${d2(r.from.day)}.${d2(r.from.month)}.${r.from.year}';
  }
  // Letzter inklusiver Tag = toExclusive - 1 day
  final lastInclusive = r.toExclusive.subtract(const Duration(days: 1));
  // Wenn gleiches Jahr → Jahr nur einmal, sonst zweimal
  if (r.from.year == lastInclusive.year) {
    return '${d2(r.from.day)}.${d2(r.from.month)}.–'
        '${d2(lastInclusive.day)}.${d2(lastInclusive.month)}.${lastInclusive.year}';
  }
  return '${d2(r.from.day)}.${d2(r.from.month)}.${r.from.year}–'
      '${d2(lastInclusive.day)}.${d2(lastInclusive.month)}.${lastInclusive.year}';
});

// ─────────────────────────────────────────────────────────────────────
// Repo-Helper: Range → BETWEEN-kompatibles `to`
// ─────────────────────────────────────────────────────────────────────

/// Die Repo-Aggregat-Methoden nutzen `BETWEEN ? AND ?` (inklusiv beidseitig).
/// `DateRange.toExclusive` ist halb-offen (Element exakt am Boundary
/// gehoert *nicht* zur Range). Wir konvertieren beim Aufruf in den
/// "letzten inklusiven Moment", sodass sich Aggregate exakt wie das
/// alte In-Memory-`r.contains(t)` verhalten.
DateTime _inclusiveTo(DateRange r) =>
    r.toExclusive.subtract(const Duration(milliseconds: 1));

// ─────────────────────────────────────────────────────────────────────
// Pagination der Ausgabenliste (DESC nach Datum, gefiltert auf Range)
// ─────────────────────────────────────────────────────────────────────

@immutable
class PagedExpensesState {
  const PagedExpensesState({
    required this.items,
    required this.total,
    required this.hasMore,
    required this.loadingMore,
  });

  final List<Expense> items;

  /// Gesamtzahl der Eintraege in der aktuellen Range (vom Repo geliefert).
  final int total;

  /// `true`, solange es weitere Pages zu laden gibt.
  final bool hasMore;

  /// `true`, solange `loadMore()` einen Page-Fetch laufen hat.
  final bool loadingMore;

  PagedExpensesState copyWith({
    List<Expense>? items,
    int? total,
    bool? hasMore,
    bool? loadingMore,
  }) =>
      PagedExpensesState(
        items: items ?? this.items,
        total: total ?? this.total,
        hasMore: hasMore ?? this.hasMore,
        loadingMore: loadingMore ?? this.loadingMore,
      );

  static const PagedExpensesState empty = PagedExpensesState(
    items: <Expense>[],
    total: 0,
    hasMore: false,
    loadingMore: false,
  );
}

/// Notifier fuer die paginierte Ausgabenliste der ausgewaehlten Range.
///
/// Build laedt die erste Page (`kExpensesPageSize` Eintraege) und das
/// Gesamt-Count via `getCountInRange`. `loadMore()` haengt die naechste
/// Page hinten an. Der Notifier rebuildet automatisch, wenn:
///  - die Range gewechselt wird (`selectedDateRangeProvider`)
///  - Daten geaendert werden (CRUD im `expensesProvider` bumpt Version)
class PagedExpensesNotifier extends AsyncNotifier<PagedExpensesState> {
  @override
  Future<PagedExpensesState> build() async {
    final range = ref.watch(selectedDateRangeProvider);
    // Re-fetch nach jeder CRUD-Mutation:
    ref.watch(expensesProvider);
    final repo = await ref.watch(expenseRepositoryProvider.future);
    final to = _inclusiveTo(range);
    final total = await repo.getCountInRange(range.from, to);
    final items = await repo.getPageInRange(
      from: range.from,
      to: to,
      offset: 0,
      limit: kExpensesPageSize,
    );
    return PagedExpensesState(
      items: items,
      total: total,
      hasMore: items.length < total,
      loadingMore: false,
    );
  }

  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null) return;
    if (!current.hasMore || current.loadingMore) return;

    state = AsyncData(current.copyWith(loadingMore: true));

    final range = ref.read(selectedDateRangeProvider);
    final repo = await ref.read(expenseRepositoryProvider.future);
    final to = _inclusiveTo(range);
    final more = await repo.getPageInRange(
      from: range.from,
      to: to,
      offset: current.items.length,
      limit: kExpensesPageSize,
    );
    final newItems = <Expense>[...current.items, ...more];
    state = AsyncData(current.copyWith(
      items: newItems,
      hasMore: newItems.length < current.total,
      loadingMore: false,
    ));
  }
}

final pagedExpensesProvider =
    AsyncNotifierProvider<PagedExpensesNotifier, PagedExpensesState>(
  PagedExpensesNotifier.new,
);

// ─────────────────────────────────────────────────────────────────────
// Aggregate (alle aus dem Repo, nicht mehr aus In-Memory-Liste).
// Hangen alle an selectedDateRangeProvider + expensesProvider (Version).
// ─────────────────────────────────────────────────────────────────────

/// Summe der Ausgaben in der ausgewaehlten Range (Cent).
final totalSpentInSelectedRangeProvider = FutureProvider<int>((ref) async {
  final range = ref.watch(selectedDateRangeProvider);
  ref.watch(expensesProvider);
  final repo = await ref.watch(expenseRepositoryProvider.future);
  return repo.getTotalCents(range.from, _inclusiveTo(range));
});

/// Summe pro Kategorie in der ausgewaehlten Range.
final spentByCategoryInSelectedRangeProvider =
    FutureProvider<Map<String, int>>((ref) async {
  final range = ref.watch(selectedDateRangeProvider);
  ref.watch(expensesProvider);
  final repo = await ref.watch(expenseRepositoryProvider.future);
  return repo.getTotalsByCategory(range.from, _inclusiveTo(range));
});

/// Tagesdurchschnitt in der Range.
/// * Wenn die Range in der Zukunft endet (z. B. aktueller Monat ist
///   gewaehlt), teilen wir nur durch die bisher vergangenen Tage.
/// * Sonst durch die volle Range-Laenge.
final dailyAverageCentsProvider = FutureProvider<int>((ref) async {
  final spent = await ref.watch(totalSpentInSelectedRangeProvider.future);
  final r = ref.watch(selectedDateRangeProvider);
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final fullDays = r.days;
  // Wenn Range schon komplett vergangen → durch volle Laenge teilen.
  if (!today.isBefore(r.toExclusive)) {
    if (fullDays <= 0) return 0;
    return (spent / fullDays).round();
  }
  // Wenn Range erst noch beginnt → 0.
  if (today.isBefore(r.from)) return 0;
  // Sonst: Range laeuft gerade. Teiler = Tage seit from einschliesslich heute.
  final elapsed = today.difference(r.from).inDays + 1;
  if (elapsed <= 0) return 0;
  return (spent / elapsed).round();
});

/// Top-Kategorien in der ausgewaehlten Range (sortiert, mit cents).
@immutable
class CategorySpend {
  const CategorySpend({required this.categoryId, required this.totalCents});
  final String categoryId;
  final int totalCents;
}

final topCategoriesInSelectedRangeProvider =
    FutureProvider<List<CategorySpend>>((ref) async {
  final byCat = await ref.watch(spentByCategoryInSelectedRangeProvider.future);
  final list = byCat.entries
      .map((e) => CategorySpend(categoryId: e.key, totalCents: e.value))
      .toList()
    ..sort((a, b) => b.totalCents.compareTo(a.totalCents));
  return list;
});

// ─────────────────────────────────────────────────────────────────────
// Trend-Diagramme: 12 Monate zurueck (anchor = letzter Monat der Range)
// ─────────────────────────────────────────────────────────────────────

@immutable
class MonthlyTotal {
  const MonthlyTotal({required this.month, required this.totalCents});
  final DateTime month;
  final int totalCents;
}

/// Liste der letzten 12 Kalendermonate mit Summe pro Monat,
/// chronologisch (aelteste zuerst). Anker ist der Monat von [from].
///
/// Implementierung: 12 SQL-Aggregate parallel (`Future.wait`). Bei
/// lokaler SQLite uneingeschraenkt schnell, dafuer kein In-Memory-Pass
/// mehr ueber die volle Tabelle.
final monthlyTotalsProvider =
    FutureProvider<List<MonthlyTotal>>((ref) async {
  final r = ref.watch(selectedDateRangeProvider);
  ref.watch(expensesProvider);
  final repo = await ref.watch(expenseRepositoryProvider.future);
  final anchor = DateTime(r.from.year, r.from.month);
  final months = <DateTime>[
    for (int i = 11; i >= 0; i--) DateTime(anchor.year, anchor.month - i),
  ];
  final totals = await Future.wait<int>(months.map((m) {
    final monthStart = m;
    final monthEndExclusive = DateTime(m.year, m.month + 1);
    return repo.getTotalCents(
      monthStart,
      monthEndExclusive.subtract(const Duration(milliseconds: 1)),
    );
  }));
  return <MonthlyTotal>[
    for (int i = 0; i < months.length; i++)
      MonthlyTotal(month: months[i], totalCents: totals[i]),
  ];
});

// ─────────────────────────────────────────────────────────────────────
// Vorperioden-Vergleich
// ─────────────────────────────────────────────────────────────────────

/// Vergleich: aktuelle Range vs. unmittelbar davor liegende Range
/// gleicher Laenge.
@immutable
class PeriodOverPeriod {
  const PeriodOverPeriod({
    required this.currentCents,
    required this.previousCents,
  });

  final int currentCents;
  final int previousCents;

  int get diffCents => currentCents - previousCents;

  /// Prozentuale Differenz (Vorperiode = Basis). Null, wenn Basis == 0.
  double? get diffPercent {
    if (previousCents == 0) return null;
    return (diffCents / previousCents) * 100;
  }
}

final periodOverPeriodProvider =
    FutureProvider<PeriodOverPeriod>((ref) async {
  final current = ref.watch(selectedDateRangeProvider);
  ref.watch(expensesProvider);
  final repo = await ref.watch(expenseRepositoryProvider.future);
  final previous = current.shiftedBackByLength();

  final results = await Future.wait<int>(<Future<int>>[
    repo.getTotalCents(current.from, _inclusiveTo(current)),
    repo.getTotalCents(previous.from, _inclusiveTo(previous)),
  ]);
  return PeriodOverPeriod(
    currentCents: results[0],
    previousCents: results[1],
  );
});
