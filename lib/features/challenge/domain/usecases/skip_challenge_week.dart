import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:penyintas_app/core/error/failures.dart';
import 'package:penyintas_app/core/usecases/usecase.dart';
import 'package:penyintas_app/core/utils/app_clock.dart';
import 'package:penyintas_app/features/challenge/data/datasources/challenge_local_datasource.dart';
import 'package:penyintas_app/features/challenge/domain/challenge_calculator.dart';
import 'package:penyintas_app/features/challenge/domain/entities/challenge_status.dart';
import 'package:penyintas_app/features/challenge/domain/repositories/challenge_repository.dart';

/// T15. Terkunci jendela Senin–Selasa: kalau tersedia sepanjang minggu, "Lewati"
/// berubah jadi penghapus kegagalan — Sabtu melihat akan gagal, lalu lewati
/// supaya riwayat bersih.
class SkipChallengeWeek implements UseCase<void, SkipWeekParams> {
  SkipChallengeWeek({
    required ChallengeRepository repo,
    required ChallengeLocalDatasource local,
    required AppClock clock,
  }) : _repo = repo,
       _local = local,
       _clock = clock;

  final ChallengeRepository _repo;
  final ChallengeLocalDatasource _local;
  final AppClock _clock;

  @override
  Future<Either<Failure, void>> call(SkipWeekParams p) async {
    if (!isCreationWindow(_clock.now())) {
      return Left(ValidationFailure('Minggu ini sudah berjalan.'));
    }
    final row = await _local.findWeek(p.weekKey);
    if (row == null || row.status != ChallengeStatus.active) {
      return const Right(null);
    }
    final kategori = row.category;
    final terpakai = kategori == null
        ? 0
        : await _local.spentInWeek(weekKey: p.weekKey, category: kategori);
    return _repo.resolveWeek(
      weekKey: p.weekKey,
      status: ChallengeStatus.skipped,
      finalSpent: terpakai,
    );
  }
}

class SkipWeekParams extends Equatable {
  const SkipWeekParams({required this.weekKey});

  final int weekKey;

  @override
  List<Object> get props => [weekKey];
}
