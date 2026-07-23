import 'package:dartz/dartz.dart';
import 'package:penyintas_app/core/error/failures.dart';
import 'package:penyintas_app/core/usecases/usecase.dart';
import 'package:penyintas_app/features/bills/domain/repositories/bill_repository.dart';

class SyncBillsFromRemoteUseCase implements UseCase<int, NoParams> {
  const SyncBillsFromRemoteUseCase(this._repository);
  final BillRepository _repository;

  @override
  Future<Either<Failure, int>> call(NoParams params) =>
      _repository.syncBillsFromRemote();
}
