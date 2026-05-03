import '../entities/category.dart';

abstract class CategoryRepository {
  /// Alle Kategorien (auch versteckte). Sortiert nach `name` ASC.
  Future<List<Category>> getAll({bool includeHidden = true});

  /// Sichtbare Kategorien (zur Auswahl beim Erfassen einer Ausgabe).
  Future<List<Category>> getVisible();

  Future<Category?> getById(String id);

  Future<Category> create({
    required String name,
    required int colorValue,
    required int iconCodePoint,
  });

  Future<Category> update(Category category);

  /// Loescht eine Kategorie. Default-Kategorien werden nicht
  /// physisch geloescht, sondern nur als versteckt markiert.
  Future<void> delete(String id);
}
