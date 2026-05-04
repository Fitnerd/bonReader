import 'package:bonbudget/data/datasources/database/schema.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/in_memory_database.dart';

/// Sichert das DB-Schema ab. Wenn jemand versehentlich eine Spalte
/// loescht oder umbenennt, schlagen diese Tests an, bevor die App
/// in Produktion crashed.
void main() {
  group('Migrations v1', () {
    test('alle Tabellen werden angelegt', () async {
      final db = await openInMemoryTestDb();
      addTearDown(db.close);

      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' ORDER BY name",
      );
      final names = tables.map((r) => r['name']).toList();

      expect(names, containsAll(<String>[
        DbTables.auth,
        DbTables.categories,
        DbTables.budgets,
        DbTables.expenses,
        DbTables.expenseItems,
      ]));
    });

    test('Foreign Keys sind aktiv', () async {
      final db = await openInMemoryTestDb();
      addTearDown(db.close);

      final result = await db.rawQuery('PRAGMA foreign_keys;');
      expect(result.first.values.first, 1);
    });

    test('expense.total_cents darf nicht negativ sein', () async {
      final db = await openInMemoryTestDb();
      addTearDown(db.close);

      // Erst Kategorie anlegen, sonst kollidiert die FK ohnehin.
      await db.insert(DbTables.categories, <String, Object?>{
        CategoryCols.id: 'cat1',
        CategoryCols.name: 'Test',
        CategoryCols.colorValue: 0xFF000000,
        CategoryCols.iconCodePoint: 0xe000,
        CategoryCols.isDefault: 0,
        CategoryCols.isHidden: 0,
        CategoryCols.createdAt: 0,
      });

      expect(
        () async => db.insert(DbTables.expenses, <String, Object?>{
          ExpenseCols.id: 'e1',
          ExpenseCols.categoryId: 'cat1',
          ExpenseCols.totalCents: -100,
          ExpenseCols.merchant: '',
          ExpenseCols.occurredAt: 0,
          ExpenseCols.note: '',
          ExpenseCols.createdAt: 0,
        }),
        throwsA(anything),
      );
    });

    test('Loeschen einer Ausgabe loescht ihre Items (CASCADE)', () async {
      final db = await openInMemoryTestDb();
      addTearDown(db.close);

      await db.insert(DbTables.categories, <String, Object?>{
        CategoryCols.id: 'cat1',
        CategoryCols.name: 'Test',
        CategoryCols.colorValue: 0,
        CategoryCols.iconCodePoint: 0xe000,
        CategoryCols.isDefault: 0,
        CategoryCols.isHidden: 0,
        CategoryCols.createdAt: 0,
      });
      await db.insert(DbTables.expenses, <String, Object?>{
        ExpenseCols.id: 'e1',
        ExpenseCols.categoryId: 'cat1',
        ExpenseCols.totalCents: 1000,
        ExpenseCols.merchant: '',
        ExpenseCols.occurredAt: 0,
        ExpenseCols.note: '',
        ExpenseCols.createdAt: 0,
      });
      await db.insert(DbTables.expenseItems, <String, Object?>{
        ExpenseItemCols.id: 'i1',
        ExpenseItemCols.expenseId: 'e1',
        ExpenseItemCols.name: 'Brot',
        ExpenseItemCols.quantity: 1,
        ExpenseItemCols.unitPriceCents: 199,
        ExpenseItemCols.totalCents: 199,
      });

      await db.delete(DbTables.expenses,
          where: '${ExpenseCols.id} = ?', whereArgs: ['e1']);

      final remaining = await db.query(DbTables.expenseItems);
      expect(remaining, isEmpty);
    });
  });
}
