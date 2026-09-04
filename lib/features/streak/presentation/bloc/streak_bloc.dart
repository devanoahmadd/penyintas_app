import 'dart:async';

import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:penyintas_app/core/error/failures.dart';
import 'package:penyintas_app/core/usecases/usecase.dart';
import 'package:penyintas_app/core/utils/app_clock.dart';
import 'package:penyintas_app/core/utils/date_helper.dart';
import 'package:penyintas_app/features/streak/domain/entities/streak_snapshot.dart';
import 'package:penyintas_app/features/streak/domain/repositories/streak_repository.dart';
import 'package:penyintas_app/features/streak/domain/usecases/mark_today_no_spend_usecase.dart';
import 'package:penyintas_app/features/streak/domain/usecases/undo_today_no_spend_usecase.dart';
import 'package:penyintas_app/features/streak/domain/usecases/watch_streak_snapshot_usecase.dart';
import 'package:penyintas_app/features/streak/presentation/bloc/streak_event.dart';
import 'package:penyintas_app/features/streak/presentation/bloc/streak_state.dart';

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
  }) : _watchSnapshot = watchSnapshot,
       _restoringGrace = restoringGrace,
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

  Timer? _midnightTimer;
  Timer? _restoringTimer;
  bool _restoringHabis = false;

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
    await emit.onEach<StreakSnapshot>(
      _watchSnapshot(),
      onData: (snapshot) => _serap(snapshot, emit),
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
  /// mematikan rantainya.
  Future<void> _serap(StreakSnapshot snapshot, Emitter<StreakState> emit) {
    _gerbang = _gerbang
        .then((_) => _serapSekali(snapshot, emit))
        .catchError((Object _) {});
    return _gerbang;
  }

  Future<void> _serapSekali(
    StreakSnapshot snapshot,
    Emitter<StreakState> emit,
  ) async {
    // `emit.onEach` tidak menunggu `onData`, jadi handler-nya bisa SUDAH mati
    // saat pekerjaan async di bawah selesai — misalnya karena `restartable()`
    // membatalkannya ketika rute lain men-dispatch StreakSubscribed lagi.
    if (emit.isDone) return;
    final meta = await _repo.readMeta();
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
    if (memulihkan) _armRestoringTimer();

    if (emit.isDone) return;
    emit(
      state.copyWith(
        status: memulihkan ? StreakStatus.restoring : StreakStatus.ready,
        snapshot: snapshot,
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
        (f) => state.copyWith(
          isMarking: false,
          status: StreakStatus.ready,
          failure: f,
        ),
        (_) => state.copyWith(isMarking: false),
      ),
    );
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
  }

  /// Konsumsi sekali-pakai `pendingCelebration`. BlocListener memanggil ini
  /// SESUDAH toast tampil; slot dikosongkan di state DAN ambangnya dinaikkan
  /// di StreakMeta, jadi perayaan tidak terulang setelah proses di-restart.
  Future<void> _onMilestoneShown(
    StreakMilestoneShown e,
    Emitter<StreakState> emit,
  ) async {
    final meta = await _repo.readMeta();
    if (meta.lastCelebratedRuas != e.ruas) {
      await _repo.saveMeta(meta.copyWith(lastCelebratedRuas: e.ruas));
    }
    emit(state.copyWith(clearCelebration: true));
  }

  Future<void> _onBreakAcknowledged(
    StreakBreakAcknowledged e,
    Emitter<StreakState> emit,
  ) async {
    final hariPutus = state.snapshot?.lastBreakDay;
    if (hariPutus == null) return;
    final meta = await _repo.readMeta();
    if (meta.acknowledgedBreakDay != hariPutus) {
      await _repo.saveMeta(meta.copyWith(acknowledgedBreakDay: hariPutus));
    }
    emit(state.copyWith(clearBreak: true));
  }

  /// D-16. Dipanggil bersebelahan dengan `BootstrapCoordinator.reset()` saat
  /// logout. `StreakBloc` adalah singleton seumur proses sama seperti
  /// `BootstrapCoordinator` — tanpa method ini, jaring pengaman S6/D-10 yang
  /// sudah menyalak untuk satu akun tetap terkunci "habis" untuk akun
  /// berikutnya dalam sesi proses yang sama, dan proteksi T24 (riwayat belum
  /// tiba ≠ streak nol) berhenti berlaku justru saat paling dibutuhkan.
  void resetForNewSession() {
    _restoringTimer?.cancel();
    _restoringTimer = null;
    _restoringHabis = false;
    _anomaliSebelumnya = false;
  }

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
