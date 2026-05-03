import 'package:bonbudget/data/repositories/category_repository_impl.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/in_memory_database.dart';

void main() {
  group('CategoryRepositoryImpl', () {
    late CategoryRepositoryImpl repo;

    setUp(() async {
      final db = await openInMemoryTestDb();
      repo = CategoryRepositoryImpl(db);
      addTearDown(db.close);
    });

    test('seedDefaultsIfNeeded legt alle Default-Kategorien an', () async {
      await repo.seedDefaultsIfNeeded();
      final all = await repo.getAll();
      expect(all.length, DefaultCategories.all.length);
      expect(all.every((c) => c.isDefault), isTrue);
    });

    test('seedDefaultsIfNeeded ist idempotent', () async {
      await repo.seedDefaultsIfNeeded();
      await repo.seedDefaultsIfNeeded();
      final all = await repo.getAll();
      expect(all.length, DefaultCategories.all.length);
    });

    test('create legt eigene Kategorie an (isDefault=false)', () async {
      final cat = await repo.create(
        name: 'Hobbys',
        colorValue: 0xFF14B8A6,
        iconCodePoint: Icons.brush_rounded.codePoint,
      );
      expect(cat.isDefault, isFalse);
      expect(cat.isHidden, isFalse);
      expect(cat.name, 'Hobbys');

      final fetched = await repo.getById(cat.id);
      expect(fetched, isNotNull);
      expect(fetched!.name, 'Hobbys');
    });

    test('delete einer Default-Kategorie versteckt sie nur', () async {
      await repo.seedDefaultsIfNeeded();
      final all = await repo.getAll();
      final first = all.first;
      expect(first.isDefault, isTrue);

      await repo.delete(first.id);

      final after = await repo.getById(first.id);
      expect(after, isNotNull, reason: 'Default-Kategorie bleibt physisch erhalten');
      expect(after!.isHidden, isTrue);

      final visible = await repo.getVisible();
      expect(visible.any((c) => c.id == first.id), isFalse);
    });

    test('delete einer eigenen Kategorie loescht sie physisch', () async {
      final cat = await repo.create(
        name: 'Custom',
        colorValue: 0xFF000000,
        iconCodePoint: 0xe000,
      );
      await repo.delete(cat.id);
      final fetched = await repo.getById(cat.id);
      expect(fetched, isNull);
    });

    test('update aendert Name und Farbe', () async {
      final cat = await repo.create(
        name: 'Alt',
        colorValue: 0xFF111111,
        iconCodePoint: 0xe000,
      );
      final updated = await repo.update(cat.copyWith(
        name: 'Neu',
        colorValue: 0xFF222222,
      ));
      expect(updated.name, 'Neu');

      final fetched = await repo.getById(cat.id);
      expect(fetched!.name, 'Neu');
      expect(fetched.colorValue, 0xFF222222);
    });
  });
}
