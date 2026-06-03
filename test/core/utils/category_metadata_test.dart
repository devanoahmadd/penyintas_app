import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:penyintas_app/core/theme/app_colors.dart';
import 'package:penyintas_app/core/utils/category_metadata.dart';

void main() {
  group('CategoryMetadata.of', () {
    test('built-in slug → icon dan color dari _map', () {
      final (icon, color) = CategoryMetadata.of('food');
      expect(icon, Icons.restaurant_outlined);
      expect(color, AppColors.warn);
    });

    test('slug tidak dikenal tanpa iconSlug → default icon dan primary', () {
      final (icon, color) = CategoryMetadata.of('unknown');
      expect(icon, Icons.grid_view_outlined);
      expect(color, AppColors.primary);
    });

    test('custom slug dengan iconSlug dikenal → icon dari _iconMap', () {
      final (icon, color) = CategoryMetadata.of('gym', iconSlug: 'fitness');
      expect(icon, Icons.fitness_center_outlined);
      expect(color, AppColors.primary);
    });

    test('custom slug dengan iconSlug tidak dikenal → default icon', () {
      final (icon, color) = CategoryMetadata.of('gym', iconSlug: 'xyz_unknown');
      expect(icon, Icons.grid_view_outlined);
      expect(color, AppColors.primary);
    });
  });

  group('CategoryMetadata.iconFromSlug', () {
    test('slug dikenal → icon yang benar', () {
      expect(CategoryMetadata.iconFromSlug('fitness'), Icons.fitness_center_outlined);
      expect(CategoryMetadata.iconFromSlug('school'), Icons.school_outlined);
      expect(CategoryMetadata.iconFromSlug('pets'), Icons.pets_outlined);
    });

    test('slug tidak dikenal → default icon', () {
      expect(CategoryMetadata.iconFromSlug('xyz'), Icons.grid_view_outlined);
    });
  });
}
