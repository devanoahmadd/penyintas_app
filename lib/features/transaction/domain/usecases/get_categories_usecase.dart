import 'package:dartz/dartz.dart';
import 'package:penyintas_app/core/error/failures.dart';
import 'package:penyintas_app/core/usecases/usecase.dart';
import 'package:penyintas_app/features/transaction/domain/entities/category_entity.dart';
import 'package:penyintas_app/features/transaction/domain/repositories/category_repository.dart';

class GetCategoriesUseCase extends UseCase<List<CategoryEntity>, NoParams> {
  GetCategoriesUseCase(this._repo);
  final CategoryRepository _repo;

  @override
  Future<Either<Failure, List<CategoryEntity>>> call(NoParams _) =>
      _repo.getCategories();
}
