import 'package:drift/drift.dart';
import 'package:penyintas_app/core/database/app_database.dart';
import 'package:penyintas_app/features/transaction/data/models/category_model.dart';

abstract class CategoryLocalDatasource {
  Future<List<CategoryModel>> getCategories();
  Future<List<CategoryModel>> getLimitableCategories();
}

class CategoryLocalDatasourceImpl implements CategoryLocalDatasource {
  CategoryLocalDatasourceImpl(this._db);
  final AppDatabase _db;

  @override
  Future<List<CategoryModel>> getCategories() async {
    final rows = await (_db.select(_db.categories)
          ..orderBy([(c) => OrderingTerm.asc(c.sortOrder)]))
        .get();
    return rows.map(CategoryModel.fromRow).toList();
  }

  @override
  Future<List<CategoryModel>> getLimitableCategories() async {
    final rows = await (_db.select(_db.categories)
          ..where((c) => c.isLimitable)
          ..orderBy([(c) => OrderingTerm.asc(c.sortOrder)]))
        .get();
    return rows.map(CategoryModel.fromRow).toList();
  }
}
