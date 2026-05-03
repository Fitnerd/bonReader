import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/data_providers.dart';
import '../../domain/entities/category.dart';

class CategoriesNotifier extends AsyncNotifier<List<Category>> {
  @override
  Future<List<Category>> build() async {
    final repo = await ref.watch(categoryRepositoryProvider.future);
    return repo.getAll();
  }

  Future<void> addCategory({
    required String name,
    required int colorValue,
    required int iconCodePoint,
  }) async {
    final repo = await ref.read(categoryRepositoryProvider.future);
    await repo.create(
      name: name,
      colorValue: colorValue,
      iconCodePoint: iconCodePoint,
    );
    ref.invalidateSelf();
  }

  Future<void> updateCategory(Category category) async {
    final repo = await ref.read(categoryRepositoryProvider.future);
    await repo.update(category);
    ref.invalidateSelf();
  }

  Future<void> deleteCategory(String id) async {
    final repo = await ref.read(categoryRepositoryProvider.future);
    await repo.delete(id);
    ref.invalidateSelf();
  }
}

final categoriesProvider =
    AsyncNotifierProvider<CategoriesNotifier, List<Category>>(
  CategoriesNotifier.new,
);

/// Sichtbare Kategorien fuer Auswahllisten (Ausgabe erfassen,
/// Budget setzen). Filtert versteckte raus.
final visibleCategoriesProvider = FutureProvider<List<Category>>((ref) async {
  final all = await ref.watch(categoriesProvider.future);
  return all.where((c) => !c.isHidden).toList(growable: false);
});
