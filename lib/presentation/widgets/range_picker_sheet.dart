import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/expenses_state.dart';

/// Bottom-Sheet zur Range-Auswahl mit Quick-Presets und Custom-Picker.
///
/// Presets:
///  * "Diesen Monat" / "Letzten Monat"
///  * "Diese Woche" (Mo-So) / "Letzte 7 Tage"
///  * "Letzte 30 Tage" / "Heute"
///  * "Benutzerdefiniert..." -> oeffnet showDateRangePicker
Future<void> showRangePickerSheet(
  BuildContext context,
  WidgetRef ref,
  DateRange current,
) async {
  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (BuildContext ctx) => _RangePickerSheet(current: current),
  );
}

class _RangePickerSheet extends ConsumerWidget {
  const _RangePickerSheet({required this.current});

  final DateRange current;

  void _setRange(WidgetRef ref, DateRange r, BuildContext context) {
    ref.read(selectedDateRangeProvider.notifier).state = r;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final thisMonth = DateRange.calendarMonth(now);
    final lastMonth = DateRange.calendarMonth(DateTime(now.year, now.month - 1));
    // Woche (Mo - So). Dart: weekday 1=Mo .. 7=So.
    final mondayOfThisWeek =
        today.subtract(Duration(days: today.weekday - 1));
    final thisWeek = DateRange(
      from: mondayOfThisWeek,
      toExclusive: mondayOfThisWeek.add(const Duration(days: 7)),
    );
    final last7 = DateRange(
      from: today.subtract(const Duration(days: 6)),
      toExclusive: today.add(const Duration(days: 1)),
    );
    final last30 = DateRange(
      from: today.subtract(const Duration(days: 29)),
      toExclusive: today.add(const Duration(days: 1)),
    );
    final todayRange = DateRange.singleDay(today);

    final presets = <(String, DateRange)>[
      ('Heute', todayRange),
      ('Diese Woche', thisWeek),
      ('Letzte 7 Tage', last7),
      ('Diesen Monat', thisMonth),
      ('Letzten Monat', lastMonth),
      ('Letzte 30 Tage', last30),
    ];

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Zeitraum waehlen',
                style: theme.textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                for (final p in presets)
                  ChoiceChip(
                    selected: current == p.$2,
                    label: Text(p.$1),
                    onSelected: (_) => _setRange(ref, p.$2, context),
                  ),
              ],
            ),
            const Divider(height: 32),
            FilledButton.icon(
              onPressed: () async {
                final picked = await showDateRangePicker(
                  context: context,
                  firstDate: DateTime(2020),
                  lastDate:
                      DateTime.now().add(const Duration(days: 1)),
                  initialDateRange: DateTimeRange(
                    start: current.from,
                    end: current.toExclusive
                        .subtract(const Duration(days: 1)),
                  ),
                  helpText: 'Zeitraum waehlen',
                  saveText: 'Uebernehmen',
                );
                if (picked != null && context.mounted) {
                  _setRange(
                    ref,
                    DateRange.fromInclusive(picked.start, picked.end),
                    context,
                  );
                }
              },
              icon: const Icon(Icons.calendar_today_rounded),
              label: const Text('Benutzerdefiniert...'),
            ),
          ],
        ),
      ),
    );
  }
}
