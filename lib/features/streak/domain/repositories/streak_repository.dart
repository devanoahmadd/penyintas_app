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
  /// KONTRAK NILAI BALIK (TEMUAN I5/R1/R2 — wajib dibaca sebelum menangani
  /// `Left`):
  ///
  ///  - `Left(ValidationFailure)` — satu-satunya kasus yang BENAR-BENAR
  ///    berarti "tidak ada yang berubah". Ini penjaga jam mode netral:
  ///    penandaan ditolak SEBELUM baris lokal mana pun disentuh.
  ///
  ///  - `Left(CacheFailure)` — TIDAK MENJAMIN APA PUN soal apakah efek lokal
  ///    terjadi (TEMUAN R1, koreksi dari draf sebelumnya). Try-block luar
  ///    membungkus SELURUH method, termasuk pembacaan di awal
  ///    (`hasMark()`/`readMeta()`) — kalau salah satu dari situ yang
  ///    melempar, `CacheFailure` yang SAMA PERSIS kembali tapi baris lokal
  ///    belum tersentuh SAMA SEKALI. Kalau yang melempar `addToSyncQueue()`
  ///    di akhir, baris lokal SUDAH `insertMark()`-ed dan
  ///    `requestRecompute()` sudah dipanggil. Nilai balik `CacheFailure`
  ///    TIDAK BISA membedakan dua keadaan itu — satu-satunya cara consumer
  ///    (BLoC) tahu keadaan sebenarnya adalah STREAM SNAPSHOT, bukan nilai
  ///    balik method ini. Jangan asumsikan `Left` = "belum terjadi apa-apa"
  ///    maupun "sudah rollback otomatis" — keduanya sama-sama bisa salah.
  ///
  ///  - `Right(null)` mencakup beberapa jalur berbeda, SEMUANYA "sukses"
  ///    dari sudut pandang caller:
  ///     - no-op idempoten (hari sudah ditandai, D-4);
  ///     - berhasil tersinkron langsung (online, push ke remote sukses);
  ///     - diantre ke `SyncQueue` untuk dikirim nanti — ini terjadi BAIK
  ///       saat offline MAUPUN saat online tapi `remote.saveMark()`
  ///       melempar (TEMUAN R4, koreksi label "diantre offline" yang
  ///       sebelumnya melewatkan cabang kedua ini);
  ///     - baris `viaClockCorrection` yang sengaja tak pernah diantre
  ///       (§4.7);
  ///     - user belum login (`uid == null`, TEMUAN R2) — baris lokal
  ///       TERTULIS tapi TIDAK ADA percobaan sync apa pun, bukan salah satu
  ///       dari tiga jalur sync di atas.
  Future<Either<Failure, void>> markToday();

  /// Urungkan penanda `today` — penghapusan baris, bukan penandaan-terbalik.
  ///
  /// KONTRAK NILAI BALIK sama seperti [markToday] (TEMUAN I5/R1): `Left`
  /// method ini SELALU `CacheFailure`, tapi TIDAK MENJAMIN APA PUN soal
  /// apakah `deleteMark()`/`requestRecompute()` sudah terjadi — try-block
  /// luar membungkus pembacaan `findMark()` di awal JUGA. Sama seperti
  /// [markToday], stream snapshot adalah satu-satunya sumber kebenaran;
  /// nilai balik ini bukan.
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
