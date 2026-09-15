import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:penyintas_app/core/error/failures.dart';
import 'package:penyintas_app/core/usecases/usecase.dart';
import 'package:penyintas_app/core/utils/app_clock.dart';
import 'package:penyintas_app/features/challenge/data/datasources/challenge_local_datasource.dart';
import 'package:penyintas_app/features/challenge/data/datasources/challenge_settings_datasource.dart';
import 'package:penyintas_app/features/challenge/domain/challenge_calculator.dart';
import 'package:penyintas_app/features/challenge/domain/entities/challenge_status.dart';
import 'package:penyintas_app/features/challenge/domain/repositories/challenge_repository.dart';

/// T16. TIDAK terkunci jendela — ini bukan pintas membersihkan riwayat,
/// melainkan pernyataan user bahwa ia tidak mau fitur ini.
///
/// URUTAN MENGIKAT: tutup baris DULU, baru balik sakelar. Urutan terbalik
/// meninggalkan tantangan hidup di bawah sakelar mati bila penutupan gagal —
/// dan itu lolos semua test kecuali U75.
class SetChallengeEnabled implements UseCase<void, SetChallengeEnabledParams> {
  SetChallengeEnabled({
    required ChallengeRepository repo,
    required ChallengeLocalDatasource local,
    required ChallengeSettingsDatasource settings,
    required AppClock clock,
  }) : _repo = repo,
       _local = local,
       _settings = settings,
       _clock = clock;

  final ChallengeRepository _repo;
  final ChallengeLocalDatasource _local;
  final ChallengeSettingsDatasource _settings;
  final AppClock _clock;

  @override
  Future<Either<Failure, void>> call(SetChallengeEnabledParams p) async {
    if (!p.enabled) {
      final mingguIni = weekKeyOf(_clock.now());
      final row = await _local.findWeek(mingguIni);
      if (row != null && row.status == ChallengeStatus.active) {
        final kategori = row.category;
        final terpakai = kategori == null
            ? 0
            : await _local.spentInWeek(weekKey: mingguIni, category: kategori);
        final hasil = await _repo.resolveWeek(
          weekKey: mingguIni,
          status: ChallengeStatus.skipped,
          finalSpent: terpakai,
        );
        if (hasil.isLeft()) return hasil; // sakelar TIDAK ikut berubah
      }
    }
    await _settings.setEnabled(p.enabled);
    return const Right(null);
  }
}

class SetChallengeEnabledParams extends Equatable {
  const SetChallengeEnabledParams({required this.enabled});

  final bool enabled;

  @override
  List<Object> get props => [enabled];
}
