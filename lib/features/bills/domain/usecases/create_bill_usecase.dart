import 'package:dartz/dartz.dart';
import 'package:penyintas_app/core/error/failures.dart';
import 'package:penyintas_app/core/usecases/usecase.dart';
import 'package:penyintas_app/features/bills/data/models/bill_model.dart';
import 'package:penyintas_app/features/bills/domain/repositories/bill_repository.dart';

class CreateBillUseCase implements UseCase<int, BillModel> {
  const CreateBillUseCase(this._repository);
  final BillRepository _repository;

  @override
  Future<Either<Failure, int>> call(BillModel params) =>
      _repository.createBill(params);
}
