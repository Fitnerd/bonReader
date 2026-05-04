import 'package:bonbudget/data/datasources/database/migrations.dart';
import 'package:bonbudget/data/datasources/database/schema.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../../../helpers/in_memory_database.dart';

/// Sichert das DB-Schema ab. Wenn jemand versehentlich eine Spalte
/// loescht oder umbenennt, schlagen diese Tests an, bevor die App
/// in Produktion crashed.
void main() {
  group('Migrations - aktuelles Schema', () {
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
        ExpenseItemCols.quantityMilli: 1000,
        ExpenseItemCols.unitPriceCents: 199,
        ExpenseItemCols.totalCents: 199,
      });

      await db.delete(DbTables.expenses,
          where: '${ExpenseCols.id} = ?', whereArgs: ['e1']);

      final remaining = await db.query(DbTables.expenseItems);
      expect(remaining, isEmpty);
    });

    test('auth-Tabelle hat KEINE Passwort-Spalten mehr (v3)', () async {
      final db = await openInMemoryTestDb();
      addTearDown(db.close);

      final cols = await db.rawQuery('PRAGMA table_info(${DbTables.auth});');
      final names = cols.map((r) => r['name'] as String).toSet();
      expect(names, contains(AuthCols.id));
      expect(names, contains(AuthCols.createdAt));
      expect(names, contains(AuthCols.updatedAt));
      expect(names, isNot(contains('password_hash')));
      expect(names, isNot(contains('password_salt')));
      expect(names, isNot(contains('biometric_enabled')));
    });

    test('expense_items.total_cents darf negativ sein (v2-Effekt)',
        () async {
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
      // -299 Cent (Pfand) muss erlaubt sein.
      await db.insert(DbTables.expenseItems, <String, Object?>{
        ExpenseItemCols.id: 'pf1',
        ExpenseItemCols.expenseId: 'e1',
        ExpenseItemCols.name: 'Pfand',
        ExpenseItemCols.quantityMilli: 1000,
        ExpenseItemCols.unitPriceCents: -299,
        ExpenseItemCols.totalCents: -299,
      });
      final rows = await db.query(DbTables.expenseItems);
      expect(rows, hasLength(1));
    });
  });

  group('Migrations - Upgrade-Pfade', () {
    test('v1 → latest: Passwort-Spalten verschwinden, IDs bleiben',
        () async {
      sqfliteFfiInit();
      final factory = databaseFactoryFfi;

      // 1) DB als v1 oeffnen.
      final db = await factory.openDatabase(
        inMemoryDatabasePath,
        options: OpenDatabaseOptions(
          version: 1,
          onCreate: (db, _) => Migrations.onCreate(db, 1),
        ),
      );
      addTearDown(db.close);

      // Auth-Zeile mit Hash anlegen, wie eine alte Installation es hat.
      final id = await db.insert(DbTables.auth, <String, Object?>{
        'password_hash': 'legacyhash',
        'password_salt': 'legacysalt',
        'biometric_enabled': 1,
        AuthCols.createdAt: 1700000000,
        AuthCols.updatedAt: 1700000001,
      });
      expect(id, isNonZero);

      // 2) Manuell auf v3 upgraden.
      await Migrations.onUpgrade(db, 1, Migrations.latestVersion);

      // 3) Spalten weg, ID + Zeitstempel da.
      final cols = await db.rawQuery('PRAGMA table_info(${DbTables.auth});');
      final names = cols.map((r) => r['name'] as String).toSet();
      expect(names, isNot(contains('password_hash')));
      expect(names, isNot(contains('password_salt')));
      expect(names, isNot(contains('biometric_enabled')));

      final rows = await db.query(DbTables.auth);
      expect(rows, hasLength(1));
      expect(rows.first[AuthCols.id], id);
      expect(rows.first[AuthCols.createdAt], 1700000000);
    });

    test('v2 → latest: Auth-Tabelle wird zurueckgebaut', () async {
      sqfliteFfiInit();
      final factory = databaseFactoryFfi;

      final db = await factory.openDatabase(
        inMemoryDatabasePath,
        options: OpenDatabaseOptions(
          version: 2,
          onCreate: (db, _) => Migrations.onCreate(db, 2),
        ),
      );
      addTearDown(db.close);

      await db.insert(DbTables.auth, <String, Object?>{
        'password_hash': 'h',
        'password_salt': 's',
        'biometric_enabled': 0,
        AuthCols.createdAt: 0,
        AuthCols.updatedAt: 0,
      });

      await Migrations.onUpgrade(db, 2, Migrations.latestVersion);

      final cols = await db.rawQuery('PRAGMA table_info(${DbTables.auth});');
      final names = cols.map((r) => r['name'] as String).toSet();
      expect(names, isNot(contains('password_hash')));
      expect((await db.query(DbTables.auth)).length, 1);
    });

    test('v3 → v4: quantity REAL wird zu quantity_milli INTEGER * 1000',
        () async {
      sqfliteFfiInit();
      final factory = databaseFactoryFfi;

      // 1) DB als v3 oeffnen.
      final db = await factory.openDatabase(
        inMemoryDatabasePath,
        options: OpenDatabaseOptions(
          version: 3,
          onCreate: (db, _) => Migrations.onCreate(db, 3),
        ),
      );
      addTearDown(db.close);

      // Beispieldaten anlegen (kategorie + ausgabe + zwei items mit
      // unterschiedlichen quantitaeten).
      await db.insert(DbTables.categories, <String, Object?>{
        CategoryCols.id: 'c1',
        CategoryCols.name: 'Test',
        CategoryCols.colorValue: 0,
        CategoryCols.iconCodePoint: 0xe000,
        CategoryCols.isDefault: 0,
        CategoryCols.isHidden: 0,
        CategoryCols.createdAt: 0,
      });
      await db.insert(DbTables.expenses, <String, Object?>{
        ExpenseCols.id: 'e1',
        ExpenseCols.categoryId: 'c1',
        ExpenseCols.totalCents: 500,
        ExpenseCols.merchant: '',
        ExpenseCols.occurredAt: 0,
        ExpenseCols.note: '',
        ExpenseCols.createdAt: 0,
      });
      // v3-Schema hat noch die `quantity` REAL-Spalte.
      await db.rawInsert(
        'INSERT INTO ${DbTables.expenseItems} '
        '(${ExpenseItemCols.id}, ${ExpenseItemCols.expenseId}, '
        '${ExpenseItemCols.name}, quantity, '
        '${ExpenseItemCols.unitPriceCents}, ${ExpenseItemCols.totalCents}) '
        'VALUES (?, ?, ?, ?, ?, ?)',
        <Object?>['i1', 'e1', 'Apfel', 1.5, 200, 300],
      );
      await db.rawInsert(
        'INSERT INTO ${DbTables.expenseItems} '
        '(${ExpenseItemCols.id}, ${ExpenseItemCols.expenseId}, '
        '${ExpenseItemCols.name}, quantity, '
        '${ExpenseItemCols.unitPriceCents}, ${ExpenseItemCols.totalCents}) '
        'VALUES (?, ?, ?, ?, ?, ?)',
        <Object?>['i2', 'e1', 'Brot', 1.0, 200, 200],
      );

      // 2) v4-Migration laufen lassen.
      await Migrations.onUpgrade(db, 3, Migrations.latestVersion);

      // 3) Schema-Check: alte Spalte weg, neue da, INTEGER.
      final cols = await db
          .rawQuery('PRAGMA table_info(${DbTables.expenseItems});');
      final names = cols.map((r) => r['name'] as String).toSet();
      expect(names, isNot(contains('quantity')));
      expect(names, contains(ExpenseItemCols.quantityMilli));
      final qmCol = cols.firstWhere(
          (c) => c['name'] == ExpenseItemCols.quantityMilli);
      expect(qmCol['type'], 'INTEGER');

      // 4) Daten-Roundtrip: 1.5 → 1500, 1.0 → 1000.
      final rows = await db.query(
        DbTables.expenseItems,
        orderBy: '${ExpenseItemCols.id} ASC',
      );
      expect(rows, hasLength(2));
      expect(rows[0][ExpenseItemCols.quantityMilli], 1500);
      expect(rows[1][ExpenseItemCols.quantityMilli], 1000);
    });
  });
}
