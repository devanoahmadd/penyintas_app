import 'package:penyintas_app/features/auth/domain/entities/user_entity.dart';
import 'package:penyintas_app/features/auth/domain/repositories/auth_repository.dart';

// Tidak pakai StreamUseCase<Either<...>> — auth state stream tidak bisa gagal
// secara meaningful. null = logged out, UserEntity = logged in.
class WatchAuthStateUseCase {
  WatchAuthStateUseCase(this._repository);
  final AuthRepository _repository;

  Stream<UserEntity?> call() => _repository.authStateChanges;
}
