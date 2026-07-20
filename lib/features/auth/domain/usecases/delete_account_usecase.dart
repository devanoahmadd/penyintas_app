import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:penyintas_app/core/error/failures.dart';
import 'package:penyintas_app/core/usecases/usecase.dart';
import 'package:penyintas_app/features/auth/domain/repositories/auth_repository.dart';

class DeleteAccountUseCase extends UseCase<void, DeleteAccountParams> {
  DeleteAccountUseCase(this._repository);
  final AuthRepository _repository;

  @override
  Future<Either<Failure, void>> call(DeleteAccountParams params) =>
      _repository.deleteAccount(password: params.password);
}

class DeleteAccountParams extends Equatable {
  const DeleteAccountParams({this.password});
  final String? password;

  @override
  // password dikecualikan dari props agar tidak bocor lewat toString()
  // jika BlocObserver logging ditambahkan kelak.
  List<Object> get props => [];
}
