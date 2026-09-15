import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:penyintas_app/core/error/failures.dart';
import 'package:penyintas_app/core/usecases/usecase.dart';
import 'package:penyintas_app/core/utils/app_clock.dart';
import 'package:penyintas_app/features/challenge/domain/challenge_calculator.dart';
import 'package:penyintas_app/features/challenge/domain/entities/challenge_snapshot.dart';
import 'package:penyintas_app/features/challenge/domain/entities/challenge_status.dart';
import 'package:penyintas_app/features/challenge/domain/entities/challenge_week.dart';
import 'package:penyintas_app/features/challenge/domain/usecases/change_challenge_category.dart';
import 'package:penyintas_app/features/challenge/domain/usecases/ensure_and_resolve_challenge.dart';
import 'package:penyintas_app/features/challenge/domain/usecases/mark_challenge_result_seen.dart';
import 'package:penyintas_app/features/challenge/domain/usecases/set_challenge_enabled.dart';
import 'package:penyintas_app/features/challenge/domain/usecases/skip_challenge_week.dart';
import 'package:penyintas_app/features/challenge/domain/usecases/watch_challenge_snapshot.dart';
import 'package:penyintas_app/features/challenge/presentation/bloc/challenge_event.dart';
import 'package:penyintas_app/features/challenge/presentation/bloc/challenge_state.dart';

/// Perakit tunggal fitur Tantangan Mingguan.
///
/// Dua aliran bahan bertemu di sini dan hanya di sini:
/// - MURAH & REAKTIF (`ChallengeInputs` dari stream) — baris minggu ini,
///   progres, riwayat, sakelar;
/// - MAHAL & SESEKALI (`EnsureOutcome` dari usecase tulis) — `candidateCount`
///   dan `env`.
///
/// Karena bloc ini `registerLazySingleton` yang dipakai bersama tile dashboard
/// dan halaman `/challenge`, `phase` tetap dihitung SEKALI (S1) — hanya
/// tempatnya yang pindah dari repository ke sini (S-B).
///
/// SELURUH tulisan lahir dari handler event. Stream tidak pernah menulis
/// (D-2 Fase 1: menulis dari stream yang mengawasi tabelnya sendiri
/// menghidupkan loop tulis→emit→hitung→tulis).
class ChallengeBloc extends Bloc<ChallengeEvent, ChallengeState> {
  ChallengeBloc({
    required WatchChallengeSnapshot watchInputs,
    required EnsureAndResolveChallenge ensure,
    required ChangeChallengeCategory changeCategory,
    required SkipChallengeWeek skipWeek,
    required SetChallengeEnabled setEnabled,
    required MarkChallengeResultSeen markResultSeen,
    required AppClock clock,
  }) : _watchInputs = watchInputs,
       _ensure = ensure,
       _changeCategory = changeCategory,
       _skipWeek = skipWeek,
       _setEnabled = setEnabled,
       _markResultSeen = markResultSeen,
       _clock = clock,
       super(const ChallengeState()) {
    // M4 — `restartable()`: event ini di-dispatch di scope dashboard DAN di
    // rute /challenge, pada bloc singleton yang sama. Tanpa transformer, tiap
    // masuk-keluar halaman menumpuk satu langganan stream lagi, dan tiap
    // perubahan transaksi diproses berlipat. Presedennya `bills_bloc.dart:48`.
    on<ChallengeStarted>(_onStarted, transformer: restartable());
    on<ChallengeInputsUpdated>(_onInputsUpdated);
    on<ChallengeInputsFailed>(_onInputsFailed);
    on<ChallengeAppResumed>(_onAppResumed);
    on<ChallengeCategoryChanged>(_onCategoryChanged);
    on<ChallengeWeekSkipped>(_onWeekSkipped);
    on<ChallengeResultDismissed>(_onResultDismissed);
    on<ChallengeEnabledToggled>(_onEnabledToggled);
    on<ChallengeSessionReset>(_onSessionReset);
  }

  final WatchChallengeSnapshot _watchInputs;
  final EnsureAndResolveChallenge _ensure;
  final ChangeChallengeCategory _changeCategory;
  final SkipChallengeWeek _skipWeek;
  final SetChallengeEnabled _setEnabled;
  final MarkChallengeResultSeen _markResultSeen;
  final AppClock _clock;

  /// Bahan terakhir dari stream. Hidup di field privat, BUKAN di state: ia
  /// bahan, bukan tampilan. Resume membutuhkannya karena ia merakit ulang
  /// phase tanpa menunggu emit baru dari stream — dan stream memang tidak akan
  /// meng-emit, sebab pergantian minggu di background tak mengubah tabel apa
  /// pun.
  ChallengeInputs? _inputsTerakhir;

  // ── Langganan ─────────────────────────────────────────────────────────────

  Future<void> _onStarted(
    ChallengeStarted event,
    Emitter<ChallengeState> emit,
  ) async {
    // `loading` HANYA saat memang belum ada apa-apa untuk ditampilkan. Event
    // ini datang lagi tiap kali rutenya dimasuki; mengembalikannya ke
    // `loading` tiap kali membuat tile berkedip pada tiap navigasi.
    if (state.snapshot == null) {
      emit(state.copyWith(status: ChallengeViewStatus.loading));
    }
    await emit.onEach<Either<Failure, ChallengeInputs>>(
      _watchInputs(const NoParams()),
      // SENGAJA `add`, bukan `emit`: `onData` berjalan di luar alur kendali
      // handler ini (`emit.onEach` tidak menunggunya), dan satu-satunya cara
      // menjaga aturan "emit hanya dari handler terdaftar" tetap harfiah
      // adalah mengubah tiap kabar stream jadi event.
      onData: (hasil) => hasil.fold(
        (f) => add(ChallengeInputsFailed(f)),
        (inputs) => add(ChallengeInputsUpdated(inputs)),
      ),
      onError: (e, s) {
        addError(e, s);
        add(const ChallengeInputsFailed(UnknownFailure()));
      },
    );
  }

  Future<void> _onInputsUpdated(
    ChallengeInputsUpdated event,
    Emitter<ChallengeState> emit,
  ) async {
    _inputsTerakhir = event.inputs;
    final now = _clock.now();
    emit(
      state.copyWith(
        snapshot: _rakit(event.inputs, now),
        status: ChallengeViewStatus.ready,
        // Minor-6: HANYA hapus failure kalau ia berasal dari STREAM yang baru
        // saja pulih (`status` masih `failure`). Failure dari AKSI user yang
        // BARU SAJA gagal (mis. `skipWeek` ditolak) tetap `status: ready` —
        // emit stream dari tabel yang sama sekali tak berhubungan (mis. tick
        // transaksi lain) tidak boleh menghapusnya sebelum user sempat
        // membacanya.
        clearFailure: state.status == ChallengeViewStatus.failure,
      ),
    );
    await _pastikanMingguIni(emit, event.inputs);
  }

  void _onInputsFailed(
    ChallengeInputsFailed event,
    Emitter<ChallengeState> emit,
  ) {
    // Snapshot lama sengaja DIPERTAHANKAN: angka yang sudah terender lebih
    // berguna daripada layar kosong, selama indikator galatnya ikut tampil.
    emit(
      state.copyWith(
        status: state.snapshot == null
            ? ChallengeViewStatus.failure
            : state.status,
        failure: event.failure,
      ),
    );
  }

  /// M3 — resume TIDAK boleh diam. Pergantian minggu yang terjadi selagi app
  /// di background tidak mengubah satu tabel pun, jadi stream tak meng-emit dan
  /// [_onInputsUpdated] tak pernah jalan. Tanpa handler ini, minggu lalu baru
  /// ditutup ketika user kebetulan mencatat transaksi.
  Future<void> _onAppResumed(
    ChallengeAppResumed event,
    Emitter<ChallengeState> emit,
  ) => _pastikanMingguIni(emit, _inputsTerakhir);

  // ── Aksi user ─────────────────────────────────────────────────────────────

  Future<void> _onCategoryChanged(
    ChallengeCategoryChanged event,
    Emitter<ChallengeState> emit,
  ) async {
    final hasil = await _changeCategory(
      ChangeCategoryParams(
        weekKey: weekKeyOf(_clock.now()),
        category: event.category,
      ),
    );
    _serapHasilAksi(hasil, emit);
  }

  Future<void> _onWeekSkipped(
    ChallengeWeekSkipped event,
    Emitter<ChallengeState> emit,
  ) async {
    final hasil = await _skipWeek(
      SkipWeekParams(weekKey: weekKeyOf(_clock.now())),
    );
    _serapHasilAksi(hasil, emit);
  }

  Future<void> _onResultDismissed(
    ChallengeResultDismissed event,
    Emitter<ChallengeState> emit,
  ) async {
    final hasil = await _markResultSeen(
      MarkResultSeenParams(weekKey: event.weekKey),
    );
    _serapHasilAksi(hasil, emit);
  }

  Future<void> _onEnabledToggled(
    ChallengeEnabledToggled event,
    Emitter<ChallengeState> emit,
  ) async {
    final hasil = await _setEnabled(
      SetChallengeEnabledParams(enabled: event.enabled),
    );
    // IMPORTANT-2 — sakelar DINYALAKAN: lepas penjaga minggu supaya `ensure`
    // boleh dicoba lagi. Tanpa ini, kalau `ensure` terakhir kali jalan keluar
    // lewat gerbang murah `!aktif` (sakelar masih mati saat itu), tantangan
    // TAK PERNAH dibuat sampai Senin berikutnya walau user baru saja
    // menyalakannya — penjaga `lastEnsuredWeekKey` sudah terlanjur terpasang
    // untuk minggu ini dan tak ada jalur lain yang melepasnya.
    if (event.enabled && hasil.isRight() && !emit.isDone) {
      emit(state.copyWith(clearLastEnsuredWeekKey: true));
    }
    _serapHasilAksi(hasil, emit);
  }

  /// CRITICAL-1 — dipanggil dari `app_router.dart` di sebelah
  /// `StreakBloc.resetForNewSession()`, tiap kali user keluar dari akun
  /// (redirect ke `/login`). `ChallengeBloc` adalah `registerLazySingleton`
  /// seumur proses (dibagi tile dashboard dan halaman `/challenge`), jadi
  /// tanpa reset ini akun BERIKUTNYA yang login di minggu yang SAMA mewarisi
  /// `lastEnsuredWeekKey` akun lama: `_pastikanMingguIni` memulangkan diri di
  /// baris pertama dan `ensure` TAK PERNAH dipanggil untuk akun baru — baris
  /// minggu ini tak pernah dibuat, dan baris `active` lampau akun baru (yang
  /// baru saja ditarik `syncChallengesFromRemote`) tak pernah ditutup.
  /// `snapshot` dan `lastOutcome` lama juga dibuang: `_onInputsFailed`
  /// sengaja MEMPERTAHANKAN snapshot lama, jadi tanpa reset ini kategori dan
  /// riwayat akun lama bisa terender sesaat di layar akun baru.
  void resetForNewSession() => add(const ChallengeSessionReset());

  void _onSessionReset(
    ChallengeSessionReset event,
    Emitter<ChallengeState> emit,
  ) {
    _inputsTerakhir = null;
    emit(
      state.copyWith(
        status: ChallengeViewStatus.initial,
        clearSnapshot: true,
        clearFailure: true,
        clearLastEnsuredWeekKey: true,
        clearLastOutcome: true,
      ),
    );
  }

  /// Aksi yang BERHASIL sengaja tidak meng-emit snapshot baru: perubahannya
  /// datang lewat stream, satu jalur, tanpa dua sumber kebenaran.
  void _serapHasilAksi(
    Either<Failure, void> hasil,
    Emitter<ChallengeState> emit,
  ) {
    if (emit.isDone) return;
    hasil.fold(
      (f) => emit(state.copyWith(failure: f)),
      (_) => emit(state.copyWith(clearFailure: true)),
    );
  }

  // ── Perakitan & penjaga ───────────────────────────────────────────────────

  /// S-B — SATU tempat perakitan phase, dipakai tile dan halaman sekaligus.
  ///
  /// Penjaga basi `weekKey`: outcome dari minggu lain diperlakukan sebagai tak
  /// diketahui. Tanpa itu, beberapa milidetik pertama minggu baru menyusun
  /// phase dari kandidat minggu lalu — dan kalau kebetulan minggu lalu
  /// berkandidat nol, user disambut "belum cukup data" di minggu yang datanya
  /// justru lengkap. Akibat penjaganya jinak: skeleton sesaat, sampai ensure
  /// minggu baru selesai.
  ChallengeSnapshot _rakit(ChallengeInputs inputs, DateTime now) {
    final mingguIni = weekKeyOf(now);
    final outcome = state.lastOutcome?.weekKey == mingguIni
        ? state.lastOutcome
        : null;

    return ChallengeSnapshot(
      phase: resolveChallengePhase(
        weekThisWeek: inputs.weekThisWeek,
        spentThisWeek: inputs.spentThisWeek,
        enabled: inputs.enabled,
        env: outcome?.env,
        candidateCount: outcome?.candidateCount,
        historyEmpty: inputs.history.isEmpty,
        localNow: now,
      ),
      pendingResult: _hasilBelumDilihatTerbaru(inputs.history),
      spentThisWeek: inputs.spentThisWeek,
      excludedThisWeek: inputs.excludedThisWeek,
      history: inputs.history,
      // Dihitung DI SINI dari `AppClock`, bukan di stream: ia berubah karena
      // waktu berjalan, bukan karena tabel berubah.
      daysLeft: daysLeftInWeek(now),
    );
  }

  /// Hasil belum dilihat dengan `weekKey` TERBESAR. Jamaknya dirapikan langkah
  /// 1c (D22), bukan di sini — perakit hanya boleh MEMILIH.
  ChallengeWeek? _hasilBelumDilihatTerbaru(List<ChallengeWeek> history) {
    ChallengeWeek? terbaru;
    for (final w in history) {
      if (w.resultSeenAt != null) continue;
      if (w.status != ChallengeStatus.achieved &&
          w.status != ChallengeStatus.missed) {
        continue;
      }
      if (terbaru == null || w.weekKey > terbaru.weekKey) terbaru = w;
    }
    return terbaru;
  }

  /// Penjaga titik-3 (§4). Titik-3 adalah satu-satunya jalur yang masih bisa
  /// menghidupkan loop tulis→emit→hitung→tulis. Nilainya diperbarui SEBELUM
  /// `await`: satu weekKey = satu panggilan, dari jalur mana pun ia datang.
  /// Memperbaruinya sesudah `await` membuka jendela tempat emit stream kedua
  /// menyelinap masuk dan memanggil ensure untuk minggu yang sama.
  Future<void> _pastikanMingguIni(
    Emitter<ChallengeState> emit,
    ChallengeInputs? inputs,
  ) async {
    final mingguSekarang = weekKeyOf(_clock.now());
    if (state.lastEnsuredWeekKey == mingguSekarang) return;
    emit(state.copyWith(lastEnsuredWeekKey: mingguSekarang)); // SEBELUM await

    final hasil = await _ensure(const NoParams());
    if (emit.isDone) return;
    hasil.fold(
      (f) => emit(
        state.copyWith(
          failure: f,
          // IMPORTANT-2 — "sudah DICOBA" ≠ "sudah TUNTAS". Kegagalan transien
          // (mis. `createChallenge`/`holdWeek` mengembalikan `Left`) tidak
          // boleh mengunci minggu ini selamanya: lepas penjaga supaya jalur
          // berikutnya (resume, atau tick transaksi lain) boleh mencoba lagi.
          clearLastEnsuredWeekKey: true,
        ),
      ),
      (outcome) {
        // S-B — simpan apa yang ensure pelajari, lalu RAKIT ULANG: tanpa ini,
        // layar tetap menampilkan skeleton sampai ada perubahan tabel
        // berikutnya. Di Senin pertama seorang user, perubahan itu bisa tidak
        // pernah datang.
        emit(state.copyWith(lastOutcome: outcome));
        final terakhir = inputs;
        if (terakhir != null) {
          emit(
            state.copyWith(
              snapshot: _rakit(terakhir, _clock.now()),
              status: ChallengeViewStatus.ready,
            ),
          );
        }
      },
    );
  }
}
