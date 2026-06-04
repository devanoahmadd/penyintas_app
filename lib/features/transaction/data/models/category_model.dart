import 'package:penyintas_app/core/database/app_database.dart';
import 'package:penyintas_app/features/transaction/domain/entities/category_entity.dart';

class CategoryModel extends CategoryEntity {
  const CategoryModel({
    required super.id,
    required super.slug,
    super.labelKey,
    super.labelOverride,
    required super.isBuiltIn,
    required super.isLimitable,
    required super.type,
    required super.sortOrder,
  });

  factory CategoryModel.fromRow(Category row) => CategoryModel(
        id: row.id,
        slug: row.slug,
        labelKey: row.labelKey,
        labelOverride: row.labelOverride,
        isBuiltIn: row.isBuiltIn,
        isLimitable: row.isLimitable,
        type: row.type,
        sortOrder: row.sortOrder,
      );
}
