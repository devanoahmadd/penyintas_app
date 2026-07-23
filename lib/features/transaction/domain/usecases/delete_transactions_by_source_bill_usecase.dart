import 'package:dartz/dartz.dart';
import 'package:penyintas_app/core/error/failures.dart';
import 'package:penyintas_app/core/usecases/usecase.dart';
import 'package:penyintas_app/features/transaction/domain/repositories/transaction_repository.dart';

/// Hapus semua transaksi yang bersumber dari sebuah tagihan (undo tagihan).
class DeleteTransactionsBySourceBillUseCase implements UseCase<void, int> {
  const DeleteTransactionsBySourceBillUseCase(this._repository);
  final TransactionRepository _repository;

  @override
  Future<Either<Failure, void>> call(int params) =>
      _repository.deleteTransactionsBySourceBill(params);
}
