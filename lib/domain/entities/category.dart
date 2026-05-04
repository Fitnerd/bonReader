import 'package:flutter/material.dart';

/// Eine Ausgabe-Kategorie. Vordefinierte Kategorien (`isDefault = true`)
/// werden beim ersten Start angelegt; eigene Kategorien können
/// hinzugefügt, umbenannt und gelöscht werden (Default-Kategorien
/// kann der Nutzer ausblenden, aber nicht physisch löschen, damit
/// historische Ausgaben ihre Zuordnung behalten).
@immutable
class Category {
  const Category({
    required this.id,
    required this.name,
    required this.colorValue,
    required this.iconCodePoint,
    required this.isDefault,
    required this.isHidden,
    required this.createdAt,
  });

  final String id;
  final String name;
  /// Material-Color als ARGB-int. Persistierbar als `INTEGER` in SQLite.
  final int colorValue;
  /// Icon als CodePoint (z. B. `Icons.shopping_cart.codePoint`).
  /// Beim Lesen wird daraus wieder ein `IconData` gebaut.
  final int iconCodePoint;
  final bool isDefault;
  final bool isHidden;
  final DateTime createdAt;

  Color get color => Color(colorValue);

  IconData get icon => IconData(
        iconCodePoint,
        fontFamily: 'MaterialIcons',
      );

  Category copyWith({
    String? name,
    int? colorValue,
    int? iconCodePoint,
    bool? isHidden,
  }) {
    return Category(
      id: id,
      name: name ?? this.name,
      colorValue: colorValue ?? this.colorValue,
      iconCodePoint: iconCodePoint ?? this.iconCodePoint,
      isDefault: isDefault,
      isHidden: isHidden ?? this.isHidden,
      createdAt: createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Category && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
