import 'package:bonbudget/core/providers/data_providers.dart';
import 'package:bonbudget/data/repositories/category_repository_impl.dart';
import 'package:bonbudget/domain/repositories/category_repository.dart';
import 'package:bonbudget/presentation/providers/categories_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/in_memory_database.dart';

/// Tests fuer den CategoriesNotifier ueber Riverpod.
///
/// Wir ueberschreiben den `categoryRepositoryProvider` mit einer echten
/// Repository-Implementation, die auf einer In-Memory-DB sitzt. So wird
/// die ganze Provider-Pipeline getestet (build, addCategory, etc.) – nur
/// die SQLCipher-Verschluesselung wird durch Plain-SQLite ersetzt.
void main() {
  group('CategoriesNotifier', () {
    late ProviderContainer container;
    late CategoryRepositoryImpl repo;

    setUp(() async {
      final db = await openInMemoryTestDb();
      repo = CategoryRepositoryImpl(db);
      addTearDown(db.close);

      container = ProviderContainer(overrides: <Override>[
        categoryRepositoryProvider.overrideWith(
          (_) async => repo as CategoryRepository,
        ),
      ]);
      addTearDown(container.dispose);
    });

    test('build liefert leere Liste, wenn DB leer ist', () async {
      final cats = await container.read(categoriesProvider.future);
      expect(cats, isEmpty);
    });

    test('addCategory legt Kategorie an und invalidiert Liste', () async {
      // Initial leer
      final initial = await container.read(categoriesProvider.future);
      expect(initial, isEmpty);

      await container
          .read(categoriesProvider.notifier)
          .addCategory(name: 'Hobbys', colorValue: 0xFF14B8A6, iconCodePoint: 0xe3ae);

      final after = await container.read(categoriesProvider.future);
      expect(after, hasLength(1));
      expect(after.first.name, 'Hobbys');
      expect(after.first.isDefault, isFalse);
    });

    test('updateCategory aendert die Kategorie', () async {
      final notifier = container.read(categoriesProvider.notifier);
      await notifier.addCategory(
        name: 'Alt', colorValue: 0xFF000000, iconCodePoint: 0xe000,
      );

      final list = await container.read(categoriesProvider.future);
      final cat = list.first;

      await notifier.updateCategory(cat.copyWith(name: 'Neu'));
      final after = await container.read(categoriesProvider.future);
      expect(after.first.name, 'Neu');
    });

    test('deleteCategory entfernt eigene Kategorie', () async {
      final notifier = container.read(categoriesProvider.notifier);
      await notifier.addCategory(
        name: 'Custom', colorValue: 0xFF111111, iconCodePoint: 0xe000,
      );

      final list = await container.read(categoriesProvider.future);
      expect(list, hasLength(1));

      await notifier.deleteCategory(list.first.id);
      final after = await container.read(categoriesProvider.future);
      expect(after, isEmpty);
    });

    test('visibleCategoriesProvider blendet versteckte Default-Kategorien aus',
        () async {
      // Default-Kategorien anlegen (via Repo direkt, simuliert App-Start)
      await repo.seedDefaultsIfNeeded();
      // Riverpod-State neu laden, damit er die geseedeten Kategorien sieht.
      container.invalidate(categoriesProvider);

      final all = await container.read(categoriesProvider.future);
      expect(all, isNotEmpty);

      // Eine Default-Kategorie verstecken (= delete)
      final firstDefault = all.firstWhere((c) => c.isDefault);
      await container.read(categoriesProvider.notifier).deleteCategory(firstDefault.id);

      final visible = await container.read(visibleCategoriesProvider.future);
      expect(visible.any((c) => c.id == firstDefault.id), isFalse);

      final allAfter = await container.read(categoriesProvider.future);
      expect(
        allAfter.any((c) => c.id == firstDefault.id),
        isTrue,
        reason: 'Default-Kategorie bleibt physisch erhalten',
      );
    });
  });
}
