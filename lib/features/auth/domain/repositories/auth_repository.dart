import 'package:dartz/dartz.dart';
import 'package:penyintas_app/core/error/failures.dart';
import 'package:penyintas_app/features/auth/domain/entities/user_entity.dart';

abstract class AuthRepository {
  Future<Either<Failure, UserEntity>> signIn({
    required String email,
    required String password,
  });

  Future<Either<Failure, UserEntity>> signUp({
    required String email,
    required String password,
    required String name,
    String? languageCode,
  });

  Future<Either<Failure, void>> signOut();

  Future<Either<Failure, UserEntity?>> getCurrentUser();

  // Stream langsung tanpa Either — auth state tidak bisa gagal secara meaningful;
  // null = logged out, non-null = logged in.
  Stream<UserEntity?> get authStateChanges;

  Future<Either<Failure, void>> deleteAccount({required String password});

  Future<Either<Failure, void>> sendPasswordResetEmail(String email);

  Future<Either<Failure, void>> sendEmailVerification({String? languageCode});

  Future<Either<Failure, UserEntity?>> reloadCurrentUser();
}
