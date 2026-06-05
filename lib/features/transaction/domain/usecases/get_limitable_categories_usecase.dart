import 'package:dartz/dartz.dart';
import 'package:penyintas_app/core/error/failures.dart';
import 'package:penyintas_app/core/usecases/usecase.dart';
import 'package:penyintas_app/features/transaction/domain/entities/category_entity.dart';
import 'package:penyintas_app/features/transaction/domain/repositories/category_repository.dart';

/// Mengembalikan kategori yang bisa diberi batas anggaran (isLimitable = true).
/// Dipakai oleh BudgetLimitsBloc untuk menggantikan daftar hardcode.
class GetLimitableCategoriesUseCase
    extends UseCase<List<CategoryEntity>, NoParams> {
  GetLimitableCategoriesUseCase(this._repo);
  final CategoryRepository _repo;

  @override
  Future<Either<Failure, List<CategoryEntity>>> call(NoParams _) =>
      _repo.getLimitableCategories();
}
