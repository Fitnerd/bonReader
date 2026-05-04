import 'package:bonbudget/data/repositories/budget_repository_impl.dart';
import 'package:bonbudget/data/repositories/category_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/in_memory_database.dart';

void main() {
  group('BudgetRepositoryImpl', () {
    late BudgetRepositoryImpl repo;
    late CategoryRepositoryImpl catRepo;
    late String catId1;
    late String catId2;

    setUp(() async {
      final db = await openInMemoryTestDb();
      repo = BudgetRepositoryImpl(db);
      catRepo = CategoryRepositoryImpl(db);
      addTearDown(db.close);

      final c1 = await catRepo.create(
        name: 'Lebensmittel',
        colorValue: 0xFF14B8A6,
        iconCodePoint: 0xe000,
      );
      final c2 = await catRepo.create(
        name: 'Tanken',
        colorValue: 0xFFEF4444,
        iconCodePoint: 0xe001,
      );
      catId1 = c1.id;
      catId2 = c2.id;
    });

    test('setForCategory legt Budget an', () async {
      final b = await repo.setForCategory(
        categoryId: catId1,
        amountCents: 40000,
      );
      expect(b.amountCents, 40000);

      final fetched = await repo.getForCategory(catId1);
      expect(fetched, isNotNull);
      expect(fetched!.amountCents, 40000);
    });

    test('setForCategory aktualisiert bestehendes Budget', () async {
      await repo.setForCategory(categoryId: catId1, amountCents: 30000);
      await repo.setForCategory(categoryId: catId1, amountCents: 50000);

      final all = await repo.getAll();
      expect(all, hasLength(1), reason: 'Es darf nur EIN Budget pro Kategorie geben');
      expect(all.first.amountCents, 50000);
    });

    test('Gesamtbudget ist Summe aller Kategorie-Budgets', () async {
      await repo.setForCategory(categoryId: catId1, amountCents: 40000);
      await repo.setForCategory(categoryId: catId2, amountCents: 10000);
      expect(await repo.getTotalBudgetCents(), 50000);
    });

    test('Gesamtbudget ist 0 wenn keine Budgets gesetzt', () async {
      expect(await repo.getTotalBudgetCents(), 0);
    });

    test('remove loescht das Budget', () async {
      await repo.setForCategory(categoryId: catId1, amountCents: 40000);
      await repo.remove(catId1);
      expect(await repo.getForCategory(catId1), isNull);
    });

    test('negative Betraege werden abgelehnt', () async {
      expect(
        () => repo.setForCategory(categoryId: catId1, amountCents: -100),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}
