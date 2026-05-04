import 'package:sqflite_sqlcipher/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/expense.dart';
import '../../domain/entities/expense_item.dart';
import '../../domain/repositories/expense_repository.dart';
import '../datasources/database/schema.dart';

class ExpenseRepositoryImpl implements ExpenseRepository {
  ExpenseRepositoryImpl(this._db, {Uuid? uuid}) : _uuid = uuid ?? const Uuid();

  final Database _db;
  final Uuid _uuid;

  @override
  Future<List<Expense>> getAll({int? limit}) async {
    final rows = await _db.query(
      DbTables.expenses,
      orderBy: '${ExpenseCols.occurredAt} DESC',
      limit: limit,
    );
    return _hydrateAll(rows);
  }

  @override
  Future<List<Expense>> getInRange(DateTime from, DateTime to) async {
    final rows = await _db.query(
      DbTables.expenses,
      where: '${ExpenseCols.occurredAt} BETWEEN ? AND ?',
      whereArgs: <Object?>[
        from.millisecondsSinceEpoch,
        to.millisecondsSinceEpoch,
      ],
      orderBy: '${ExpenseCols.occurredAt} DESC',
    );
    return _hydrateAll(rows);
  }

  @override
  Future<List<Expense>> getPage({
    required int offset,
    required int limit,
  }) async {
    if (offset < 0 || limit <= 0) return const <Expense>[];
    final rows = await _db.query(
      DbTables.expenses,
      orderBy: '${ExpenseCols.occurredAt} DESC',
      limit: limit,
      offset: offset,
    );
    return _hydrateAll(rows);
  }

  @override
  Future<List<Expense>> getPageInRange({
    required DateTime from,
    required DateTime to,
    required int offset,
    required int limit,
  }) async {
    if (offset < 0 || limit <= 0) return const <Expense>[];
    final rows = await _db.query(
      DbTables.expenses,
      where: '${ExpenseCols.occurredAt} BETWEEN ? AND ?',
      whereArgs: <Object?>[
        from.millisecondsSinceEpoch,
        to.millisecondsSinceEpoch,
      ],
      orderBy: '${ExpenseCols.occurredAt} DESC',
      limit: limit,
      offset: offset,
    );
    return _hydrateAll(rows);
  }

  @override
  Future<int> getCount() async {
    final rows = await _db
        .rawQuery('SELECT COUNT(*) AS c FROM ${DbTables.expenses}');
    return (rows.first['c'] as int?) ?? 0;
  }

  @override
  Future<int> getCountInRange(DateTime from, DateTime to) async {
    final rows = await _db.rawQuery(
      'SELECT COUNT(*) AS c FROM ${DbTables.expenses} '
      'WHERE ${ExpenseCols.occurredAt} BETWEEN ? AND ?',
      <Object?>[from.millisecondsSinceEpoch, to.millisecondsSinceEpoch],
    );
    return (rows.first['c'] as int?) ?? 0;
  }

  @override
  Future<Map<String, int>> getTotalsByCategory(
    DateTime from,
    DateTime to,
  ) async {
    final rows = await _db.rawQuery(
      'SELECT ${ExpenseCols.categoryId} AS cat, '
      'SUM(${ExpenseCols.totalCents}) AS total '
      'FROM ${DbTables.expenses} '
      'WHERE ${ExpenseCols.occurredAt} BETWEEN ? AND ? '
      'GROUP BY ${ExpenseCols.categoryId}',
      <Object?>[from.millisecondsSinceEpoch, to.millisecondsSinceEpoch],
    );
    return <String, int>{
      for (final row in rows)
        row['cat']! as String: (row['total'] as int?) ?? 0,
    };
  }

  @override
  Future<Expense?> getById(String id) async {
    final rows = await _db.query(
      DbTables.expenses,
      where: '${ExpenseCols.id} = ?',
      whereArgs: <Object?>[id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return _hydrateOne(rows.first);
  }

  @override
  Future<Expense> create(ExpenseDraft draft) async {
    if (draft.totalCents < 0) {
      throw ArgumentError.value(
        draft.totalCents,
        'totalCents',
        'must be >= 0',
      );
    }
    final now = DateTime.now();
    final expenseId = _uuid.v4();

    await _db.transaction((Transaction txn) async {
      await txn.insert(DbTables.expenses, <String, Object?>{
        ExpenseCols.id: expenseId,
        ExpenseCols.categoryId: draft.categoryId,
        ExpenseCols.totalCents: draft.totalCents,
        ExpenseCols.merchant: draft.merchant,
        ExpenseCols.occurredAt: draft.occurredAt.millisecondsSinceEpoch,
        ExpenseCols.note: draft.note,
        ExpenseCols.createdAt: now.millisecondsSinceEpoch,
      });
      for (final item in draft.items) {
        await txn.insert(DbTables.expenseItems, <String, Object?>{
          ExpenseItemCols.id: _uuid.v4(),
          ExpenseItemCols.expenseId: expenseId,
          ExpenseItemCols.name: item.name,
          ExpenseItemCols.quantityMilli: item.quantityMilli,
          ExpenseItemCols.unitPriceCents: item.unitPriceCents,
          ExpenseItemCols.totalCents: item.totalCents,
        });
      }
    });

    final created = await getById(expenseId);
    if (created == null) {
      // Sollte nie passieren - die Transaktion oben hat gerade
      // committed. Wenn doch, ist die DB korrupt - lieber explizit
      // failen als mit `!` einen NPE-aehnlichen Crash zu kaschieren.
      throw StateError(
        'create: Ausgabe $expenseId nach Insert nicht auffindbar.',
      );
    }
    return created;
  }

  @override
  Future<Expense> update(Expense expense) async {
    await _db.transaction((Transaction txn) async {
      await txn.update(
        DbTables.expenses,
        <String, Object?>{
          ExpenseCols.categoryId: expense.categoryId,
          ExpenseCols.totalCents: expense.totalCents,
          ExpenseCols.merchant: expense.merchant,
          ExpenseCols.occurredAt: expense.occurredAt.millisecondsSinceEpoch,
          ExpenseCols.note: expense.note,
        },
        where: '${ExpenseCols.id} = ?',
        whereArgs: <Object?>[expense.id],
      );
      // Items werden komplett ersetzt – einfacher als Diff zu pflegen.
      await txn.delete(
        DbTables.expenseItems,
        where: '${ExpenseItemCols.expenseId} = ?',
        whereArgs: <Object?>[expense.id],
      );
      for (final item in expense.items) {
        await txn.insert(DbTables.expenseItems, <String, Object?>{
          ExpenseItemCols.id: item.id,
          ExpenseItemCols.expenseId: expense.id,
          ExpenseItemCols.name: item.name,
          ExpenseItemCols.quantityMilli: item.quantityMilli,
          ExpenseItemCols.unitPriceCents: item.unitPriceCents,
          ExpenseItemCols.totalCents: item.totalCents,
        });
      }
    });
    final updated = await getById(expense.id);
    if (updated == null) {
      throw StateError(
        'update: Ausgabe ${expense.id} nach Update nicht auffindbar.',
      );
    }
    return updated;
  }

  @override
  Future<void> delete(String id) async {
    await _db.delete(
      DbTables.expenses,
      where: '${ExpenseCols.id} = ?',
      whereArgs: <Object?>[id],
    );
  }

  @override
  Future<int> getTotalCents(DateTime from, DateTime to) async {
    final rows = await _db.rawQuery(
      'SELECT COALESCE(SUM(${ExpenseCols.totalCents}), 0) AS total '
      'FROM ${DbTables.expenses} '
      'WHERE ${ExpenseCols.occurredAt} BETWEEN ? AND ?',
      <Object?>[from.millisecondsSinceEpoch, to.millisecondsSinceEpoch],
    );
    return (rows.first['total'] as int?) ?? 0;
  }

  // ────────────────────────────────────────────────────────────────
  Future<List<Expense>> _hydrateAll(List<Map<String, Object?>> rows) async {
    final result = <Expense>[];
    for (final row in rows) {
      result.add(await _hydrateOne(row));
    }
    return result;
  }

  Future<Expense> _hydrateOne(Map<String, Object?> row) async {
    final id = row[ExpenseCols.id]! as String;
    final itemRows = await _db.query(
      DbTables.expenseItems,
      where: '${ExpenseItemCols.expenseId} = ?',
      whereArgs: <Object?>[id],
    );
    final items = itemRows
        .map((Map<String, Object?> r) => ExpenseItem(
              id: r[ExpenseItemCols.id]! as String,
              expenseId: r[ExpenseItemCols.expenseId]! as String,
              name: r[ExpenseItemCols.name]! as String,
              quantityMilli: r[ExpenseItemCols.quantityMilli]! as int,
              unitPriceCents: r[ExpenseItemCols.unitPriceCents]! as int,
              totalCents: r[ExpenseItemCols.totalCents]! as int,
            ))
        .toList(growable: false);

    return Expense(
      id: id,
      categoryId: row[ExpenseCols.categoryId]! as String,
      totalCents: row[ExpenseCols.totalCents]! as int,
      merchant: row[ExpenseCols.merchant]! as String,
      occurredAt: DateTime.fromMillisecondsSinceEpoch(
        row[ExpenseCols.occurredAt]! as int,
      ),
      note: row[ExpenseCols.note]! as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        row[ExpenseCols.createdAt]! as int,
      ),
      items: items,
    );
  }
}
