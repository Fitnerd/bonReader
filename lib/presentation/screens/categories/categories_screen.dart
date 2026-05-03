import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/categories_state.dart';
import 'category_edit_screen.dart';

class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key});

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    String id,
    String name,
    bool isDefault,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: Text('„$name" entfernen?'),
        content: Text(
          isDefault
              ? 'Default-Kategorien werden nur ausgeblendet, damit deine bisherigen Ausgaben weiterhin korrekt zugeordnet sind. Du kannst sie spaeter wieder einblenden.'
              : 'Die Kategorie wird endgueltig geloescht. Bestehende Ausgaben in dieser Kategorie verhindern das Loeschen.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Entfernen'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(categoriesProvider.notifier).deleteCategory(id);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncCats = ref.watch(categoriesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Kategorien')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(MaterialPageRoute<void>(
            builder: (_) => const CategoryEditScreen(),
          ));
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text('Neu'),
      ),
      body: asyncCats.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Fehler: $e')),
        data: (categories) {
          if (categories.isEmpty) {
            return const Center(child: Text('Noch keine Kategorien.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: categories.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (BuildContext ctx, int i) {
              final c = categories[i];
              return ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: c.color.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(c.icon, color: c.color),
                ),
                title: Text(c.name),
                subtitle: Text(<String>[
                  if (c.isDefault) 'Standard',
                  if (c.isHidden) 'Ausgeblendet',
                ].join(' · ')),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    IconButton(
                      icon: const Icon(Icons.edit_rounded),
                      onPressed: () {
                        Navigator.of(ctx).push(MaterialPageRoute<void>(
                          builder: (_) => CategoryEditScreen(existing: c),
                        ));
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded),
                      onPressed: () => _confirmDelete(
                        ctx,
                        ref,
                        c.id,
                        c.name,
                        c.isDefault,
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
