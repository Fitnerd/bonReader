import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
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
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: Text(l10n.categoriesDeleteTitle(name)),
        content: Text(
          isDefault
              ? l10n.categoriesDeleteBodyDefault
              : l10n.categoriesDeleteBodyCustom,
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.commonRemove),
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
    final l10n = AppLocalizations.of(context)!;
    final asyncCats = ref.watch(categoriesProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.categoriesTitle)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(MaterialPageRoute<void>(
            builder: (_) => const CategoryEditScreen(),
          ));
        },
        icon: const Icon(Icons.add_rounded),
        label: Text(l10n.commonNew),
      ),
      body: asyncCats.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(l10n.commonErrorWithDetail('$e'))),
        data: (categories) {
          if (categories.isEmpty) {
            return Center(child: Text(l10n.categoriesEmpty));
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
                  if (c.isDefault) l10n.categoriesBadgeDefault,
                  if (c.isHidden) l10n.categoriesBadgeHidden,
                ].join(' · ')),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    IconButton(
                      icon: const Icon(Icons.edit_rounded),
                      tooltip: l10n.commonEdit,
                      onPressed: () {
                        Navigator.of(ctx).push(MaterialPageRoute<void>(
                          builder: (_) => CategoryEditScreen(existing: c),
                        ));
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded),
                      tooltip: l10n.commonDelete,
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
