import 'package:flutter/material.dart';

/// Vorgegebene Farben und Icons, aus denen der Nutzer beim Anlegen
/// einer eigenen Kategorie auswaehlen kann. Bewusst kuratiert –
/// kein freier Color-Picker, damit alles zum Theme passt.
class CategoryPickerData {
  CategoryPickerData._();

  static const List<int> colors = <int>[
    0xFF14B8A6, // Mint
    0xFF10B981, // Emerald
    0xFF0EA5E9, // Sky
    0xFF8B5CF6, // Violet
    0xFFEC4899, // Pink
    0xFFF59E0B, // Amber
    0xFFEF4444, // Red
    0xFF64748B, // Slate
  ];

  static const List<IconData> icons = <IconData>[
    Icons.shopping_cart_rounded,
    Icons.restaurant_rounded,
    Icons.local_gas_station_rounded,
    Icons.home_rounded,
    Icons.checkroom_rounded,
    Icons.sports_esports_rounded,
    Icons.flight_rounded,
    Icons.medical_services_rounded,
    Icons.pets_rounded,
    Icons.school_rounded,
    Icons.fitness_center_rounded,
    Icons.brush_rounded,
    Icons.coffee_rounded,
    Icons.directions_car_rounded,
    Icons.movie_rounded,
    Icons.category_rounded,
  ];

}
