import 'dart:async';

import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:penyintas_app/core/error/failures.dart';
import 'package:penyintas_app/core/usecases/usecase.dart';
import 'package:penyintas_app/core/utils/app_clock.dart';
import 'package:penyintas_app/core/utils/date_helper.dart';
import 'package:penyintas_app/features/streak/domain/entities/streak_meta_values.dart';
import 'package:penyintas_app/features/streak/domain/entities/streak_snapshot.dart';
import 'package:penyintas_app/features/streak/domain/repositories/streak_repository.dart';
import 'package:penyintas_app/features/streak/domain/usecases/mark_today_no_spend_usecase.dart';
import 'package:penyintas_app/features/streak/domain/usecases/undo_today_no_spend_usecase.dart';
import 'package:penyintas_app/features/streak/domain/usecases/watch_streak_snapshot_usecase.dart';
import 'package:penyintas_app/features/streak/presentation/bloc/streak_event.dart';
import 'package:penyintas_app/features/streak/presentation/bloc/streak_state.dart';

/// CATATAN DESAIN (jangan diubah tanpa alasan kuat): `_serapSekali` meng-emit
/// dari helper, di luar alur kendali handler-nya. Itu konsekuensi
/// `emit.onEach`, yang `onData`-nya bertipe `void Function(T)` dan karena itu
/// TIDAK ditunggu. `emit.onEach` tetap primitif yang benar di sini —
/// langganan-nya dibatalkan otomatis oleh `restartable()` dan oleh `close()`.
/// Harganya: `_gerbang` (serialisasi) dan tiga penjaga `emit.isDone` ada
/// SEMATA karena pola ini. Mengganti helper dengan `await for` di dalam
/// handler menghapus keduanya, tapi juga menghapus pembatalan otomatis itu.
///
/// Ambang ruas bambu. Tanpa poin, koin, atau level — mata uang virtual di app
/// keuangan rancu dengan uang nyata.
const _kRuas = <int>[3, 7, 14, 30, 60, 100];

class StreakBloc extends Bloc<StreakEvent, StreakState> {
  StreakBloc({
    required WatchStreakSnapshotUseCase watchSnapshot,
    required MarkTodayNoSpendUseCase markToday,
    required UndoTodayNoSpendUseCase undoToday,
    required StreakRepository repository,
    required AppClock clock,
    required bool Function() isBootstrapDone,

    /// Umur maksimal state `restoring` (S6). `BootstrapCoordinator.isDone`
    /// bernilai false SEBELUM `ensure()` pernah dipanggil dan false LAGI
    /// sesudah `reset()` saat logout — jadi tanpa batas ini, user baru yang
    /// offline bisa disambut skeleton selamanya.
    ///
    /// D-10: 20 detik, BUKAN 6. `BootstrapCoordinator._run()` menjalankan
    /// `_prefs.syncOnLaunch(...)` tanpa `timeout` sama sekali, jadi
    /// terburuknya tidak berbatas. Jaring yang menyalak duluan mengembalikan
    /// persis kebohongan T24. Ia murni jaring pengaman — pelepas normalnya
    /// `StreakRefreshed` dari `BootstrapCoordinator.onComplete`.
    Duration restoringGrace = const Duration(seconds: 20),

    /// Dipanggil sesudah penandaan / undo yang BERHASIL — yaitu setiap kali
    /// status "hari ini aman" bisa berubah. Diisi DI dengan
    /// `DailyReminderScheduler.reschedule()`: hari yang jadi aman harus
    /// mendiamkan pengingat harian, dan undo harus menghidupkannya lagi.
    ///
    /// Lewat callback, BLoC tidak bergantung pada kelas notifikasi mana pun.
    /// OPSIONAL dan berdefault no-op supaya test yang tidak peduli soal
    /// pengingat tak perlu menyediakannya.
    Future<void> Function()? onDaySafetyChanged,
  }) : _watchSnapshot = watchSnapshot,
       _restoringGrace = restoringGrace,
       _onDaySafetyChanged = onDaySafetyChanged,
       _markToday = markToday,
       _undoToday = undoToday,
       _repo = repository,
       _clock = clock,
       _isBootstrapDone = isBootstrapDone,
       super(const StreakState()) {
    on<StreakSubscribed>(_onSubscribed, transformer: restartable());
    on<StreakRefreshed>((_, _) => _repo.requestRecompute());
    on<StreakRestoringTimedOut>((_, emit) {
      // Bootstrap tak kunjung selesai (offline, atau `ensure()` memang belum
      // pernah dipanggil). Skeleton abadi jauh lebih buruk daripada empty
      // state yang jujur.
      _restoringHabis = true;
      if (state.status == StreakStatus.restoring) {
        emit(state.copyWith(status: StreakStatus.ready));
      }
    });
    on<StreakSessionReset>((_, emit) {
      // C2: MEMBUANG STATE, bukan cuma field privat. BLoC ini singleton
      // seumur proses; tanpa emisi state kosong, akun berikutnya mewarisi
      // `snapshot`, `pendingCelebration`, dan `failure` milik akun sebelumnya
      // — dan penjaga `state.snapshot == null` di `_onSubscribed` ikut
      // menekan gerbang `loading` tepat saat ia paling dibutuhkan.
      _restoringTimer?.cancel();
      _restoringTimer = null;
      _restoringHabis = false;
      _anomaliSebelumnya = false;
      // IB1: naikkan SEBELUM emit — `_serapSekali` yang sedang berjalan
      // (dari langganan sesi lama) memotret generasi lama dan akan
      // membandingkannya dengan nilai baru ini sesudah `await`-nya kembali.
      _generasi++;
      emit(const StreakState());
    });
    on<StreakTodayMarked>(_onMarked);
    on<StreakTodayMarkUndone>(_onUndone);
    on<StreakMilestoneShown>(_onMilestoneShown);
    on<StreakBreakAcknowledged>(_onBreakAcknowledged);
  }

  final WatchStreakSnapshotUseCase _watchSnapshot;
  final MarkTodayNoSpendUseCase _markToday;
  final UndoTodayNoSpendUseCase _undoToday;
  final StreakRepository _repo;
  final AppClock _clock;
  final bool Function() _isBootstrapDone;
  final Duration _restoringGrace;
  final Future<void> Function()? _onDaySafetyChanged;

  Timer? _midnightTimer;
  Timer? _restoringTimer;
  bool _restoringHabis = false;

  /// IB1: penghitung generasi sesi. `StreakSessionReset` MENAIKKANNYA.
  /// `_onSubscribed` memotretnya SEKALI saat langganan dimulai (bukan
  /// `_serapSekali`, dan bukan per snapshot) — potretan itu lalu diteruskan
  /// apa adanya ke tiap `_serapSekali` lewat `_serap`, yang membandingkannya
  /// lagi sesudah titik `await`. Memotret ulang di dalam `_serapSekali` tidak
  /// menjaga apa pun: snapshot yang tiba SESUDAH reset akan memotret
  /// `_generasi` yang SUDAH versi baru, jadi pembandingnya selalu cocok
  /// dengan dirinya sendiri.
  ///
  /// Dipilih generasi, BUKAN pembatalan langganan `_watchSnapshot()`, karena
  /// `restartable()` di `_onSubscribed` adalah `switchMap` — ia hanya
  /// membatalkan emitter LAMA saat `StreakSubscribed` BARU datang, bukan saat
  /// `StreakSessionReset`. Tanpa penjaga ini, langganan sesi lama tetap hidup
  /// sesudah reset; kalau stream lama memancarkan satu snapshot susulan (mis.
  /// notifikasi Drift dari `clearAllLocalData()` saat logout), `_serapSekali`
  /// akan meng-emit lewat emitter LAMA — yang belum `isDone` — dan menimpa
  /// balik `StreakState()` kosong dengan data akun lama.
  ///
  /// Solusinya terkurung PENUH di dalam BLoC ini: `resetForNewSession()`
  /// tetap `add(StreakSessionReset())` polos, tidak perlu tahu apa pun soal
  /// siklus hidup `emit.onEach` — pemanggilnya (Task 12, di lokasi lain) juga
  /// tidak perlu tahu.
  int _generasi = 0;

  /// Anomali dicatat hanya saat TRANSISI, bukan tiap hitung ulang — kalau
  /// tidak, satu pembekuan dua hari akan menggelembungkan diagnostiknya.
  ///
  /// Catatan: ia hidup di memori, jadi anomali yang menetap dihitung sekali
  /// per cold start. Diterima — kolomnya murni diagnostik.
  bool _anomaliSebelumnya = false;

  /// Rantai serialisasi `_serap` (S2). `emit.onEach` TIDAK menunggu `onData`,
  /// jadi dua emisi berdekatan bisa menjalankan dua `readMeta → saveMeta`
  /// yang saling menimpa. Ini membuat urutannya deterministik tanpa mengunci
  /// stream-nya.
  Future<void> _gerbang = Future<void>.value();

  Future<void> _onSubscribed(
    StreakSubscribed event,
    Emitter<StreakState> emit,
  ) async {
    // Emit `loading` HANYA saat memang belum ada apa-apa untuk ditampilkan.
    // `StreakSubscribed` didispatch ulang setiap kali rute `/dashboard` atau
    // `/consistency` dibangun; mengembalikannya ke `loading` tiap kali membuat
    // tile berkedip dari angka nyata ke "Mulai hari ini" pada tiap navigasi.
    if (state.snapshot == null) {
      emit(state.copyWith(status: StreakStatus.loading));
    }
    _armMidnightTimer();
    // IB1: generasi milik LANGGANAN ini, dipotret SEKALI saat langganan
    // dimulai — BUKAN per snapshot di dalam `_serapSekali`. Memotret ulang
    // tiap snapshot tidak menjaga apa pun: snapshot yang tiba SESUDAH
    // `StreakSessionReset` akan memotret `_generasi` yang SUDAH versi baru,
    // sehingga pembandingnya selalu sama dengan dirinya sendiri. Potretan
    // sekali-per-langganan inilah yang tetap membeku ke generasi LAMA
    // selamanya sesudah reset, apa pun kapan snapshot-nya tiba.
    final generasi = _generasi;
    await emit.onEach<StreakSnapshot>(
      _watchSnapshot(),
      onData: (snapshot) => _serap(snapshot, emit, generasi),
      onError: (e, s) {
        if (emit.isDone) return;
        emit(
          state.copyWith(
            status: StreakStatus.failure,
            failure: const UnknownFailure(),
          ),
        );
      },
    );
  }

  /// Dijalankan berurutan lewat [_gerbang]; galat satu putaran tidak boleh
  /// mematikan rantainya. [generasi] diteruskan apa adanya dari langganan
  /// yang memanggilnya — lihat catatan IB1 di [_onSubscribed].
  Future<void> _serap(
    StreakSnapshot snapshot,
    Emitter<StreakState> emit,
    int generasi,
  ) {
    _gerbang = _gerbang
        .then((_) => _serapSekali(snapshot, emit, generasi))
        .catchError((Object e, StackTrace s) {
          // I2: JANGAN ditelan. `readMeta()` mendelegasikan mentah ke Drift;
          // kalau ia melempar, menelannya berarti nol emisi, nol status
          // galat, dan nol jejak Crashlytics — skeleton abadi lewat pintu
          // yang tak dijaga `_restoringTimer` (timer itu baru dipasang DI
          // DALAM `_serapSekali`, yang justru tak pernah sampai).
          addError(e, s);
          if (!emit.isDone) {
            emit(
              state.copyWith(
                status: StreakStatus.failure,
                failure: const CacheFailure(),
              ),
            );
          }
        });
    return _gerbang;
  }

  /// Satu-satunya pintu tulis StreakMeta di LUAR [_serapSekali] — dan ia
  /// memakai antrean yang SAMA (`_gerbang`).
  ///
  /// C1: ada tiga penulis meta, semuanya read-modify-write async.
  /// `_onMilestoneShown` dan `_onBreakAcknowledged` adalah handler terpisah
  /// dengan transformer `concurrent` bawaan, jadi tanpa antrean bersama
  /// tulisannya bisa terselip di antara `readMeta` dan `saveMeta` milik
  /// serapan snapshot — lalu tertimpa meta basi. Akibatnya nyata: toast ruas
  /// yang sama muncul dua kali, dan banner "ruas putus" hidup lagi setelah
  /// ditutup. Jendelanya normal: `markToday()` memanggil `requestRecompute()`
  /// dan repo men-debounce 150 ms, jadi dua snapshot berdekatan itu biasa.
  Future<void> _ubahMeta(StreakMetaValues Function(StreakMetaValues) ubah) {
    _gerbang = _gerbang
        .then((_) async {
          final meta = await _repo.readMeta();
          final next = ubah(meta);
          if (next != meta) await _repo.saveMeta(next);
        })
        .catchError((Object e, StackTrace s) {
          addError(e, s);
        });
    return _gerbang;
  }

  Future<void> _serapSekali(
    StreakSnapshot snapshot,
    Emitter<StreakState> emit,
    int generasi,
  ) async {
    // `emit.onEach` tidak menunggu `onData`, jadi handler-nya bisa SUDAH mati
    // saat pekerjaan async di bawah selesai — misalnya karena `restartable()`
    // membatalkannya ketika rute lain men-dispatch StreakSubscribed lagi.
    if (emit.isDone) return;
    final meta = await _repo.readMeta();
    // IB1: reset terjadi SELAMA `readMeta()` tertunda → jangan tulis balik
    // meta akun lama ke penyimpanan yang kini milik akun baru (atau kosong).
    if (generasi != _generasi) return;
    final hariDevice = localDayKey(_clock.now());

    // `maxSeenDay` HANYA NAIK — termasuk di cabang koreksi jam yang justru
    // menurunkan `lastSeenDay`. Yang boleh turun tidak dipakai menuduh; yang
    // dipakai menuduh tidak pernah membekukan.
    final anomaliBaru = snapshot.clockAnomalyDetected && !_anomaliSebelumnya;
    _anomaliSebelumnya = snapshot.clockAnomalyDetected;

    var next = meta.copyWith(
      lastSeenDay: snapshot.nextLastSeenDay,
      maxSeenDay: hariDevice > meta.maxSeenDay ? hariDevice : meta.maxSeenDay,
      clockAnomalyCount: anomaliBaru
          ? meta.clockAnomalyCount + 1
          : meta.clockAnomalyCount,
    );

    // Streak menyusut (putus atau transaksi dihapus) → turunkan ambang
    // perayaan agar ruas yang sama bisa dirayakan lagi saat dibangun kembali.
    if (snapshot.currentStreak < next.lastCelebratedRuas) {
      next = next.copyWith(
        lastCelebratedRuas: _ruasTertinggiDicapai(snapshot.currentStreak),
      );
    }

    // INVARIAN §5.5: hanya BLoC yang menulis StreakMeta, hanya di dalam
    // handler event terdaftar, dan HANYA bila nilainya benar-benar berubah.
    if (next != meta) await _repo.saveMeta(next);

    final ruasBaru = _ruasBelumDirayakan(
      snapshot.currentStreak,
      next.lastCelebratedRuas,
    );

    final putusBelumDiakui =
        snapshot.lastBreakDay != null &&
        snapshot.lastBreakDay != next.acknowledgedBreakDay;

    // "Riwayat belum tiba" ≠ "streak nol". `hasStarted == false` sendirian
    // tidak bisa membedakan user baru dari riwayat yang belum ditarik.
    // `_restoringHabis` memberi keadaan itu batas waktu (S6).
    final memulihkan =
        !_isBootstrapDone() && !snapshot.hasStarted && !_restoringHabis;

    // M1: penjaga DULU. Serapan basi tidak boleh memasang timer yang lalu
    // menembakkan `add(...)` ke bloc yang sudah ditutup. IB1: `saveMeta()` di
    // atas juga sebuah `await` — reset bisa lewat selama itu, jadi generasi
    // dicek lagi di sini sebelum emit.
    if (emit.isDone || generasi != _generasi) return;
    if (memulihkan) {
      _armRestoringTimer();
    } else {
      // M2: keluar dari `restoring` secara normal juga harus mematikan
      // timernya. Kalau tidak, ia tetap menyalak di detik ke-20 dan menyetel
      // `_restoringHabis` semu — mematikan jaring S6 untuk sisa sesi.
      _restoringTimer?.cancel();
      _restoringTimer = null;
    }
    emit(
      state.copyWith(
        status: memulihkan ? StreakStatus.restoring : StreakStatus.ready,
        snapshot: snapshot,
        // I1: snapshot segar mengakhiri galat lama. Tanpa ini `failure`
        // menetap selamanya dan `status: ready` + `failure: CacheFailure`
        // jadi kombinasi tanpa arti yang tak bisa dibedakan listener mana pun
        // dari galat yang baru datang.
        clearFailure: true,
        pendingCelebration: ruasBaru,
        clearCelebration: ruasBaru == null,
        unacknowledgedBreakRun: putusBelumDiakui
            ? snapshot.brokenRunLength
            : null,
        clearBreak: !putusBelumDiakui,
      ),
    );
    _armMidnightTimer();
  }

  int _ruasTertinggiDicapai(int streak) =>
      _kRuas.where((r) => r <= streak).fold(0, (a, b) => b > a ? b : a);

  int? _ruasBelumDirayakan(int streak, int terakhir) {
    final capai = _ruasTertinggiDicapai(streak);
    return capai > terakhir ? capai : null;
  }

  /// Sekali pasang saja — timer yang sudah berjalan tidak di-reset tiap
  /// snapshot, supaya batasnya benar-benar mengikat.
  void _armRestoringTimer() {
    if (_restoringTimer?.isActive ?? false) return;
    _restoringTimer = Timer(
      _restoringGrace,
      () => add(StreakRestoringTimedOut()),
    );
  }

  /// Hitung ulang saat tengah malam lewat selagi app terbuka.
  void _armMidnightTimer() {
    _midnightTimer?.cancel();
    final now = _clock.now();
    final besok = DateTime(now.year, now.month, now.day + 1);
    _midnightTimer = Timer(
      besok.difference(now) + const Duration(seconds: 1),
      () => add(StreakRefreshed()),
    );
  }

  Future<void> _onMarked(StreakTodayMarked e, Emitter<StreakState> emit) async {
    if (state.isMarking) return; // guard tap-ganda (constraint PK dayKey)
    emit(state.copyWith(isMarking: true));
    final hasil = await _markToday(const NoParams());
    // I5/R1: `Left` TIDAK menjamin "tidak ada yang berubah" — hanya stream
    // snapshot yang tahu keadaan sebenarnya. Karena itu tidak ada rollback
    // optimistik di sini; yang dilakukan hanya menaruh galat untuk SnackBar.
    emit(
      hasil.fold(
        // M3: JANGAN memaksa `status: ready` di sini. Snapshot lama sengaja
        // dipertahankan saat galat supaya kartunya tetap terender — menaikkan
        // status ke `ready` menyembunyikan indikator galat sambil memajang
        // angka basi seolah segar. Cabang `Right` pun tidak memaksa status.
        (f) => state.copyWith(isMarking: false, failure: f),
        (_) => state.copyWith(isMarking: false, clearFailure: true),
      ),
    );
    // HANYA cabang `Right`: kegagalan tidak membuat hari ini jadi aman, jadi
    // pengingat tak boleh ikut didiamkan. Efeknya idempoten, jadi urutannya
    // terhadap `emit` tidak kritis.
    if (hasil.isRight()) await _onDaySafetyChanged?.call();
  }

  Future<void> _onUndone(
    StreakTodayMarkUndone e,
    Emitter<StreakState> emit,
  ) async {
    // D-8: lewat tengah malam `unmarkToday()` mengembalikan `Right(null)`
    // TANPA efek apa pun. Karena itu jalur sukses sengaja tidak memancarkan
    // "berhasil diurungkan" — perubahan nyata datang lewat stream snapshot.
    final hasil = await _undoToday(const NoParams());
    hasil.fold((f) => emit(state.copyWith(failure: f)), (_) {});
    // Undo yang berhasil mengembalikan hari ini ke "belum aman" — pengingat
    // harian harus hidup lagi.
    if (hasil.isRight()) await _onDaySafetyChanged?.call();
  }

  /// Konsumsi sekali-pakai `pendingCelebration`. BlocListener memanggil ini
  /// SESUDAH toast tampil; slot dikosongkan di state DAN ambangnya dinaikkan
  /// di StreakMeta, jadi perayaan tidak terulang setelah proses di-restart.
  Future<void> _onMilestoneShown(
    StreakMilestoneShown e,
    Emitter<StreakState> emit,
  ) async {
    await _ubahMeta((meta) => meta.copyWith(lastCelebratedRuas: e.ruas));
    emit(state.copyWith(clearCelebration: true));
  }

  Future<void> _onBreakAcknowledged(
    StreakBreakAcknowledged e,
    Emitter<StreakState> emit,
  ) async {
    final hariPutus = state.snapshot?.lastBreakDay;
    if (hariPutus == null) return;
    await _ubahMeta((meta) => meta.copyWith(acknowledgedBreakDay: hariPutus));
    emit(state.copyWith(clearBreak: true));
  }

  /// D-16. Dipanggil bersebelahan dengan `BootstrapCoordinator.reset()` saat
  /// logout. `StreakBloc` adalah singleton seumur proses sama seperti
  /// `BootstrapCoordinator` — tanpa method ini, jaring pengaman S6/D-10 yang
  /// sudah menyalak untuk satu akun tetap terkunci "habis" untuk akun
  /// berikutnya dalam sesi proses yang sama, dan proteksi T24 (riwayat belum
  /// tiba ≠ streak nol) berhenti berlaku justru saat paling dibutuhkan.
  void resetForNewSession() => add(StreakSessionReset());

  @override
  Future<void> close() {
    _midnightTimer?.cancel();
    _restoringTimer?.cancel();
    // SENGAJA TIDAK memanggil `_repo.dispose()`. StreakRepositoryImpl adalah
    // lazySingleton yang dipakai BERSAMA halaman /consistency, tile bento,
    // kartu sore, dan DailyReminderScheduler; menutup pemicunya dari satu
    // consumer membuat `requestRecompute()` senyap jadi no-op untuk SEMUA
    // consumer lain sepanjang sisa umur proses.
    return super.close();
  }
}
