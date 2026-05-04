import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/currency_formatter.dart';
import '../../../domain/entities/category.dart';
import '../../../domain/entities/expense.dart';
import '../../../domain/entities/expense_item.dart';
import '../../../domain/repositories/expense_repository.dart';
import '../../providers/categories_state.dart';
import '../../providers/expenses_state.dart';

/// Vor-Auswertung eines Bons (vom OCR-Parser), die als Vorlage in das
/// Formular geht. Im Gegensatz zu [Expense] gibt es keine ID, weil
/// noch nichts persistiert wurde.
class ExpensePrefill {
  const ExpensePrefill({
    required this.merchant,
    required this.occurredAt,
    required this.totalCents,
    required this.items,
    this.categoryId,
  });

  final String merchant;
  final DateTime occurredAt;
  final int totalCents;
  final List<ExpenseItemDraft> items;
  final String? categoryId;
}

/// Formular zum Anlegen oder Bearbeiten einer Ausgabe.
///
/// Drei Modi:
/// * `existing != null`  → Bearbeiten (update)
/// * `prefill != null`   → Neu, mit OCR-Werten vorbefuellt (add)
/// * sonst                → Neu, leer (add)
///
/// Wenn der Nutzer Positionen erfasst, ist `totalCents` deren Summe.
/// Wenn keine Positionen, gibt es ein einzelnes Gesamtfeld.
class ExpenseFormScreen extends ConsumerStatefulWidget {
  const ExpenseFormScreen({super.key, this.existing, this.prefill})
      : assert(existing == null || prefill == null,
            'existing und prefill duerfen nicht beide gesetzt sein');

  final Expense? existing;
  final ExpensePrefill? prefill;

  @override
  ConsumerState<ExpenseFormScreen> createState() => _ExpenseFormScreenState();
}

class _ExpenseFormScreenState extends ConsumerState<ExpenseFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _merchantCtrl;
  late final TextEditingController _noteCtrl;
  late final TextEditingController _totalCtrl;

  late DateTime _occurredAt;
  String? _categoryId;

  /// Drafts fuer Positionen, jeweils mit eigenen Controllern,
  /// damit Eingaben live mitlaufen koennen.
  final List<_ItemDraft> _items = <_ItemDraft>[];

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    final prefill = widget.prefill;
    final initialMerchant = existing?.merchant ?? prefill?.merchant ?? '';
    final initialNote = existing?.note ?? '';
    final initialTotalCents = existing?.totalCents ?? prefill?.totalCents ?? 0;
    _merchantCtrl = TextEditingController(text: initialMerchant);
    _noteCtrl = TextEditingController(text: initialNote);
    _totalCtrl = TextEditingController(
      text: initialTotalCents == 0
          ? ''
          : (initialTotalCents / 100).toStringAsFixed(2).replaceAll('.', ','),
    );
    _occurredAt = existing?.occurredAt ?? prefill?.occurredAt ?? DateTime.now();
    _categoryId = existing?.categoryId ?? prefill?.categoryId;
    if (existing != null) {
      for (final i in existing.items) {
        _items.add(_ItemDraft.fromItem(i));
      }
    } else if (prefill != null) {
      for (final i in prefill.items) {
        _items.add(_ItemDraft.fromDraft(i));
      }
    }
  }

  @override
  void dispose() {
    _merchantCtrl.dispose();
    _noteCtrl.dispose();
    _totalCtrl.dispose();
    for (final i in _items) {
      i.dispose();
    }
    super.dispose();
  }

  bool get _hasItems => _items.isNotEmpty;

  int get _itemsTotalCents =>
      _items.fold<int>(0, (sum, i) => sum + (i.totalCents ?? 0));

  int? get _effectiveTotalCents {
    // Manuelle Eingabe hat Vorrang. Wenn das Feld leer ist UND Positionen
    // existieren, faellt es auf die Item-Summe zurueck.
    final manual = CurrencyFormatter.parseToCents(_totalCtrl.text);
    if (manual != null && manual > 0) return manual;
    if (_hasItems) return _itemsTotalCents;
    return null;
  }

  Future<void> _pickDate() async {
    final result = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      initialDate: _occurredAt,
    );
    if (result != null) {
      setState(() {
        _occurredAt = DateTime(
          result.year,
          result.month,
          result.day,
          _occurredAt.hour,
          _occurredAt.minute,
        );
      });
    }
  }

  void _addItem() {
    setState(() => _items.add(_ItemDraft.empty()));
  }

  void _removeItem(int index) {
    setState(() {
      _items.removeAt(index).dispose();
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_categoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bitte eine Kategorie waehlen.')),
      );
      return;
    }
    final total = _effectiveTotalCents;
    if (total == null || total <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Betrag muss groesser 0 sein.')),
      );
      return;
    }

    setState(() => _saving = true);
    final notifier = ref.read(expensesProvider.notifier);

    try {
      final existing = widget.existing;
      if (existing == null) {
        final draft = ExpenseDraft(
          categoryId: _categoryId!,
          totalCents: total,
          merchant: _merchantCtrl.text.trim(),
          occurredAt: _occurredAt,
          note: _noteCtrl.text.trim(),
          items: _items
              .map((i) => ExpenseItemDraft(
                    name: i.nameCtrl.text.trim(),
                    quantity: i.quantity,
                    unitPriceCents: i.unitPriceCents ?? 0,
                    totalCents: i.totalCents ?? 0,
                  ))
              .toList(growable: false),
        );
        await notifier.addExpense(draft);
      } else {
        // Update: wir bauen Items mit (alten oder neuen) IDs.
        final items = _items
            .map((i) => ExpenseItem(
                  id: i.id ?? UniqueKey().toString(),
                  expenseId: existing.id,
                  name: i.nameCtrl.text.trim(),
                  quantity: i.quantity,
                  unitPriceCents: i.unitPriceCents ?? 0,
                  totalCents: i.totalCents ?? 0,
                ))
            .toList(growable: false);
        final updated = existing.copyWith(
          categoryId: _categoryId,
          totalCents: total,
          merchant: _merchantCtrl.text.trim(),
          occurredAt: _occurredAt,
          note: _noteCtrl.text.trim(),
          items: items,
        );
        await notifier.updateExpense(updated);
      }
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler beim Speichern: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEdit = widget.existing != null;
    final isPrefill = widget.prefill != null;
    final asyncCats = ref.watch(visibleCategoriesProvider);
    final title = isEdit
        ? 'Ausgabe bearbeiten'
        : isPrefill
            ? 'Ausgabe pruefen & speichern'
            : 'Neue Ausgabe';

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: asyncCats.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Fehler: $e')),
        data: (categories) {
          if (categories.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Keine sichtbaren Kategorien. Bitte erst eine Kategorie '
                  'anlegen.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          // Initiale Kategorie setzen, wenn noch keine ausgewaehlt.
          _categoryId ??= categories.first.id;

          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: <Widget>[
                _SectionHeader(theme: theme, label: 'Allgemein'),
                TextFormField(
                  controller: _merchantCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Haendler',
                    hintText: 'z. B. Rewe, Aldi',
                  ),
                  textCapitalization: TextCapitalization.words,
                  maxLength: 50,
                ),
                const SizedBox(height: 8),
                _CategoryDropdown(
                  categories: categories,
                  value: _categoryId,
                  onChanged: (id) => setState(() => _categoryId = id),
                ),
                const SizedBox(height: 12),
                _DatePickerRow(
                  date: _occurredAt,
                  onTap: _pickDate,
                ),
                const SizedBox(height: 16),
                _SectionHeader(theme: theme, label: 'Betrag'),
                // Live-Summe aus Positionen (nur wenn welche existieren)
                if (_hasItems)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: <Widget>[
                        const Icon(Icons.functions_rounded),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Aus Positionen: '
                            '${CurrencyFormatter.formatCents(_itemsTotalCents)}',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: theme.colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (_hasItems) const SizedBox(height: 8),
                // Gesamtbetrag IMMER editierbar. Bei OCR-Vorbefuellung zeigt
                // er den vom Bon erkannten Total; der Nutzer kann ihn ueber-
                // schreiben oder auf 'leer' setzen, dann wird die Item-Summe
                // genommen.
                TextFormField(
                  controller: _totalCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: _hasItems
                        ? 'Gesamtbetrag (ueberschreibt Positionen-Summe)'
                        : 'Gesamtbetrag',
                    suffixText: '€',
                    hintText: '0,00',
                  ),
                  onChanged: (_) => setState(() {}),
                  validator: (v) {
                    final manual = CurrencyFormatter.parseToCents(v ?? '');
                    // Wenn Items da sind, akzeptieren wir leer (-> items sum)
                    if (_hasItems && (v == null || v.trim().isEmpty)) {
                      return null;
                    }
                    if (manual == null || manual <= 0) {
                      return 'Bitte einen Betrag > 0 eingeben';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _SectionHeader(
                  theme: theme,
                  label: 'Positionen (optional)',
                  trailing: TextButton.icon(
                    onPressed: _addItem,
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Hinzufuegen'),
                  ),
                ),
                if (_items.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'Keine Positionen erfasst. Wenn du den Bon abfotografierst, '
                      'fuellt der OCR-Parser das automatisch.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  )
                else
                  for (int i = 0; i < _items.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _ItemRow(
                        draft: _items[i],
                        onChanged: () => setState(() {}),
                        onRemove: () => _removeItem(i),
                      ),
                    ),
                const SizedBox(height: 16),
                _SectionHeader(theme: theme, label: 'Notiz (optional)'),
                TextFormField(
                  controller: _noteCtrl,
                  decoration: const InputDecoration(
                    hintText: 'z. B. Wocheneinkauf',
                  ),
                  maxLines: 2,
                  maxLength: 200,
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(isEdit ? 'Speichern' : 'Ausgabe anlegen'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.theme,
    required this.label,
    this.trailing,
  });

  final ThemeData theme;
  final String label;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 8),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class _CategoryDropdown extends StatelessWidget {
  const _CategoryDropdown({
    required this.categories,
    required this.value,
    required this.onChanged,
  });

  final List<Category> categories;
  final String? value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: const InputDecoration(labelText: 'Kategorie'),
      items: <DropdownMenuItem<String>>[
        for (final c in categories)
          DropdownMenuItem<String>(
            value: c.id,
            child: Row(
              children: <Widget>[
                Icon(c.icon, color: c.color, size: 20),
                const SizedBox(width: 8),
                Text(c.name),
              ],
            ),
          ),
      ],
      onChanged: onChanged,
    );
  }
}

class _DatePickerRow extends StatelessWidget {
  const _DatePickerRow({required this.date, required this.onTap});

  final DateTime date;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formatted =
        '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: InputDecorator(
        decoration: const InputDecoration(labelText: 'Datum'),
        child: Row(
          children: <Widget>[
            Expanded(child: Text(formatted)),
            Icon(Icons.calendar_today_rounded,
                color: theme.colorScheme.onSurfaceVariant, size: 20),
          ],
        ),
      ),
    );
  }
}

/// Mutabler Draft fuer eine Position im Formular.
/// Halt Controller, damit Eingaben sauber editiert werden koennen.
class _ItemDraft {
  _ItemDraft({
    this.id,
    required this.nameCtrl,
    required this.priceCtrl,
    required this.quantity,
  });

  factory _ItemDraft.empty() => _ItemDraft(
        nameCtrl: TextEditingController(),
        priceCtrl: TextEditingController(),
        quantity: 1,
      );

  factory _ItemDraft.fromItem(ExpenseItem item) => _ItemDraft(
        id: item.id,
        nameCtrl: TextEditingController(text: item.name),
        priceCtrl: TextEditingController(
          text: (item.totalCents / 100).toStringAsFixed(2).replaceAll('.', ','),
        ),
        quantity: item.quantity,
      );

  /// Aus OCR-Pre-Fill (noch keine ID, wird beim Speichern vergeben).
  factory _ItemDraft.fromDraft(ExpenseItemDraft d) => _ItemDraft(
        nameCtrl: TextEditingController(text: d.name),
        priceCtrl: TextEditingController(
          text: (d.totalCents / 100).toStringAsFixed(2).replaceAll('.', ','),
        ),
        quantity: d.quantity,
      );

  final String? id;
  final TextEditingController nameCtrl;
  final TextEditingController priceCtrl;
  double quantity;

  int? get totalCents => CurrencyFormatter.parseToCents(priceCtrl.text);

  /// Bei manueller Eingabe gibt es keinen separaten Stueckpreis,
  /// wir setzen ihn = totalCents / quantity (gerundet) wenn moeglich.
  int? get unitPriceCents {
    final t = totalCents;
    if (t == null) return null;
    if (quantity <= 0) return t;
    return (t / quantity).round();
  }

  void dispose() {
    nameCtrl.dispose();
    priceCtrl.dispose();
  }
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({
    required this.draft,
    required this.onChanged,
    required this.onRemove,
  });

  final _ItemDraft draft;
  final VoidCallback onChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
        child: Row(
          children: <Widget>[
            Expanded(
              flex: 3,
              child: TextField(
                controller: draft.nameCtrl,
                decoration: const InputDecoration(
                  hintText: 'Position',
                  isDense: true,
                ),
                textCapitalization: TextCapitalization.sentences,
                onChanged: (_) => onChanged(),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: TextField(
                controller: draft.priceCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                textAlign: TextAlign.end,
                decoration: const InputDecoration(
                  hintText: '0,00',
                  suffixText: '€',
                  isDense: true,
                ),
                onChanged: (_) => onChanged(),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close_rounded),
              tooltip: 'Position entfernen',
              onPressed: onRemove,
            ),
          ],
        ),
      ),
    );
  }
}
