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
        items: [
          ExpenseItemDraft(name: 'Brot', totalCents: 199, unitPriceCents: 199),
          ExpenseItemDraft(name: 'Milch', totalCents: 1035, unitPriceCents: 1035),
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
        items: [ExpenseItemDraft(name: 'X', totalCents: 100)],
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

    test('update ersetzt Items komplett', () async {
      final e = await repo.create(ExpenseDraft(
        categoryId: catId,
        totalCents: 200,
        merchant: '',
        occurredAt: DateTime(2026, 5, 1),
        items: [
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
