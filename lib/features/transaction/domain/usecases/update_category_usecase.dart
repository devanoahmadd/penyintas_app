import 'package:dartz/dartz.dart';
import 'package:penyintas_app/core/error/failures.dart';
import 'package:penyintas_app/features/transaction/domain/entities/category_entity.dart';
import 'package:penyintas_app/features/transaction/domain/repositories/category_repository.dart';

class UpdateCategoryUseCase {
  UpdateCategoryUseCase(this._repo);
  final CategoryRepository _repo;

  Future<Either<Failure, void>> call(CategoryEntity category) async {
    if (category.isBuiltIn) {
      return const Left(ValidationFailure('Tidak bisa mengubah kategori bawaan.'));
    }
    if (category.labelOverride == null || category.labelOverride!.trim().isEmpty) {
      return const Left(ValidationFailure('Nama kategori tidak boleh kosong.'));
    }
    return _repo.updateCategory(category);
  }
}
