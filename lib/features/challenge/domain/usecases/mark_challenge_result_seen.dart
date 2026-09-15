import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:penyintas_app/core/error/failures.dart';
import 'package:penyintas_app/core/usecases/usecase.dart';
import 'package:penyintas_app/features/challenge/domain/repositories/challenge_repository.dart';

/// D11 — dipicu tombol ✕ di kartu hasil. `resultSeenAt` kolom lokal-saja: TIDAK
/// pernah dikirim ke Firestore, jadi usecase ini tidak boleh menyentuh
/// `isSynced` (lihat `ChallengeRepositoryImpl.markResultSeen`).
class MarkChallengeResultSeen implements UseCase<void, MarkResultSeenParams> {
  MarkChallengeResultSeen({required ChallengeRepository repo}) : _repo = repo;

  final ChallengeRepository _repo;

  @override
  Future<Either<Failure, void>> call(MarkResultSeenParams p) =>
      _repo.markResultSeen(p.weekKey);
}

class MarkResultSeenParams extends Equatable {
  const MarkResultSeenParams({required this.weekKey});

  final int weekKey;

  @override
  List<Object> get props => [weekKey];
}
