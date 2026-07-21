import 'package:dartz/dartz.dart';
import 'package:penyintas_app/core/error/failures.dart';
import 'package:penyintas_app/features/transaction/domain/entities/category_entity.dart';

abstract class CategoryRepository {
  Future<Either<Failure, List<CategoryEntity>>> getCategories();
  Future<Either<Failure, List<CategoryEntity>>> getLimitableCategories();

  // Fase 3C — CRUD untuk custom categories
  Future<Either<Failure, CategoryEntity>> createCategory(
    CategoryEntity category,
  );
  Future<Either<Failure, void>> updateCategory(CategoryEntity category);

  /// Hapus kategori + cascade hapus budget_limits dengan slug yang sama.
  Future<Either<Failure, void>> deleteCategory(String slug);
}
