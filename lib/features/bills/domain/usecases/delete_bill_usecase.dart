import 'package:dartz/dartz.dart';
import 'package:penyintas_app/core/error/failures.dart';
import 'package:penyintas_app/core/usecases/usecase.dart';
import 'package:penyintas_app/features/bills/domain/repositories/bill_repository.dart';

class DeleteBillUseCase implements UseCase<void, int> {
  const DeleteBillUseCase(this._repository);
  final BillRepository _repository;

  @override
  Future<Either<Failure, void>> call(int params) =>
      _repository.deleteBill(params);
}
