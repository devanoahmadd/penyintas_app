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

  /// Tandai `today` sebagai hari aman.
  ///
  /// KONTRAK NILAI BALIK (TEMUAN I5 — wajib dibaca sebelum menangani `Left`):
  ///
  ///  - `Left(ValidationFailure)` — satu-satunya kasus yang BENAR-BENAR
  ///    berarti "tidak ada yang berubah". Ini penjaga jam mode netral:
  ///    penandaan ditolak SEBELUM baris lokal mana pun disentuh.
  ///
  ///  - `Left(CacheFailure)` — TIDAK berarti "tidak terjadi apa-apa". Ia
  ///    dikembalikan SESUDAH efek lokal sudah terjadi: baris sudah
  ///    `insertMark()`-ed dan `requestRecompute()` sudah dipanggil (galat
  ///    yang ditangkap berasal dari `addToSyncQueue()` yang melempar, bukan
  ///    dari penulisan lokalnya). Consumer (BLoC) yang memperlakukan `Left`
  ///    sebagai "no-op" akan menampilkan galat sementara stream snapshot
  ///    justru sudah menunjukkan hari itu berubah — jangan asumsikan
  ///    `Left` = rollback otomatis.
  ///
  ///  - `Right(null)` mencakup beberapa jalur berbeda: no-op idempoten
  ///    (hari sudah ditandai, D-4), berhasil tersinkron, berhasil diantre
  ///    offline, MAUPUN baris `viaClockCorrection` yang sengaja tak pernah
  ///    diantre (§4.7) — semuanya "sukses" dari sudut pandang caller.
  Future<Either<Failure, void>> markToday();

  /// Urungkan penanda `today` — penghapusan baris, bukan penandaan-terbalik.
  ///
  /// KONTRAK NILAI BALIK sama seperti [markToday] (TEMUAN I5): `Left`
  /// method ini SELALU `CacheFailure`, dikembalikan SESUDAH `deleteMark()`
  /// dan `requestRecompute()` sudah terjadi — bukan sebelum. Jangan
  /// perlakukan `Left` sebagai bukti baris lokal belum terhapus.
  Future<Either<Failure, void>> unmarkToday();

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
