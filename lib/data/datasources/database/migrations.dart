import 'package:sqflite_sqlcipher/sqflite.dart';

import 'schema.dart';

/// SQL-Migrationen.
///
/// Jede Migration ist idempotent geschrieben (CREATE IF NOT EXISTS,
/// DROP IF EXISTS), damit ein abgebrochener Lauf keinen Halbzustand
/// hinterlaesst. Migrationen muessen aufsteigend aufgerufen werden:
/// `_v1`, dann `_v2`, ... - das wird in [Migrations.runMigrations]
/// automatisch erledigt.
class Migrations {
  Migrations._();

  /// Liste aller Migrations-Funktionen, in aufsteigender Reihenfolge.
  /// Index 0 = Version 1, Index 1 = Version 2, ...
  static final List<Future<void> Function(DatabaseExecutor)> _all = <
      Future<void> Function(DatabaseExecutor)>[
    _v1,
    _v2,
  ];

  static int get latestVersion => _all.length;

  /// Wird beim ersten Anlegen der DB aufgerufen -> fuehrt alle
  /// Migrationen einmal aus.
  static Future<void> onCreate(Database db, int version) async {
    for (var i = 0; i < version; i++) {
      await _all[i](db);
    }
  }

  /// Wird bei DB-Versionswechsel aufgerufen -> fuehrt nur die neuen
  /// Migrationen aus.
  static Future<void> onUpgrade(Database db, int oldVersion, int newVersion) async {
    for (var i = oldVersion; i < newVersion; i++) {
      await _all[i](db);
    }
  }

  // ----------------------------------------------------------------
  // Version 1: initiales Schema
  // ----------------------------------------------------------------
  static Future<void> _v1(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${DbTables.auth} (
        ${AuthCols.id} INTEGER PRIMARY KEY AUTOINCREMENT,
        ${AuthCols.passwordHash} TEXT NOT NULL,
        ${AuthCols.passwordSalt} TEXT NOT NULL,
        ${AuthCols.biometricEnabled} INTEGER NOT NULL DEFAULT 0,
        ${AuthCols.createdAt} INTEGER NOT NULL,
        ${AuthCols.updatedAt} INTEGER NOT NULL
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${DbTables.categories} (
        ${CategoryCols.id} TEXT PRIMARY KEY,
        ${CategoryCols.name} TEXT NOT NULL,
        ${CategoryCols.colorValue} INTEGER NOT NULL,
        ${CategoryCols.iconCodePoint} INTEGER NOT NULL,
        ${CategoryCols.isDefault} INTEGER NOT NULL DEFAULT 0,
        ${CategoryCols.isHidden} INTEGER NOT NULL DEFAULT 0,
        ${CategoryCols.createdAt} INTEGER NOT NULL
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${DbTables.budgets} (
        ${BudgetCols.id} TEXT PRIMARY KEY,
        ${BudgetCols.categoryId} TEXT NOT NULL UNIQUE
          REFERENCES ${DbTables.categories}(${CategoryCols.id}) ON DELETE CASCADE,
        ${BudgetCols.amountCents} INTEGER NOT NULL CHECK (${BudgetCols.amountCents} >= 0),
        ${BudgetCols.createdAt} INTEGER NOT NULL,
        ${BudgetCols.updatedAt} INTEGER NOT NULL
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${DbTables.expenses} (
        ${ExpenseCols.id} TEXT PRIMARY KEY,
        ${ExpenseCols.categoryId} TEXT NOT NULL
          REFERENCES ${DbTables.categories}(${CategoryCols.id}) ON DELETE RESTRICT,
        ${ExpenseCols.totalCents} INTEGER NOT NULL CHECK (${ExpenseCols.totalCents} >= 0),
        ${ExpenseCols.merchant} TEXT NOT NULL DEFAULT '',
        ${ExpenseCols.occurredAt} INTEGER NOT NULL,
        ${ExpenseCols.note} TEXT NOT NULL DEFAULT '',
        ${ExpenseCols.createdAt} INTEGER NOT NULL
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${DbTables.expenseItems} (
        ${ExpenseItemCols.id} TEXT PRIMARY KEY,
        ${ExpenseItemCols.expenseId} TEXT NOT NULL
          REFERENCES ${DbTables.expenses}(${ExpenseCols.id}) ON DELETE CASCADE,
        ${ExpenseItemCols.name} TEXT NOT NULL,
        ${ExpenseItemCols.quantity} REAL NOT NULL DEFAULT 1,
        ${ExpenseItemCols.unitPriceCents} INTEGER NOT NULL DEFAULT 0,
        ${ExpenseItemCols.totalCents} INTEGER NOT NULL CHECK (${ExpenseItemCols.totalCents} >= 0)
      );
    ''');

    // Indizes fuer haeufige Statistik-Abfragen
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_expenses_occurred_at
      ON ${DbTables.expenses}(${ExpenseCols.occurredAt});
    ''');
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_expenses_category
      ON ${DbTables.expenses}(${ExpenseCols.categoryId});
    ''');
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_expense_items_expense
      ON ${DbTables.expenseItems}(${ExpenseItemCols.expenseId});
    ''');
  }

  // ----------------------------------------------------------------
  // Version 2: expense_items.total_cents darf negativ sein
  //
  // Hintergrund: Pfand-Erstattung (Leergut) auf deutschen Bons hat
  // einen negativen Wert (`-2,99 EUR`). Damit der Parser das als eigene
  // Position einfuegen kann, muss das CHECK-Constraint weichen.
  //
  // SQLite kennt kein DROP CONSTRAINT - wir muessen die Tabelle neu
  // anlegen und Daten migrieren.
  // ----------------------------------------------------------------
  static Future<void> _v2(DatabaseExecutor db) async {
    // 1. Neue Tabelle ohne CHECK-Constraint anlegen.
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${DbTables.expenseItems}_new (
        ${ExpenseItemCols.id} TEXT PRIMARY KEY,
        ${ExpenseItemCols.expenseId} TEXT NOT NULL
          REFERENCES ${DbTables.expenses}(${ExpenseCols.id}) ON DELETE CASCADE,
        ${ExpenseItemCols.name} TEXT NOT NULL,
        ${ExpenseItemCols.quantity} REAL NOT NULL DEFAULT 1,
        ${ExpenseItemCols.unitPriceCents} INTEGER NOT NULL DEFAULT 0,
        ${ExpenseItemCols.totalCents} INTEGER NOT NULL
      );
    ''');

    // 2. Daten ruebertragen.
    await db.execute('''
      INSERT INTO ${DbTables.expenseItems}_new
      SELECT * FROM ${DbTables.expenseItems};
    ''');

    // 3. Alten Index droppen (haengt an alter Tabelle).
    await db.execute('DROP INDEX IF EXISTS idx_expense_items_expense;');

    // 4. Alte Tabelle wegwerfen.
    await db.execute('DROP TABLE ${DbTables.expenseItems};');

    // 5. Neue Tabelle umbenennen.
    await db.execute('''
      ALTER TABLE ${DbTables.expenseItems}_new
      RENAME TO ${DbTables.expenseItems};
    ''');

    // 6. Index wieder anlegen.
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_expense_items_expense
      ON ${DbTables.expenseItems}(${ExpenseItemCols.expenseId});
    ''');
  }
}
