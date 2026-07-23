import 'package:dartz/dartz.dart';
import 'package:penyintas_app/core/error/failures.dart';
import 'package:penyintas_app/core/usecases/usecase.dart';
import 'package:penyintas_app/features/bills/domain/entities/bill_entity.dart';
import 'package:penyintas_app/features/bills/domain/repositories/bill_repository.dart';

class WatchActiveBillsUseCase
    implements StreamUseCase<List<BillEntity>, NoParams> {
  const WatchActiveBillsUseCase(this._repository);
  final BillRepository _repository;

  @override
  Stream<Either<Failure, List<BillEntity>>> call(NoParams params) =>
      _repository.watchActiveBills();
}
