import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:penyintas_app/core/error/failures.dart';
import 'package:penyintas_app/core/usecases/usecase.dart';
import 'package:penyintas_app/features/auth/domain/entities/user_entity.dart';
import 'package:penyintas_app/features/auth/domain/repositories/auth_repository.dart';

class SignUpUseCase extends UseCase<UserEntity, SignUpParams> {
  SignUpUseCase(this._repository);
  final AuthRepository _repository;

  @override
  Future<Either<Failure, UserEntity>> call(SignUpParams params) {
    return _repository.signUp(
      email: params.email,
      password: params.password,
      name: params.name,
      languageCode: params.languageCode,
    );
  }
}

class SignUpParams extends Equatable {
  final String email;
  final String password;
  final String name;
  final String? languageCode;

  const SignUpParams({
    required this.email,
    required this.password,
    required this.name,
    this.languageCode,
  });

  @override
  // password dikecualikan dari props agar tidak bocor lewat toString()
  // jika BlocObserver logging ditambahkan kelak.
  List<Object> get props => [email, name];
}
