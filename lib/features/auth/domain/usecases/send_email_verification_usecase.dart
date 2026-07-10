import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:penyintas_app/core/error/failures.dart';
import 'package:penyintas_app/core/usecases/usecase.dart';
import 'package:penyintas_app/features/auth/domain/repositories/auth_repository.dart';

class SendEmailVerificationUseCase
    extends UseCase<void, SendEmailVerificationParams> {
  SendEmailVerificationUseCase(this._repository);
  final AuthRepository _repository;

  @override
  Future<Either<Failure, void>> call(SendEmailVerificationParams params) =>
      _repository.sendEmailVerification(languageCode: params.languageCode);
}

class SendEmailVerificationParams extends Equatable {
  const SendEmailVerificationParams({this.languageCode});
  final String? languageCode;

  @override
  List<Object?> get props => [languageCode];
}
