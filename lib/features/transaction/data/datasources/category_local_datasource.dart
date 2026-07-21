import 'package:drift/drift.dart';
import 'package:penyintas_app/core/database/app_database.dart';
import 'package:penyintas_app/core/error/exceptions.dart';
import 'package:penyintas_app/features/transaction/data/models/category_model.dart';
import 'package:penyintas_app/features/transaction/domain/entities/category_entity.dart';
import 'package:drift/native.dart' show SqliteException;

abstract class CategoryLocalDatasource {
  Future<List<CategoryModel>> getCategories();
  Future<List<CategoryModel>> getLimitableCategories();
  // BARU Fase 3C:
  Future<CategoryModel> createCategory(CategoryEntity category);
  Future<void> updateCategory(CategoryEntity category);
  Future<void> deleteCategory(String slug); // cascade hapus budget_limits juga
}

class CategoryLocalDatasourceImpl implements CategoryLocalDatasource {
  CategoryLocalDatasourceImpl(this._db);
  final AppDatabase _db;

  @override
  Future<List<CategoryModel>> getCategories() async {
    final rows = await (_db.select(
      _db.categories,
    )..orderBy([(c) => OrderingTerm.asc(c.sortOrder)])).get();
    return rows.map(CategoryModel.fromRow).toList();
  }

  @override
  Future<List<CategoryModel>> getLimitableCategories() async {
    final rows =
        await (_db.select(_db.categories)
              ..where((c) => c.isLimitable)
              ..orderBy([(c) => OrderingTerm.asc(c.sortOrder)]))
            .get();
    return rows.map(CategoryModel.fromRow).toList();
  }

  @override
  Future<CategoryModel> createCategory(CategoryEntity category) async {
    try {
      final id = await _db
          .into(_db.categories)
          .insert(
            CategoriesCompanion(
              slug: Value(category.slug),
              labelOverride: Value(category.labelOverride),
              isBuiltIn: const Value(false),
              isLimitable: Value(category.isLimitable),
              type: Value(category.type),
              sortOrder: Value(category.sortOrder),
              iconSlug: Value(category.iconSlug),
            ),
          );
      return CategoryModel.fromRow(
        await (_db.select(
          _db.categories,
        )..where((c) => c.id.equals(id))).getSingle(),
      );
    } on SqliteException catch (e) {
      if (e.message.contains('UNIQUE constraint failed')) {
        throw const CacheException('Kategori dengan nama serupa sudah ada.');
      }
      rethrow;
    }
  }

  @override
  Future<void> updateCategory(CategoryEntity category) async {
    await (_db.update(
      _db.categories,
    )..where((c) => c.id.equals(category.id))).write(
      CategoriesCompanion(
        labelOverride: Value(category.labelOverride),
        isLimitable: Value(category.isLimitable),
        iconSlug: Value(category.iconSlug),
      ),
    );
  }

  @override
  Future<void> deleteCategory(String slug) async {
    await _db.transaction(() async {
      // 1. Cascade: hapus budget_limits yang pakai slug ini
      await (_db.delete(
        _db.budgetLimits,
      )..where((b) => b.category.equals(slug))).go();
      // 2. Hapus kategori itu sendiri
      await (_db.delete(
        _db.categories,
      )..where((c) => c.slug.equals(slug))).go();
    });
  }
}
