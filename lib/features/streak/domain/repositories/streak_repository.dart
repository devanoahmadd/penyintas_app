import 'package:dartz/dartz.dart';
import 'package:penyintas_app/core/error/failures.dart';
import 'package:penyintas_app/features/streak/domain/entities/streak_meta_values.dart';
import 'package:penyintas_app/features/streak/domain/entities/streak_snapshot.dart';

abstract class StreakRepository {
  /// Snapshot yang selalu segar; sudah di-debounce 150 ms.
  Stream<StreakSnapshot> watchSnapshot();

  /// Paksa hitung ulang tanpa menunggu perubahan tabel — dipakai StreakBloc
  /// untuk timer tengah malam dan saat app kembali ke foreground.
  void requestRecompute();

  Future<Either<Failure, void>> markToday(); // Task 9
  Future<Either<Failure, void>> unmarkToday(); // Task 9

  /// Dipakai DailyReminderScheduler. Sengaja BUKAN Either: saat gagal ia
  /// mengembalikan `false` (= pengingat tetap dikirim). Gagal ke arah
  /// "pengingat muncul" jauh lebih murah daripada gagal ke arah "user
  /// kehilangan satu hari".
  Future<bool> isTodaySafe();

  Future<StreakMetaValues> readMeta();
  Future<void> saveMeta(StreakMetaValues meta);

  /// Tarik penanda dari Firestore sekali per sesi login. Mengikuti bentuk
  /// `GoalRepository.syncGoalsFromRemote()` persis, TANPA gerbang
  /// "sudah ada data lokal → jangan tarik" — lihat keputusan di
  /// [StreakRepositoryImpl.syncMarksFromRemote].
  Future<Either<Failure, int>> syncMarksFromRemote();

  /// Dorong baris `isSynced == false && !viaClockCorrection` ke remote.
  /// Mengembalikan jumlah yang berhasil naik. SENGAJA bukan `Either`: ini
  /// pekerjaan latar yang tidak boleh menggagalkan bootstrap (D-9).
  Future<int> pushPendingMarks();

  void dispose();
}
