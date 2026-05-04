import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/data_providers.dart';
import '../../domain/entities/expense.dart';
import '../../domain/repositories/expense_repository.dart';

/// Notifier fuer alle Ausgaben.
///
/// Haelt absichtlich die volle Liste vor (lokal, kein Server, keine Pagination
/// bei haushaltsueblichen Mengen relevant). Abgeleitete Provider filtern dann
/// nach Datums-Range / Kategorie / etc.
class ExpensesNotifier extends AsyncNotifier<List<Expense>> {
  @override
  Future<List<Expense>> build() async {
    final repo = await ref.watch(expenseRepositoryProvider.future);
    return repo.getAll();
  }

  Future<Expense> addExpense(ExpenseDraft draft) async {
    final repo = await ref.read(expenseRepositoryProvider.future);
    final created = await repo.create(draft);
    ref.invalidateSelf();
    return created;
  }

  Future<Expense> updateExpense(Expense expense) async {
    final repo = await ref.read(expenseRepositoryProvider.future);
    final updated = await repo.update(expense);
    ref.invalidateSelf();
    return updated;
  }

  Future<void> deleteExpense(String id) async {
    final repo = await ref.read(expenseRepositoryProvider.future);
    await repo.delete(id);
    ref.invalidateSelf();
  }
}

final expensesProvider =
    AsyncNotifierProvider<ExpensesNotifier, List<Expense>>(
  ExpensesNotifier.new,
);

// ─────────────────────────────────────────────────────────────────────
// Datums-Range
// ─────────────────────────────────────────────────────────────────────

/// Halbgeschlossenes Intervall `[from, toExclusive)`. Fuer Kalender-
/// Filter eindeutig (kein Off-by-one am Tagesende).
class DateRange {
  const DateRange({required this.from, required this.toExclusive})
      : assert(from != toExclusive || from == toExclusive);

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
    return '\${months[r.from.month - 1]} \${r.from.year}';
  }
  String d2(int n) => n.toString().padLeft(2, '0');
  if (r.isSingleDay) {
    return '\${d2(r.from.day)}.\${d2(r.from.month)}.\${r.from.year}';
  }
  // Letzter inklusiver Tag = toExclusive - 1 day
  final lastInclusive = r.toExclusive.subtract(const Duration(days: 1));
  // Wenn gleiches Jahr → Jahr nur einmal, sonst zweimal
  if (r.from.year == lastInclusive.year) {
    return '\${d2(r.from.day)}.\${d2(r.from.month)}.–'
        '\${d2(lastInclusive.day)}.\${d2(lastInclusive.month)}.\${lastInclusive.year}';
  }
  return '\${d2(r.from.day)}.\${d2(r.from.month)}.\${r.from.year}–'
      '\${d2(lastInclusive.day)}.\${d2(lastInclusive.month)}.\${lastInclusive.year}';
});

// ─────────────────────────────────────────────────────────────────────
// Range-basierte Provider
// ─────────────────────────────────────────────────────────────────────

/// Ausgaben in der ausgewaehlten Range, neueste zuerst.
final expensesInSelectedRangeProvider = Provider<List<Expense>>((ref) {
  final all = ref.watch(expensesProvider).valueOrNull ?? const <Expense>[];
  final r = ref.watch(selectedDateRangeProvider);
  return all.where((e) => r.contains(e.occurredAt)).toList(growable: false);
});

/// Summe der Ausgaben in der ausgewaehlten Range (Cent).
final totalSpentInSelectedRangeProvider = Provider<int>((ref) {
  final list = ref.watch(expensesInSelectedRangeProvider);
  return list.fold<int>(0, (sum, e) => sum + e.totalCents);
});

/// Summe pro Kategorie in der ausgewaehlten Range.
final spentByCategoryInSelectedRangeProvider =
    Provider<Map<String, int>>((ref) {
  final list = ref.watch(expensesInSelectedRangeProvider);
  final map = <String, int>{};
  for (final e in list) {
    map[e.categoryId] = (map[e.categoryId] ?? 0) + e.totalCents;
  }
  return map;
});

/// Tagesdurchschnitt in der Range.
/// * Wenn die Range in der Zukunft endet (z. B. aktueller Monat ist
///   gewaehlt), teilen wir nur durch die bisher vergangenen Tage.
/// * Sonst durch die volle Range-Laenge.
final dailyAverageCentsProvider = Provider<int>((ref) {
  final spent = ref.watch(totalSpentInSelectedRangeProvider);
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
class CategorySpend {
  const CategorySpend({required this.categoryId, required this.totalCents});
  final String categoryId;
  final int totalCents;
}

final topCategoriesInSelectedRangeProvider =
    Provider<List<CategorySpend>>((ref) {
  final byCat = ref.watch(spentByCategoryInSelectedRangeProvider);
  final list = byCat.entries
      .map((e) => CategorySpend(categoryId: e.key, totalCents: e.value))
      .toList()
    ..sort((a, b) => b.totalCents.compareTo(a.totalCents));
  return list;
});

// ─────────────────────────────────────────────────────────────────────
// Trend-Diagramme: 12 Monate zurueck (anchor = letzter Monat der Range)
// ─────────────────────────────────────────────────────────────────────

class MonthlyTotal {
  const MonthlyTotal({required this.month, required this.totalCents});
  final DateTime month;
  final int totalCents;
}

/// Liste der letzten 12 Kalendermonate mit Summe pro Monat,
/// chronologisch (aelteste zuerst). Anker ist der Monat von [from].
final monthlyTotalsProvider = Provider<List<MonthlyTotal>>((ref) {
  final all = ref.watch(expensesProvider).valueOrNull ?? const <Expense>[];
  final r = ref.watch(selectedDateRangeProvider);
  final anchor = DateTime(r.from.year, r.from.month);
  final months = <DateTime>[
    for (int i = 11; i >= 0; i--)
      DateTime(anchor.year, anchor.month - i),
  ];
  return <MonthlyTotal>[
    for (final m in months)
      MonthlyTotal(
        month: m,
        totalCents: all
            .where((e) =>
                e.occurredAt.year == m.year && e.occurredAt.month == m.month)
            .fold<int>(0, (sum, e) => sum + e.totalCents),
      ),
  ];
});

// ─────────────────────────────────────────────────────────────────────
// Vorperioden-Vergleich
// ─────────────────────────────────────────────────────────────────────

/// Vergleich: aktuelle Range vs. unmittelbar davor liegende Range
/// gleicher Laenge.
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

final periodOverPeriodProvider = Provider<PeriodOverPeriod>((ref) {
  final all = ref.watch(expensesProvider).valueOrNull ?? const <Expense>[];
  final current = ref.watch(selectedDateRangeProvider);
  final previous = current.shiftedBackByLength();

  int sumIn(DateRange r) =>
      all.where((e) => r.contains(e.occurredAt)).fold<int>(0, (s, e) => s + e.totalCents);

  return PeriodOverPeriod(
    currentCents: sumIn(current),
    previousCents: sumIn(previous),
  );
});

// ─────────────────────────────────────────────────────────────────────
// Backward-Compat-Aliase. Die alten "Monat"-Provider zeigen jetzt auf
// die Range-Provider; UI/Tests sollten auf die Range-Namen umsteigen,
// die Alias-Provider machen den Migrationspfad weicher.
// ─────────────────────────────────────────────────────────────────────

@Deprecated('Use selectedDateRangeProvider')
final selectedMonthProvider = StateProvider<DateTime>((ref) {
  // Wir spiegeln den 1. des Range-Monats. Schreibzugriffe auf diesen
  // Alias gehen verloren - bewusst, damit niemand parallele Quellen
  // bedient.
  final r = ref.watch(selectedDateRangeProvider);
  return DateTime(r.from.year, r.from.month);
});

@Deprecated('Use expensesInSelectedRangeProvider')
final expensesInSelectedMonthProvider = expensesInSelectedRangeProvider;

@Deprecated('Use totalSpentInSelectedRangeProvider')
final totalSpentInSelectedMonthProvider = totalSpentInSelectedRangeProvider;

@Deprecated('Use spentByCategoryInSelectedRangeProvider')
final spentByCategoryInSelectedMonthProvider = spentByCategoryInSelectedRangeProvider;

@Deprecated('Use topCategoriesInSelectedRangeProvider')
final topCategoriesInSelectedMonthProvider = topCategoriesInSelectedRangeProvider;

@Deprecated('Use periodOverPeriodProvider')
typedef MonthOverMonth = PeriodOverPeriod;

@Deprecated('Use periodOverPeriodProvider')
final monthOverMonthProvider = periodOverPeriodProvider;
