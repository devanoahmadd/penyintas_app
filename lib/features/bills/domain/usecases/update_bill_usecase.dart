import 'package:dartz/dartz.dart';
import 'package:penyintas_app/core/error/failures.dart';
import 'package:penyintas_app/core/usecases/usecase.dart';
import 'package:penyintas_app/features/bills/data/models/bill_model.dart';
import 'package:penyintas_app/features/bills/domain/repositories/bill_repository.dart';

class UpdateBillUseCase implements UseCase<void, BillModel> {
  const UpdateBillUseCase(this._repository);
  final BillRepository _repository;

  @override
  Future<Either<Failure, void>> call(BillModel params) =>
      _repository.updateBill(params);
}
