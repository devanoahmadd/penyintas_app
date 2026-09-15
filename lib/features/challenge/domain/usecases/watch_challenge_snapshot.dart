import 'package:dartz/dartz.dart';
import 'package:penyintas_app/core/error/failures.dart';
import 'package:penyintas_app/core/usecases/usecase.dart';
import 'package:penyintas_app/features/challenge/domain/entities/challenge_snapshot.dart';
import 'package:penyintas_app/features/challenge/domain/repositories/challenge_repository.dart';

/// Pintu BLoC ke bahan reaktif fitur ini.
///
/// Namanya menyebut "snapshot" karena inilah langganan yang MELAHIRKAN
/// `ChallengeSnapshot` — tapi yang mengalir di sini sengaja [ChallengeInputs],
/// bukan snapshot jadi: `phase` butuh bahan mahal milik `EnsureOutcome`, dan
/// perakitan keduanya terjadi di BLoC supaya tetap SATU kali untuk tile
/// dashboard dan halaman `/challenge` sekaligus (S1/S-B).
class WatchChallengeSnapshot
    implements StreamUseCase<ChallengeInputs, NoParams> {
  const WatchChallengeSnapshot(this._repo);

  final ChallengeRepository _repo;

  @override
  Stream<Either<Failure, ChallengeInputs>> call(NoParams params) =>
      _repo.watchInputs();
}
