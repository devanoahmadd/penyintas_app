import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:penyintas_app/core/error/failures.dart';
import 'package:penyintas_app/features/transaction/domain/repositories/category_repository.dart';

class DeleteCategoryParams extends Equatable {
  const DeleteCategoryParams({required this.slug, required this.isBuiltIn});
  final String slug;
  final bool isBuiltIn;

  @override
  List<Object> get props => [slug, isBuiltIn];
}

class DeleteCategoryUseCase {
  DeleteCategoryUseCase(this._repo);
  final CategoryRepository _repo;

  Future<Either<Failure, void>> call(DeleteCategoryParams params) async {
    if (params.isBuiltIn) {
      return const Left(ValidationFailure('Tidak bisa menghapus kategori bawaan.'));
    }
    return _repo.deleteCategory(params.slug);
  }
}
