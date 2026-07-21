import 'package:dartz/dartz.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:penyintas_app/core/error/exceptions.dart';
import 'package:penyintas_app/core/error/failures.dart';
import 'package:penyintas_app/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:penyintas_app/features/auth/domain/entities/user_entity.dart';
import 'package:penyintas_app/features/auth/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({required this.remoteDataSource});
  final AuthRemoteDataSource remoteDataSource;

  @override
  Future<Either<Failure, UserEntity>> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final user = await remoteDataSource.signIn(
        email: email,
        password: password,
      );
      return Right(user);
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } catch (e, s) {
      try {
        FirebaseCrashlytics.instance.recordError(e, s);
      } catch (_) {}
      return const Left(UnknownFailure());
    }
  }

  @override
  Future<Either<Failure, UserEntity>> signUp({
    required String email,
    required String password,
    required String name,
    String? languageCode,
  }) async {
    try {
      final user = await remoteDataSource.signUp(
        email: email,
        password: password,
        name: name,
        languageCode: languageCode,
      );
      return Right(user);
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } catch (e, s) {
      try {
        FirebaseCrashlytics.instance.recordError(e, s);
      } catch (_) {}
      return const Left(UnknownFailure());
    }
  }

  @override
  Future<Either<Failure, void>> signOut() async {
    try {
      await remoteDataSource.signOut();
      return const Right(null);
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } catch (e, s) {
      try {
        FirebaseCrashlytics.instance.recordError(e, s);
      } catch (_) {}
      return const Left(UnknownFailure());
    }
  }

  @override
  Future<Either<Failure, UserEntity?>> getCurrentUser() async {
    try {
      final user = await remoteDataSource.getCurrentUser();
      return Right(user);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e, s) {
      try {
        FirebaseCrashlytics.instance.recordError(e, s);
      } catch (_) {}
      return const Left(UnknownFailure());
    }
  }

  @override
  Future<Either<Failure, void>> deleteAccount({
    required String? password,
  }) async {
    try {
      if (password != null) {
        await remoteDataSource.reauthenticate(password: password);
      } else {
        final ok = await remoteDataSource.reauthenticateWithGoogle();
        if (!ok) {
          // User membatalkan dialog Google — pesan tenang, tanpa menakuti.
          return const Left(AuthFailure('Konfirmasi Google dibatalkan.'));
        }
      }
      await remoteDataSource.callDeleteAccount();
      return const Right(null);
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } catch (e, s) {
      try {
        FirebaseCrashlytics.instance.recordError(e, s);
      } catch (_) {}
      return const Left(UnknownFailure());
    }
  }

  @override
  Future<Either<Failure, void>> sendPasswordResetEmail(String email) async {
    try {
      await remoteDataSource.sendPasswordResetEmail(email);
      return const Right(null);
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } catch (e, s) {
      try {
        FirebaseCrashlytics.instance.recordError(e, s);
      } catch (_) {}
      return const Left(UnknownFailure());
    }
  }

  @override
  Stream<UserEntity?> get authStateChanges => remoteDataSource.authStateChanges;

  @override
  Future<Either<Failure, void>> sendEmailVerification({
    String? languageCode,
  }) async {
    try {
      await remoteDataSource.sendEmailVerification(languageCode: languageCode);
      return const Right(null);
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } catch (e, s) {
      try {
        FirebaseCrashlytics.instance.recordError(e, s);
      } catch (_) {}
      return const Left(UnknownFailure());
    }
  }

  @override
  Future<Either<Failure, UserEntity?>> reloadCurrentUser() async {
    try {
      final user = await remoteDataSource.reloadCurrentUser();
      return Right(user);
    } catch (e, s) {
      try {
        FirebaseCrashlytics.instance.recordError(e, s);
      } catch (_) {}
      return const Left(UnknownFailure());
    }
  }

  @override
  Future<Either<Failure, UserEntity?>> signInWithGoogle() async {
    try {
      final user = await remoteDataSource.signInWithGoogle();
      return Right(user);
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } catch (e, s) {
      try {
        FirebaseCrashlytics.instance.recordError(e, s);
      } catch (_) {}
      return const Left(UnknownFailure());
    }
  }
}
