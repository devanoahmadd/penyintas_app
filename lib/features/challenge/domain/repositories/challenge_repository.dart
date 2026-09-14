import 'package:dartz/dartz.dart';
import 'package:penyintas_app/features/challenge/domain/entities/challenge_status.dart';
import 'package:penyintas_app/core/error/failures.dart';
import 'package:penyintas_app/features/challenge/domain/entities/challenge_candidate.dart';
import 'package:penyintas_app/features/challenge/domain/entities/challenge_snapshot.dart';

abstract class ChallengeRepository {
  /// Bahan REAKTIF & MURAH untuk satu layar: baris minggu ini, progres,
  /// yang dikecualikan, riwayat, dan sakelar. TIDAK PERNAH menulis (aturan
  /// aliran satu arah §4).
  ///
  /// S-B — sengaja BUKAN `ChallengeSnapshot` ber-`phase`. `phase` juga butuh
  /// `candidateCount` (proyeksi empat minggu) dan `env` (satu bacaan dashboard
  /// ber-timeout tiga detik); menghitung ulang keduanya tiap kali tabel
  /// transaksi berubah adalah harga yang tak akan pernah sepadan. Keduanya
  /// datang dari `EnsureOutcome`, dan `ChallengeSnapshot` dirakit di BLoC —
  /// satu kali, di satu tempat, jadi S1 tetap utuh.
  Stream<Either<Failure, ChallengeInputs>> watchInputs();

  Future<Either<Failure, List<ChallengeCandidate>>> getCandidates(int weekKey);

  Future<Either<Failure, void>> createChallenge({
    required int weekKey,
    required String category,
    required int targetAmount,
    required int baselineAmount,
  });

  Future<Either<Failure, void>> holdWeek(int weekKey);

  Future<Either<Failure, void>> resolveWeek({
    required int weekKey,
    required ChallengeStatus status,
    required int finalSpent,
  });

  Future<Either<Failure, void>> changeCategory({
    required int weekKey,
    required String category,
    required int targetAmount,
    required int baselineAmount,
  });

  /// D11 — dipicu tombol ✕. Satu-satunya penulis `resultSeenAt` dari sisi UI.
  Future<Either<Failure, void>> markResultSeen(int weekKey);

  /// D22 — dipanggil HANYA dari langkah 1c EnsureAndResolveChallenge.
  Future<Either<Failure, void>> markOlderResultsSeen({required int keepWeekKey});

  /// Dua blok TERPISAH dengan anggaran waktu sendiri — pelajaran D-9 Fase 1:
  /// push yang ditaruh di dalam blok pull ber-timeout membuat pull tak pernah
  /// jalan, dan riwayat user tak pernah pulih meski semua test hijau.
  Future<Either<Failure, void>> syncChallengesFromRemote();
  Future<Either<Failure, void>> pushPendingChallenges();
}
