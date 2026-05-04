import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/category.dart';
import '../../providers/categories_state.dart';
import 'category_picker_data.dart';

/// Bildschirm zum Anlegen oder Bearbeiten einer Kategorie.
/// Bei [existing] = null wird angelegt, sonst aktualisiert.
class CategoryEditScreen extends ConsumerStatefulWidget {
  const CategoryEditScreen({super.key, this.existing});

  final Category? existing;

  @override
  ConsumerState<CategoryEditScreen> createState() => _CategoryEditScreenState();
}

class _CategoryEditScreenState extends ConsumerState<CategoryEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late int _colorValue;
  late int _iconCodePoint;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _nameCtrl = TextEditingController(text: existing?.name ?? '');
    _colorValue = existing?.colorValue ?? CategoryPickerData.colors.first;
    _iconCodePoint = existing?.iconCodePoint ??
        CategoryPickerData.icons.first.codePoint;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final notifier = ref.read(categoriesProvider.notifier);
    final name = _nameCtrl.text.trim();

    final existing = widget.existing;
    if (existing == null) {
      await notifier.addCategory(
        name: name,
        colorValue: _colorValue,
        iconCodePoint: _iconCodePoint,
      );
    } else {
      await notifier.updateCategory(existing.copyWith(
        name: name,
        colorValue: _colorValue,
        iconCodePoint: _iconCodePoint,
      ));
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEdit = widget.existing != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Kategorie bearbeiten' : 'Neue Kategorie'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            // Vorschau
            Center(
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Color(_colorValue).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  IconData(_iconCodePoint, fontFamily: 'MaterialIcons'),
                  size: 40,
                  color: Color(_colorValue),
                ),
              ),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Name'),
              maxLength: 30,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Bitte einen Namen eingeben.';
                return null;
              },
            ),
            const SizedBox(height: 16),
            Text('Farbe', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                for (final c in CategoryPickerData.colors)
                  GestureDetector(
                    onTap: () => setState(() => _colorValue = c),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Color(c),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _colorValue == c
                              ? theme.colorScheme.onSurface
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text('Icon', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                for (final ico in CategoryPickerData.icons)
                  GestureDetector(
                    onTap: () =>
                        setState(() => _iconCodePoint = ico.codePoint),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: _iconCodePoint == ico.codePoint
                            ? Color(_colorValue).withValues(alpha: 0.15)
                            : theme.colorScheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        ico,
                        color: _iconCodePoint == ico.codePoint
                            ? Color(_colorValue)
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(isEdit ? 'Speichern' : 'Anlegen'),
            ),
          ],
        ),
      ),
    );
  }
}
