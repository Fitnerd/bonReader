import 'package:flutter/material.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/category.dart';
import '../../domain/repositories/category_repository.dart';
import '../datasources/database/schema.dart';

/// Vordefinierte Kategorien, die beim ersten Start angelegt werden.
class DefaultCategories {
  DefaultCategories._();

  /// (Name, Farbwert, Icon-CodePoint).
  /// Icon-CodePoints sind die der `Icons.*` Konstanten.
  static const List<({String name, int color, IconData icon})> all = [
    (name: 'Lebensmittel', color: 0xFF14B8A6, icon: Icons.shopping_cart_rounded),
    (name: 'Drogerie', color: 0xFF8B5CF6, icon: Icons.soap_rounded),
    (name: 'Restaurant', color: 0xFFF59E0B, icon: Icons.restaurant_rounded),
    (name: 'Tanken', color: 0xFFEF4444, icon: Icons.local_gas_station_rounded),
    (name: 'Freizeit', color: 0xFF0EA5E9, icon: Icons.sports_esports_rounded),
    (name: 'Wohnen', color: 0xFF10B981, icon: Icons.home_rounded),
    (name: 'Kleidung', color: 0xFFEC4899, icon: Icons.checkroom_rounded),
    (name: 'Sonstiges', color: 0xFF64748B, icon: Icons.category_rounded),
  ];
}

class CategoryRepositoryImpl implements CategoryRepository {
  CategoryRepositoryImpl(this._db, {Uuid? uuid}) : _uuid = uuid ?? const Uuid();

  final Database _db;
  final Uuid _uuid;

  /// Stellt sicher, dass die Default-Kategorien existieren.
  /// Idempotent: tut nichts, wenn schon Kategorien vorhanden sind.
  Future<void> seedDefaultsIfNeeded() async {
    final result = await _db.rawQuery(
      'SELECT COUNT(*) AS c FROM ${DbTables.categories}',
    );
    final count = (result.first['c'] as int?) ?? 0;
    if (count > 0) return;

    final now = DateTime.now().millisecondsSinceEpoch;
    final batch = _db.batch();
    for (final def in DefaultCategories.all) {
      batch.insert(DbTables.categories, <String, Object?>{
        CategoryCols.id: _uuid.v4(),
        CategoryCols.name: def.name,
        CategoryCols.colorValue: def.color,
        CategoryCols.iconCodePoint: def.icon.codePoint,
        CategoryCols.isDefault: 1,
        CategoryCols.isHidden: 0,
        CategoryCols.createdAt: now,
      });
    }
    await batch.commit(noResult: true);
  }

  @override
  Future<List<Category>> getAll({bool includeHidden = true}) async {
    final where = includeHidden ? null : '${CategoryCols.isHidden} = 0';
    final rows = await _db.query(
      DbTables.categories,
      where: where,
      orderBy: '${CategoryCols.name} ASC',
    );
    return rows.map(_fromRow).toList(growable: false);
  }

  @override
  Future<List<Category>> getVisible() => getAll(includeHidden: false);

  @override
  Future<Category?> getById(String id) async {
    final rows = await _db.query(
      DbTables.categories,
      where: '${CategoryCols.id} = ?',
      whereArgs: <Object?>[id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return _fromRow(rows.first);
  }

  @override
  Future<Category> create({
    required String name,
    required int colorValue,
    required int iconCodePoint,
  }) async {
    final now = DateTime.now();
    final category = Category(
      id: _uuid.v4(),
      name: name.trim(),
      colorValue: colorValue,
      iconCodePoint: iconCodePoint,
      isDefault: false,
      isHidden: false,
      createdAt: now,
    );
    await _db.insert(DbTables.categories, _toRow(category));
    return category;
  }

  @override
  Future<Category> update(Category category) async {
    await _db.update(
      DbTables.categories,
      _toRow(category),
      where: '${CategoryCols.id} = ?',
      whereArgs: <Object?>[category.id],
    );
    return category;
  }

  @override
  Future<void> delete(String id) async {
    final existing = await getById(id);
    if (existing == null) return;

    if (existing.isDefault) {
      // Default-Kategorien werden nur versteckt, damit historische
      // Ausgaben weiterhin korrekt zugeordnet bleiben.
      await update(existing.copyWith(isHidden: true));
      return;
    }

    await _db.delete(
      DbTables.categories,
      where: '${CategoryCols.id} = ?',
      whereArgs: <Object?>[id],
    );
  }

  // ────────────────────────────────────────────────────────────────
  // Mapping
  // ────────────────────────────────────────────────────────────────
  Category _fromRow(Map<String, Object?> row) => Category(
        id: row[CategoryCols.id]! as String,
        name: row[CategoryCols.name]! as String,
        colorValue: row[CategoryCols.colorValue]! as int,
        iconCodePoint: row[CategoryCols.iconCodePoint]! as int,
        isDefault: (row[CategoryCols.isDefault]! as int) == 1,
        isHidden: (row[CategoryCols.isHidden]! as int) == 1,
        createdAt: DateTime.fromMillisecondsSinceEpoch(
          row[CategoryCols.createdAt]! as int,
        ),
      );

  Map<String, Object?> _toRow(Category c) => <String, Object?>{
        CategoryCols.id: c.id,
        CategoryCols.name: c.name,
        CategoryCols.colorValue: c.colorValue,
        CategoryCols.iconCodePoint: c.iconCodePoint,
        CategoryCols.isDefault: c.isDefault ? 1 : 0,
        CategoryCols.isHidden: c.isHidden ? 1 : 0,
        CategoryCols.createdAt: c.createdAt.millisecondsSinceEpoch,
      };
}
