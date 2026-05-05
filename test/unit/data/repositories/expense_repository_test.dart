import 'package:bonbudget/data/repositories/category_repository_impl.dart';
import 'package:bonbudget/data/repositories/expense_repository_impl.dart';
import 'package:bonbudget/domain/repositories/expense_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/in_memory_database.dart';

void main() {
  group('ExpenseRepositoryImpl', () {
    late ExpenseRepositoryImpl repo;
    late String catId;

    setUp(() async {
      final db = await openInMemoryTestDb();
      repo = ExpenseRepositoryImpl(db);
      addTearDown(db.close);

      final cat = await CategoryRepositoryImpl(db).create(
        name: 'Lebensmittel',
        colorValue: 0xFF14B8A6,
        iconCodePoint: 0xe000,
      );
      catId = cat.id;
    });

    test('create legt Ausgabe mit Items an', () async {
      final e = await repo.create(ExpenseDraft(
        categoryId: catId,
        totalCents: 1234,
        merchant: 'Rewe',
        occurredAt: DateTime(2026, 5, 1, 12),
        items: const [
          ExpenseItemDraft(name: 'Brot', totalCents: 199, unitPriceCents: 199),
          ExpenseItemDraft(
              name: 'Milch', totalCents: 1035, unitPriceCents: 1035),
        ],
      ));
      expect(e.totalCents, 1234);
      expect(e.items, hasLength(2));
      expect(e.items.first.name, 'Brot');
    });

    test('getInRange filtert nach Datum', () async {
      await repo.create(ExpenseDraft(
        categoryId: catId,
        totalCents: 100,
        merchant: '',
        occurredAt: DateTime(2026, 4, 15),
      ));
      await repo.create(ExpenseDraft(
        categoryId: catId,
        totalCents: 200,
        merchant: '',
        occurredAt: DateTime(2026, 5, 2),
      ));

      final mai = await repo.getInRange(
        DateTime(2026, 5, 1),
        DateTime(2026, 5, 31, 23, 59, 59),
      );
      expect(mai, hasLength(1));
      expect(mai.first.totalCents, 200);
    });

    test('getTotalsByCategory summiert pro Kategorie', () async {
      await repo.create(ExpenseDraft(
        categoryId: catId,
        totalCents: 1000,
        merchant: '',
        occurredAt: DateTime(2026, 5, 1),
      ));
      await repo.create(ExpenseDraft(
        categoryId: catId,
        totalCents: 2500,
        merchant: '',
        occurredAt: DateTime(2026, 5, 2),
      ));

      final totals = await repo.getTotalsByCategory(
        DateTime(2026, 5, 1),
        DateTime(2026, 5, 31, 23, 59, 59),
      );
      expect(totals[catId], 3500);
    });

    test('getTotalCents summiert alle Ausgaben im Zeitraum', () async {
      await repo.create(ExpenseDraft(
        categoryId: catId,
        totalCents: 1000,
        merchant: '',
        occurredAt: DateTime(2026, 5, 1),
      ));
      await repo.create(ExpenseDraft(
        categoryId: catId,
        totalCents: 500,
        merchant: '',
        occurredAt: DateTime(2026, 5, 2),
      ));
      expect(
        await repo.getTotalCents(
          DateTime(2026, 5, 1),
          DateTime(2026, 5, 31, 23, 59, 59),
        ),
        1500,
      );
    });

    test('delete entfernt Ausgabe inkl. Items (CASCADE)', () async {
      final e = await repo.create(ExpenseDraft(
        categoryId: catId,
        totalCents: 100,
        merchant: '',
        occurredAt: DateTime(2026, 5, 1),
        items: const [ExpenseItemDraft(name: 'X', totalCents: 100)],
      ));
      await repo.delete(e.id);
      expect(await repo.getById(e.id), isNull);
    });

    test('negative Betraege werden abgelehnt', () async {
      expect(
        () => repo.create(ExpenseDraft(
          categoryId: catId,
          totalCents: -1,
          merchant: '',
          occurredAt: DateTime.now(),
        )),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('getPage liefert seitenweise (DESC nach Datum)', () async {
      // 5 Ausgaben anlegen, an verschiedenen Tagen
      for (var i = 1; i <= 5; i++) {
        await repo.create(ExpenseDraft(
          categoryId: catId,
          totalCents: i * 100,
          merchant: 'M$i',
          occurredAt: DateTime(2026, 5, i),
        ));
      }
      expect(await repo.getCount(), 5);

      final page1 = await repo.getPage(offset: 0, limit: 2);
      expect(page1, hasLength(2));
      // Neueste zuerst → 5. Mai (500), 4. Mai (400)
      expect(page1[0].totalCents, 500);
      expect(page1[1].totalCents, 400);

      final page2 = await repo.getPage(offset: 2, limit: 2);
      expect(page2, hasLength(2));
      expect(page2[0].totalCents, 300);
      expect(page2[1].totalCents, 200);

      final page3 = await repo.getPage(offset: 4, limit: 2);
      expect(page3, hasLength(1));
      expect(page3[0].totalCents, 100);
    });

    test('getPage mit ungueltigen Werten liefert leer', () async {
      expect(await repo.getPage(offset: -1, limit: 10), isEmpty);
      expect(await repo.getPage(offset: 0, limit: 0), isEmpty);
      expect(await repo.getPage(offset: 0, limit: -5), isEmpty);
    });

    test('getPageInRange + getCountInRange beachten Datumsfilter',
        () async {
      // April + Mai
      await repo.create(ExpenseDraft(
        categoryId: catId,
        totalCents: 100,
        merchant: '',
        occurredAt: DateTime(2026, 4, 15),
      ));
      await repo.create(ExpenseDraft(
        categoryId: catId,
        totalCents: 200,
        merchant: '',
        occurredAt: DateTime(2026, 5, 1),
      ));
      await repo.create(ExpenseDraft(
        categoryId: catId,
        totalCents: 300,
        merchant: '',
        occurredAt: DateTime(2026, 5, 15),
      ));

      final from = DateTime(2026, 5, 1);
      final to = DateTime(2026, 5, 31, 23, 59, 59);

      expect(await repo.getCountInRange(from, to), 2);

      final page = await repo.getPageInRange(
        from: from,
        to: to,
        offset: 0,
        limit: 10,
      );
      expect(page, hasLength(2));
      expect(page[0].totalCents, 300); // 15. Mai zuerst
      expect(page[1].totalCents, 200);
    });

    test('update ersetzt Items komplett', () async {
      final e = await repo.create(ExpenseDraft(
        categoryId: catId,
        totalCents: 200,
        merchant: '',
        occurredAt: DateTime(2026, 5, 1),
        items: const [
          ExpenseItemDraft(name: 'Alt1', totalCents: 100),
          ExpenseItemDraft(name: 'Alt2', totalCents: 100),
        ],
      ));
      final updated = await repo.update(e.copyWith(
        totalCents: 300,
        items: const [],
      ));
      expect(updated.totalCents, 300);
      expect(updated.items, isEmpty);
    });
  });
}
