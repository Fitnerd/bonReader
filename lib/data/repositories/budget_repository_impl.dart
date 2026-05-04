import 'package:sqflite_sqlcipher/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/budget.dart';
import '../../domain/repositories/budget_repository.dart';
import '../datasources/database/schema.dart';

class BudgetRepositoryImpl implements BudgetRepository {
  BudgetRepositoryImpl(this._db, {Uuid? uuid}) : _uuid = uuid ?? const Uuid();

  final Database _db;
  final Uuid _uuid;

  @override
  Future<List<Budget>> getAll() async {
    final rows = await _db.query(DbTables.budgets);
    return rows.map(_fromRow).toList(growable: false);
  }

  @override
  Future<Budget?> getForCategory(String categoryId) async {
    final rows = await _db.query(
      DbTables.budgets,
      where: '${BudgetCols.categoryId} = ?',
      whereArgs: <Object?>[categoryId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return _fromRow(rows.first);
  }

  @override
  Future<Budget> setForCategory({
    required String categoryId,
    required int amountCents,
  }) async {
    if (amountCents < 0) {
      throw ArgumentError.value(amountCents, 'amountCents', 'must be >= 0');
    }
    final existing = await getForCategory(categoryId);
    final now = DateTime.now();

    if (existing != null) {
      final updated = existing.copyWith(
        amountCents: amountCents,
        updatedAt: now,
      );
      await _db.update(
        DbTables.budgets,
        _toRow(updated),
        where: '${BudgetCols.id} = ?',
        whereArgs: <Object?>[updated.id],
      );
      return updated;
    }

    final budget = Budget(
      id: _uuid.v4(),
      categoryId: categoryId,
      amountCents: amountCents,
      createdAt: now,
      updatedAt: now,
    );
    await _db.insert(DbTables.budgets, _toRow(budget));
    return budget;
  }

  @override
  Future<void> remove(String categoryId) async {
    await _db.delete(
      DbTables.budgets,
      where: '${BudgetCols.categoryId} = ?',
      whereArgs: <Object?>[categoryId],
    );
  }

  @override
  Future<int> getTotalBudgetCents() async {
    final result = await _db.rawQuery(
      'SELECT COALESCE(SUM(${BudgetCols.amountCents}), 0) AS total '
      'FROM ${DbTables.budgets}',
    );
    return (result.first['total'] as int?) ?? 0;
  }

  // ────────────────────────────────────────────────────────────────
  /// Defensive Konvertierung: bei DB-Korruption / Schema-Mismatch
  /// werfen wir einen verstaendlichen Fehler statt einer kryptischen
  /// `Null check operator used on a null value`-Exception.
  Budget _fromRow(Map<String, Object?> row) {
    final id = row[BudgetCols.id];
    final categoryId = row[BudgetCols.categoryId];
    final amount = row[BudgetCols.amountCents];
    final createdAt = row[BudgetCols.createdAt];
    final updatedAt = row[BudgetCols.updatedAt];
    if (id is! String ||
        categoryId is! String ||
        amount is! int ||
        createdAt is! int ||
        updatedAt is! int) {
      throw StateError(
        'Budget-Zeile hat unerwartete Spaltentypen: $row',
      );
    }
    return Budget(
      id: id,
      categoryId: categoryId,
      amountCents: amount,
      createdAt: DateTime.fromMillisecondsSinceEpoch(createdAt),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(updatedAt),
    );
  }

  Map<String, Object?> _toRow(Budget b) => <String, Object?>{
        BudgetCols.id: b.id,
        BudgetCols.categoryId: b.categoryId,
        BudgetCols.amountCents: b.amountCents,
        BudgetCols.createdAt: b.createdAt.millisecondsSinceEpoch,
        BudgetCols.updatedAt: b.updatedAt.millisecondsSinceEpoch,
      };
}
