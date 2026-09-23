import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:penyintas_app/core/error/failures.dart';
import 'package:penyintas_app/core/usecases/usecase.dart';
import 'package:penyintas_app/core/utils/app_clock.dart';
import 'package:penyintas_app/features/challenge/data/datasources/challenge_local_datasource.dart';
import 'package:penyintas_app/features/challenge/domain/challenge_calculator.dart';
import 'package:penyintas_app/features/challenge/domain/entities/challenge_status.dart';
import 'package:penyintas_app/features/challenge/domain/repositories/challenge_repository.dart';

/// T7 + T14. Dua penjaga, dan keduanya wajib:
/// - jendela Senin–Selasa (kalau tidak, tantangan bisa "diselamatkan" hari
///   Sabtu dengan pindah ke pos yang belum tersentuh);
/// - kategori HARUS ada di daftar kandidat minggu itu (kalau tidak, user bisa
///   mengarang pos apa pun berikut targetnya).
class ChangeChallengeCategory implements UseCase<void, ChangeCategoryParams> {
  ChangeChallengeCategory({
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
  Future<Either<Failure, void>> call(ChangeCategoryParams p) async {
    // ATURAN → Left bercopy.
    if (!isCreationWindow(_clock.now())) {
      return Left(
        ValidationFailure('Pos hanya bisa diganti Senin atau Selasa.'),
      );
    }

    // BALAPAN → Right diam (M7). `changeCategory` tidak menyetel `status`, jadi
    // tanpa penjaga ini baris `held` bisa berakhir punya pos dan target — baris
    // yang mustahil, dan tak satu pun layar tahu harus merendernya sebagai apa.
    // Jalur nyatanya: sheet terbuka, minggu berganti / device lain menutup
    // minggu ini, lalu user menekan "Pakai ini".
    final row = await _local.findWeek(p.weekKey);
    if (row == null || row.status != ChallengeStatus.active) {
      return const Right(null);
    }

    final kandidat = (await _repo.getCandidates(
      p.weekKey,
    )).getOrElse(() => const []);
    final pilihan = kandidat.where((c) => c.category == p.category).firstOrNull;
    if (pilihan == null) {
      return Left(
        ValidationFailure('Pos itu tidak ada di pilihan minggu ini.'),
      );
    }
    return _repo.changeCategory(
      weekKey: p.weekKey,
      category: pilihan.category,
      targetAmount: pilihan.target, // DIHITUNG ULANG, bukan dibawa
      baselineAmount: pilihan.baseline,
    );
  }
}

class ChangeCategoryParams extends Equatable {
  const ChangeCategoryParams({required this.weekKey, required this.category});

  final int weekKey;
  final String category;

  @override
  List<Object> get props => [weekKey, category];
}
