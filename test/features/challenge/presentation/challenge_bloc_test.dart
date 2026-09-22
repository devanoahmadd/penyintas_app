import 'dart:async';
import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:penyintas_app/core/database/app_database.dart';
import 'package:penyintas_app/core/error/failures.dart';
import 'package:penyintas_app/core/network/network_info.dart';
import 'package:penyintas_app/core/usecases/usecase.dart';
import 'package:penyintas_app/core/utils/app_clock.dart';
import 'package:penyintas_app/features/challenge/data/datasources/challenge_local_datasource.dart';
import 'package:penyintas_app/features/challenge/data/datasources/challenge_remote_datasource.dart';
import 'package:penyintas_app/features/challenge/data/datasources/challenge_settings_datasource.dart';
import 'package:penyintas_app/features/challenge/data/repositories/challenge_repository_impl.dart';
import 'package:penyintas_app/features/challenge/domain/challenge_calculator.dart';
import 'package:penyintas_app/features/challenge/domain/entities/challenge_candidate.dart';
import 'package:penyintas_app/features/challenge/domain/entities/challenge_environment.dart';
import 'package:penyintas_app/features/challenge/domain/entities/challenge_phase.dart';
import 'package:penyintas_app/features/challenge/domain/entities/challenge_snapshot.dart';
import 'package:penyintas_app/features/challenge/domain/entities/challenge_status.dart';
import 'package:penyintas_app/features/challenge/domain/entities/ensure_outcome.dart';
import 'package:penyintas_app/features/challenge/domain/repositories/challenge_repository.dart';
import 'package:penyintas_app/features/challenge/domain/usecases/change_challenge_category.dart';
import 'package:penyintas_app/features/challenge/domain/usecases/ensure_and_resolve_challenge.dart';
import 'package:penyintas_app/features/challenge/domain/usecases/mark_challenge_result_seen.dart';
import 'package:penyintas_app/features/challenge/domain/usecases/set_challenge_enabled.dart';
import 'package:penyintas_app/features/challenge/domain/usecases/skip_challenge_week.dart';
import 'package:penyintas_app/features/challenge/domain/usecases/watch_challenge_snapshot.dart';
import 'package:penyintas_app/features/challenge/presentation/bloc/challenge_bloc.dart';
import 'package:penyintas_app/features/challenge/presentation/bloc/challenge_event.dart';
import 'package:penyintas_app/features/challenge/presentation/bloc/challenge_state.dart';
import 'package:penyintas_app/features/challenge/domain/ports/challenge_environment_port.dart';
import 'package:penyintas_app/features/transaction/domain/entities/category_entity.dart';
import 'package:penyintas_app/features/transaction/domain/usecases/get_limitable_categories_usecase.dart';

class _MockAuth extends Mock implements FirebaseAuth {}

class _MockNetwork extends Mock implements NetworkInfo {}

class _MockRemote extends Mock implements ChallengeRemoteDatasource {}

class _MockGetLimitable extends Mock implements GetLimitableCategoriesUseCase {}

class _MockEnvPort extends Mock implements ChallengeEnvironmentPort {}

class _MockEnsure extends Mock implements EnsureAndResolveChallenge {}

class _MockChangeCategory extends Mock implements ChangeChallengeCategory {}

class _MockSkipWeek extends Mock implements SkipChallengeWeek {}

class _MockSetEnabled extends Mock implements SetChallengeEnabled {}

class _MockMarkSeen extends Mock implements MarkChallengeResultSeen {}

/// Pembungkus repository yang MENGHITUNG langganan `watchInputs` yang masih
/// hidup. Dibutuhkan M4: `restartable()` tidak mengurangi berapa kali
/// `watchInputs()` DIPANGGIL — ia membatalkan langganan sebelumnya. Yang
/// membedakan bloc sehat dari bloc yang menumpuk langganan adalah berapa yang
/// masih HIDUP, bukan berapa yang pernah dibuat.
class _RepoPencatatLangganan implements ChallengeRepository {
  _RepoPencatatLangganan(this._asli);

  final ChallengeRepository _asli;

  int langgananAktif = 0;

  @override
  Stream<Either<Failure, ChallengeInputs>> watchInputs() {
    late StreamController<Either<Failure, ChallengeInputs>> c;
    StreamSubscription<Either<Failure, ChallengeInputs>>? sub;
    c = StreamController<Either<Failure, ChallengeInputs>>(
      onListen: () {
        langgananAktif++;
        sub = _asli.watchInputs().listen(
          c.add,
          onError: (Object e, StackTrace s) => c.addError(e, s),
        );
      },
      onCancel: () async {
        langgananAktif--;
        await sub?.cancel();
      },
    );
    return c.stream;
  }

  @override
  Future<Either<Failure, List<ChallengeCandidate>>> getCandidates(
    int weekKey,
  ) => _asli.getCandidates(weekKey);

  @override
  Future<Either<Failure, void>> createChallenge({
    required int weekKey,
    required String category,
    required int targetAmount,
    required int baselineAmount,
  }) => _asli.createChallenge(
    weekKey: weekKey,
    category: category,
    targetAmount: targetAmount,
    baselineAmount: baselineAmount,
  );

  @override
  Future<Either<Failure, void>> holdWeek(int weekKey) =>
      _asli.holdWeek(weekKey);

  @override
  Future<Either<Failure, void>> resolveWeek({
    required int weekKey,
    required ChallengeStatus status,
    required int finalSpent,
  }) => _asli.resolveWeek(
    weekKey: weekKey,
    status: status,
    finalSpent: finalSpent,
  );

  @override
  Future<Either<Failure, void>> changeCategory({
    required int weekKey,
    required String category,
    required int targetAmount,
    required int baselineAmount,
  }) => _asli.changeCategory(
    weekKey: weekKey,
    category: category,
    targetAmount: targetAmount,
    baselineAmount: baselineAmount,
  );

  @override
  Future<Either<Failure, void>> markResultSeen(int weekKey) =>
      _asli.markResultSeen(weekKey);

  @override
  Future<Either<Failure, void>> markOlderResultsSeen({
    required int keepWeekKey,
  }) => _asli.markOlderResultsSeen(keepWeekKey: keepWeekKey);

  @override
  Future<Either<Failure, void>> syncChallengesFromRemote() =>
      _asli.syncChallengesFromRemote();

  @override
  Future<Either<Failure, void>> pushPendingChallenges() =>
      _asli.pushPendingChallenges();
}

/// Mencatat event yang masuk — M4 menghitung berapa kali
/// `ChallengeInputsUpdated` tiba untuk SATU tulisan transaksi.
class _BlocTercatat extends ChallengeBloc {
  _BlocTercatat({
    required super.watchInputs,
    required super.ensure,
    required super.changeCategory,
    required super.skipWeek,
    required super.setEnabled,
    required super.markResultSeen,
    required super.clock,
  });

  final List<ChallengeEvent> tercatat = [];

  @override
  void onEvent(ChallengeEvent event) {
    tercatat.add(event);
    super.onEvent(event);
  }
}

// Senin 2026-09-07 .. Minggu 2026-09-13 — "minggu ini" di seluruh berkas ini.
const _mingguIni = 20260907;
const _mingguDepan = 20260914;
const _mingguLalu = 20260831;

const _envSehat = ChallengeEnvironment(
  budgetConfigured: true,
  survivalActive: false,
);

const _kategoriDefault = [
  CategoryEntity(
    id: 1,
    slug: 'food',
    isBuiltIn: true,
    isLimitable: true,
    type: 'expense',
    sortOrder: 0,
  ),
  CategoryEntity(
    id: 2,
    slug: 'transport',
    isBuiltIn: true,
    isLimitable: true,
    type: 'expense',
    sortOrder: 1,
  ),
  CategoryEntity(
    id: 3,
    slug: 'hiburan',
    isBuiltIn: true,
    isLimitable: true,
    type: 'expense',
    sortOrder: 2,
  ),
];

/// Jeda cukup untuk satu putaran Drift notify → recompute → emit bloc.
Future<void> _tunggu([int ms = 250]) =>
    Future<void>.delayed(Duration(milliseconds: ms));

/// Polling berdeadline longgar — pengganti `_tunggu` untuk asersi NILAI
/// ABSOLUT sesudah tidur tetap. Tidur tetap MERAH di CI lambat (pipeline
/// belum tuntas saat waktunya habis) dan bisa HAMPA di CI lambat yang lain
/// (jendela race tertutup sebelum tidurnya selesai — lihat U69b). Daya
/// pembeda asersinya utuh; yang hilang cuma ketergantungan pada kecepatan
/// mesin yang menjalankannya.
Future<void> tungguSampai(
  bool Function() kondisi, {
  Duration batas = const Duration(seconds: 5),
}) async {
  final akhir = DateTime.now().add(batas);
  while (!kondisi()) {
    if (DateTime.now().isAfter(akhir)) {
      fail('tungguSampai: kondisi tak terpenuhi dalam $batas');
    }
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
}

void main() {
  setUpAll(() {
    registerFallbackValue(const NoParams());
    registerFallbackValue(
      const ChangeCategoryParams(weekKey: 0, category: 'food'),
    );
    registerFallbackValue(const SkipWeekParams(weekKey: 0));
    registerFallbackValue(const SetChallengeEnabledParams(enabled: false));
    registerFallbackValue(const MarkResultSeenParams(weekKey: 0));
  });

  late AppDatabase db;
  late ChallengeLocalDatasource local;
  late ChallengeSettingsDatasource sakelar;
  late ChallengeRepositoryImpl repoAsli;
  late _RepoPencatatLangganan repo;
  late FixedClock clock;
  late _MockGetLimitable getLimitable;
  late _MockEnvPort envPort;
  late _MockEnsure ensureMock;
  late EnsureAndResolveChallenge ensureAsli;
  late _MockChangeCategory changeCategory;
  late _MockSkipWeek skipWeek;
  late _MockSetEnabled setEnabled;
  late _MockMarkSeen markSeen;
  late int ensureCalls;
  _BlocTercatat? bloc;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    local = ChallengeLocalDatasourceImpl(db);
    sakelar = ChallengeSettingsDatasourceImpl(db);
    clock = FixedClock(DateTime(2026, 9, 7, 9)); // Senin, di jendela

    final auth = _MockAuth();
    final network = _MockNetwork();
    // Tanpa uid: `_kirim` berhenti sebelum menyentuh jaringan/antrian.
    when(() => auth.currentUser).thenReturn(null);
    when(() => network.isConnected).thenAnswer((_) async => false);

    getLimitable = _MockGetLimitable();
    when(
      () => getLimitable(any()),
    ).thenAnswer((_) async => const Right(_kategoriDefault));

    repoAsli = ChallengeRepositoryImpl(
      local: local,
      remote: _MockRemote(),
      network: network,
      auth: auth,
      clock: clock,
      getLimitable: getLimitable,
      settings: sakelar,
    );
    repo = _RepoPencatatLangganan(repoAsli);

    envPort = _MockEnvPort();
    when(() => envPort.read()).thenAnswer((_) async => const Right(_envSehat));

    ensureAsli = EnsureAndResolveChallenge(
      repo: repo,
      local: local,
      getLimitable: getLimitable,
      env: envPort,
      settings: sakelar,
      clock: clock,
    );

    ensureCalls = 0;
    ensureMock = _MockEnsure();
    // Default: TIDAK menulis apa pun, hanya mencatat pemanggilan. Test yang
    // butuh tulisan sungguhan memasang `pakaiEnsureAsli()`.
    when(() => ensureMock(any())).thenAnswer((_) async {
      ensureCalls++;
      return Right(
        EnsureOutcome(
          weekKey: weekKeyOf(clock.now()),
          candidateCount: null,
          env: null,
        ),
      );
    });

    changeCategory = _MockChangeCategory();
    skipWeek = _MockSkipWeek();
    setEnabled = _MockSetEnabled();
    markSeen = _MockMarkSeen();
    when(
      () => changeCategory(any()),
    ).thenAnswer((_) async => const Right(null));
    when(() => skipWeek(any())).thenAnswer((_) async => const Right(null));
    when(() => setEnabled(any())).thenAnswer((_) async => const Right(null));
    when(() => markSeen(any())).thenAnswer((_) async => const Right(null));

    // Sakelar fitur menyala — fallback datasource adalah MATI (D3).
    await sakelar.setEnabled(true);
  });

  tearDown(() async {
    await bloc?.close();
    bloc = null;
    await db.close();
  });

  // ── Perkakas ──────────────────────────────────────────────────────────────

  _BlocTercatat buatBloc() => bloc = _BlocTercatat(
    watchInputs: WatchChallengeSnapshot(repo),
    ensure: ensureMock,
    changeCategory: changeCategory,
    skipWeek: skipWeek,
    setEnabled: setEnabled,
    markResultSeen: markSeen,
    clock: clock,
  );

  /// Mengalihkan `ensureMock` ke usecase SUNGGUHAN — tetap terhitung.
  void pakaiEnsureAsli() {
    when(() => ensureMock(any())).thenAnswer((_) async {
      ensureCalls++;
      return ensureAsli(const NoParams());
    });
  }

  var nomorTx = 0;
  Future<void> tambahTx({
    required DateTime tanggal,
    required int nominal,
    String kategori = 'food',
  }) => db
      .into(db.transactions)
      .insert(
        TransactionsCompanion.insert(
          txId: 'tx-${nomorTx++}',
          amount: nominal,
          category: kategori,
          type: 'expense',
          date: tanggal,
          createdAt: tanggal,
          updatedAt: tanggal,
        ),
      );

  /// Basis dua minggu untuk satu kategori — cukup lolos
  /// `kMinBaselineWeeksWithData`.
  Future<void> beriBasis(String kategori, int perMinggu) async {
    await tambahTx(
      tanggal: DateTime(2026, 8, 18, 12),
      nominal: perMinggu,
      kategori: kategori,
    );
    await tambahTx(
      tanggal: DateTime(2026, 8, 25, 12),
      nominal: perMinggu,
      kategori: kategori,
    );
  }

  Future<void> tulisBaris({
    required int weekKey,
    required ChallengeStatus status,
    String? kategori = 'food',
    int? targetAmount = 170000,
    int? finalSpent,
    DateTime? resultSeenAt,
  }) => db
      .into(db.weeklyChallenges)
      .insert(
        WeeklyChallengesCompanion.insert(
          weekKey: Value(weekKey),
          category: Value(kategori),
          targetAmount: Value(targetAmount),
          baselineAmount: const Value(200000),
          status: status,
          finalSpent: Value(finalSpent),
          timezone: 'WIB',
          createdAt: DateTime.utc(2026, 8, 1),
          updatedAt: DateTime.utc(2026, 8, 1),
          resultSeenAt: Value(resultSeenAt),
        ),
      );

  /// Tiga hasil yang BELUM dilihat — bahan langkah 1c (D22). Kalau stream
  /// merapikan (padahal tugasnya hanya memilih), dua di antaranya akan
  /// tertandai dan potret di bawah berubah.
  Future<void> tulisTigaHasilBelumDilihat() async {
    await tulisBaris(
      weekKey: 20260810,
      status: ChallengeStatus.achieved,
      finalSpent: 90000,
    );
    await tulisBaris(
      weekKey: 20260817,
      status: ChallengeStatus.missed,
      finalSpent: 220000,
    );
    await tulisBaris(
      weekKey: 20260824,
      status: ChallengeStatus.achieved,
      finalSpent: 80000,
    );
  }

  /// Potret SELURUH keadaan yang bisa ditulis fitur ini. Dibandingkan apa
  /// adanya: satu kolom bergeser, satu baris lahir, atau satu item antrian
  /// masuk — semuanya membuat string ini berbeda.
  Future<String> potretDb() async {
    final minggu = await db.select(db.weeklyChallenges).get();
    final antrian = await db.select(db.syncQueue).get();
    return [
      for (final r in minggu)
        '${r.weekKey}|${r.category}|${r.targetAmount}|${r.baselineAmount}|'
            '${r.status}|${r.finalSpent}|${r.resolvedAt}|${r.resultSeenAt}|'
            '${r.isSynced}|${r.updatedAt}',
      'antrian=${antrian.length}',
    ].join(';');
  }

  // ── U115 · stream tidak pernah menulis ────────────────────────────────────

  test('U115 · tiga hasil belum dilihat, HANYA watchInputs berjalan → NOL '
      'tulisan ke DB', () async {
    // Stream hanya boleh MEMILIH hasil terbaru, tak boleh MERAPIKAN yang lain
    // (itu tugas langkah 1c milik ensure). Menulis dari stream yang mengawasi
    // tabelnya sendiri juga menghidupkan loop tulis→emit→hitung→tulis (D-2).
    await tulisTigaHasilBelumDilihat();
    await tulisBaris(weekKey: _mingguLalu, status: ChallengeStatus.active);
    final sebelum = await potretDb();

    final sub = repoAsli.watchInputs().listen((_) {});
    await _tunggu(400);
    await sub.cancel();

    expect(await potretDb(), sebelum);
  });

  test('U115b · anti-hampa U115 — data tiga hasil belum dilihat memang '
      'tersedia lewat watchInputs (BUKAN pengunci seleksi produksi — lihat '
      'U115c)', () async {
    // Penjaga anti-hampa untuk U115: membuktikan jalur `pendingResult` memang
    // dilalui, jadi "nol tulisan" di atas bukan kebetulan karena stream diam.
    //
    // PERINGATAN (Task 16, temuan review Task 15) — nama LAMA test ini
    // ("stream memilih hasil belum dilihat dengan weekKey TERBESAR")
    // menyesatkan: ia menghitung ulang MAX weekKey DI DALAM TEST ITU
    // SENDIRI dari data mentah repo, dan TIDAK PERNAH memanggil
    // `ChallengeBloc._hasilBelumDilihatTerbaru` (method privat produksi,
    // `challenge_bloc.dart:327`). Kalau method itu punya bug (mis. `<`
    // bukan `>`, atau lupa memfilter status `achieved`/`missed`), test INI
    // TETAP HIJAU — dibuktikan lewat mutasi di laporan Task 16.
    // `U115c` di bawah adalah pengunci sungguhan, lewat BLoC UTUH.
    await tulisTigaHasilBelumDilihat();

    final inputs = await repoAsli.watchInputs().first;
    final pilihan = inputs.getOrElse(() => throw StateError('Left'));
    final terbaru = pilihan.history
        .where(
          (w) =>
              w.resultSeenAt == null &&
              (w.status == ChallengeStatus.achieved ||
                  w.status == ChallengeStatus.missed),
        )
        .map((w) => w.weekKey)
        .reduce((a, b) => a > b ? a : b);
    expect(terbaru, 20260824);
  });

  test('U115c · ChallengeBloc PENUH — pendingResult memilih weekKey TERBESAR '
      'di antara hasil achieved/missed belum dilihat, mengabaikan baris '
      'ber-status lain walau weekKey-nya lebih besar', () async {
    // Mengunci `_hasilBelumDilihatTerbaru` (challenge_bloc.dart:327) LEWAT
    // BLoC UTUH (`buatBloc()` + `ChallengeStarted()`) — bukan menghitung
    // ulang di dalam test (itu U115b, TERBUKTI TIDAK mengunci apa pun di
    // method produksi; lihat laporan Task 16 untuk bukti mutasi).
    //
    // Baris held di bawah SENGAJA diberi weekKey TERBESAR (20260831) —
    // lebih besar dari ketiga hasil achieved/missed (maks 20260824).
    // Kalau method produksi lupa memfilter status (mis. hanya membanding
    // `weekKey` tanpa syarat `achieved`/`missed`), baris held inilah yang
    // akan salah terpilih sebagai `pendingResult`.
    await tulisTigaHasilBelumDilihat();
    await tulisBaris(
      weekKey: _mingguLalu, // 20260831 — TERBESAR, tapi BUKAN achieved/missed
      status: ChallengeStatus.held,
      kategori: null,
      targetAmount: null,
    );

    final b = buatBloc()..add(const ChallengeStarted());
    await tungguSampai(() => b.state.snapshot != null);

    expect(
      b.state.snapshot!.pendingResult?.weekKey,
      20260824,
      reason:
          '20260824 adalah weekKey TERBESAR di antara baris achieved/missed '
          '(20260810, 20260817, 20260824) — baris held 20260831 harus '
          'diabaikan walau weekKey-nya lebih besar dari ketiganya.',
    );
  });

  // ── U68 · penjaga satu-minggu-satu-ensure ─────────────────────────────────

  test('U68 · stream diawasi lama TANPA pergantian minggu → ensure TIDAK '
      'dipanggil lagi sesudah yang pertama', () async {
    pakaiEnsureAsli();
    await beriBasis('food', 200000);
    await tulisBaris(weekKey: _mingguLalu, status: ChallengeStatus.active);

    final b = buatBloc()..add(const ChallengeStarted());
    await tungguSampai(() => ensureCalls >= 1); // ensure pertama SUDAH selesai

    // Tiga perubahan tabel transaksi — tiap satunya memicu emit stream.
    // Ditunggu lewat `tercatat` (bukan waktu tetap) supaya tiap iterasi
    // benar-benar menunggu `_onInputsUpdated` SELESAI diproses sebelum
    // menulis transaksi berikutnya.
    for (var i = 0; i < 3; i++) {
      final sebelum = b.tercatat.whereType<ChallengeInputsUpdated>().length;
      await tambahTx(tanggal: DateTime(2026, 9, 8, 10), nominal: 10000);
      await tungguSampai(
        () => b.tercatat.whereType<ChallengeInputsUpdated>().length > sebelum,
      );
    }

    expect(ensureCalls, 1);
  });

  // ── U69 · pergantian minggu ───────────────────────────────────────────────

  test('U69 · melintasi pergantian minggu selagi diawasi → ensure TEPAT '
      'sekali lagi', () async {
    buatBloc().add(const ChallengeStarted());
    await _tunggu();
    final n1 = ensureCalls;

    clock.at = DateTime(2026, 9, 14, 9); // Senin berikutnya
    await tambahTx(tanggal: DateTime(2026, 9, 14, 10), nominal: 10000);
    await _tunggu();

    expect(ensureCalls, n1 + 1);
  });

  test('U69b · penjaga dipasang SEBELUM await → emit stream KEDUA yang tiba '
      'selagi ensure berjalan tidak memanggil ensure lagi', () async {
    // Ditambahkan sesudah verifikasi sabotase: memindahkan
    // `emit(lastEnsuredWeekKey)` ke BAWAH `await _ensure(...)` semula tidak
    // memerahkan satu test pun — versi lama menahan jendelanya dengan
    // `Future.delayed` di kedua sisi, dan tak ada jaminan tidur test SELESAI
    // pas di tengah tidur ensure. `Completer` membuat urutannya
    // DETERMINISTIK: ensure pertama ditahan sampai test sendiri yang
    // melepaskannya, sesudah memastikan emit KEDUA sudah diproses penuh.
    final gerbang = Completer<void>();
    when(() => ensureMock(any())).thenAnswer((_) async {
      ensureCalls++;
      await gerbang.future;
      return Right(
        EnsureOutcome(
          weekKey: weekKeyOf(clock.now()),
          candidateCount: null,
          env: null,
        ),
      );
    });

    final b = buatBloc()..add(const ChallengeStarted());
    await tungguSampai(() => ensureCalls == 1); // ensure pertama SUDAH mulai

    final sebelum = b.tercatat.whereType<ChallengeInputsUpdated>().length;
    await tambahTx(tanggal: DateTime(2026, 9, 8, 10), nominal: 10000);
    await tungguSampai(
      () => b.tercatat.whereType<ChallengeInputsUpdated>().length > sebelum,
    ); // emit KEDUA sudah diproses _onInputsUpdated — penjaganya sudah dicek

    expect(ensureCalls, 1); // masih 1: penjaga menahan panggilan kedua

    // Lepas ensure pertama — jangan tinggalkan Future menggantung ke test
    // berikutnya.
    gerbang.complete();
    await tungguSampai(() => b.state.lastOutcome != null);
  });

  // ── U70 · fitur ini tidak pernah menyentuh penanda konsistensi ────────────

  group('U70 · baris jadi missed', () {
    setUp(() async {
      pakaiEnsureAsli();
      await beriBasis('food', 200000);
      // Minggu lalu `active` dengan target 100rb, tapi belanja 200rb →
      // evaluateResult menjatuhkannya ke `missed`.
      await tulisBaris(
        weekKey: _mingguLalu,
        status: ChallengeStatus.active,
        targetAmount: 100000,
      );
      await tambahTx(tanggal: DateTime(2026, 9, 1, 12), nominal: 200000);
    });

    test('prasyarat · barisnya BENAR-BENAR jadi missed', () async {
      buatBloc().add(const ChallengeStarted());
      await _tunggu(400);
      expect(
        (await local.findWeek(_mingguLalu))!.status,
        ChallengeStatus.missed,
      );
    });

    test('U70 · tabel streak_day_marks TIDAK tersentuh', () async {
      buatBloc().add(const ChallengeStarted());
      await _tunggu(400);
      expect(await db.select(db.streakDayMarks).get(), isEmpty);
    });
  });

  // ── U71 · nol DateTime.now() tersembunyi ──────────────────────────────────

  test('U71 · geser FixedClock ke hari lain → daysLeft snapshot ikut '
      'bergeser', () async {
    final b = buatBloc()..add(const ChallengeStarted());
    await tungguSampai(() => b.state.snapshot != null);

    clock.at = DateTime(2026, 9, 9, 9); // Rabu di minggu yang sama
    await tambahTx(tanggal: DateTime(2026, 9, 9, 10), nominal: 10000);
    await tungguSampai(() => b.state.snapshot?.daysLeft == 5);

    expect(b.state.snapshot!.daysLeft, 5); // 8 - weekday(Rabu=3)
  });

  // ── U97 pengganti · ChallengeBloc dibagi tile & halaman (DI) ──────────────
  //
  // U97 lama memasang DUA listener pada `b.stream` yang SAMA lalu mengasersi
  // `identical(tile.last, halaman.last)` — benar untuk implementasi APA PUN,
  // karena kedua daftar menerima objek state dari satu broadcast yang sama.
  // Yang sebenarnya dituntut U97 — bahwa tile dashboard dan halaman
  // `/challenge` berbagi INSTANS `ChallengeBloc` — tak terkunci sama sekali
  // di situ, dan itu hidup di PENDAFTARAN DI (`registerLazySingleton`), bukan
  // di perilaku bloc.
  //
  // Membangun `sl` sungguhan lewat `injection_container.dart` butuh Firebase
  // penuh (tak ada presedennya di suite ini — test lain yang memakai `sl`,
  // mis. `redirect_bootstrap_gate_test.dart`, selalu MENIMPA registrasi
  // produksi dengan mock, bukan menjalankan `init()` sungguhan), jadi test
  // ini mengunci registrasinya langsung di SUMBER `injection_container.dart`.
  test('DI · injection_container.dart mendaftarkan ChallengeBloc sebagai '
      'registerLazySingleton, BUKAN registerFactory', () {
    final sumber = File(
      'lib/core/di/injection_container.dart',
    ).readAsStringSync();
    final idx = sumber.indexOf('() => ChallengeBloc(');
    expect(
      idx,
      greaterThan(-1),
      reason: 'registrasi ChallengeBloc tidak ditemukan di sumber',
    );

    final sebelum = sumber.substring((idx - 80).clamp(0, sumber.length), idx);
    expect(sebelum, contains('registerLazySingleton'));
    expect(sebelum, isNot(contains('registerFactory')));
  });

  // ── M3 · resume WAJIB punya handler ───────────────────────────────────────

  test(
    'M3 · resume SESUDAH minggu berganti → ensure tepat sekali lagi',
    () async {
      // Tanpa handler ini, pergantian minggu di background tidak mengubah satu
      // tabel pun — stream tak meng-emit, dan minggu lalu tak pernah ditutup
      // sampai user kebetulan mencatat transaksi.
      final b = buatBloc()..add(const ChallengeStarted());
      await _tunggu();
      final n1 = ensureCalls;

      clock.at = DateTime(2026, 9, 14, 9);
      b.add(const ChallengeAppResumed());
      await _tunggu();

      expect(ensureCalls, n1 + 1);
    },
  );

  test(
    'M3b · resume di minggu yang SAMA → nol panggilan ensure tambahan',
    () async {
      final b = buatBloc()..add(const ChallengeStarted());
      await _tunggu();
      final n1 = ensureCalls;

      b.add(const ChallengeAppResumed());
      await _tunggu();

      expect(ensureCalls, n1);
    },
  );

  test(
    'M3c · prasyarat M3b · ensure memang sudah pernah jalan sekali',
    () async {
      // Penjaga anti-hampa: kalau `n1` di M3b ternyata nol, "nol tambahan"
      // tidak membuktikan apa pun.
      buatBloc().add(const ChallengeStarted());
      await tungguSampai(() => ensureCalls == 1);
      expect(ensureCalls, 1);
    },
  );

  // ── M4 · restartable() ────────────────────────────────────────────────────

  test(
    'M4 · ChallengeStarted 3× berturut → hanya SATU langganan hidup',
    () async {
      final b = buatBloc();
      b.add(const ChallengeStarted());
      b.add(const ChallengeStarted());
      b.add(const ChallengeStarted());
      await tungguSampai(() => repo.langgananAktif == 1);

      expect(repo.langgananAktif, 1);
    },
  );

  test('M4b · ChallengeStarted 3× lalu SATU transaksi → ChallengeInputsUpdated '
      'datang SEKALI', () async {
    final b = buatBloc();
    b.add(const ChallengeStarted());
    b.add(const ChallengeStarted());
    b.add(const ChallengeStarted());
    await _tunggu(400);

    final sebelum = b.tercatat.whereType<ChallengeInputsUpdated>().length;
    await tambahTx(tanggal: DateTime(2026, 9, 8, 10), nominal: 10000);
    await _tunggu(400);

    expect(b.tercatat.whereType<ChallengeInputsUpdated>().length - sebelum, 1);
  });

  // ── S-B · penjaga basi lastOutcome ────────────────────────────────────────

  test('S-B · outcome minggu LALU tidak dipakai minggu ini → skeleton, bukan '
      'kandidat basi', () async {
    when(() => ensureMock(any())).thenAnswer((_) async {
      ensureCalls++;
      if (ensureCalls == 1) {
        return const Right(
          EnsureOutcome(weekKey: _mingguIni, candidateCount: 3, env: _envSehat),
        );
      }
      // Ensure minggu baru belum sempat selesai saat asersi dijalankan.
      await Future<void>.delayed(const Duration(milliseconds: 1500));
      return const Right(
        EnsureOutcome(weekKey: _mingguDepan, candidateCount: 3, env: _envSehat),
      );
    });

    final b = buatBloc()..add(const ChallengeStarted());
    await _tunggu();

    clock.at = DateTime(2026, 9, 14, 9); // Senin berikutnya
    await tambahTx(tanggal: DateTime(2026, 9, 14, 10), nominal: 10000);
    await _tunggu(200);

    expect(b.state.snapshot!.phase, isA<PhaseUndetermined>());
  });

  test('S-B prasyarat · outcome minggu INI memang dipakai (bukan selalu '
      'skeleton)', () async {
    // Penjaga anti-hampa untuk test di atas: kalau `lastOutcome` tak pernah
    // terpakai sama sekali, PhaseUndetermined muncul karena sebab lain.
    when(() => ensureMock(any())).thenAnswer((_) async {
      ensureCalls++;
      return const Right(
        EnsureOutcome(weekKey: _mingguIni, candidateCount: 3, env: _envSehat),
      );
    });

    final b = buatBloc()..add(const ChallengeStarted());
    await tungguSampai(() => b.state.snapshot?.phase is PhasePreparing);

    expect(b.state.snapshot!.phase, isA<PhasePreparing>());
  });

  test('S-B · sakelar dinyalakan dari Pengaturan → penjaga dilepas, ensure '
      'dipanggil lagi, DAN phase keluar dari PhaseUndetermined', () async {
    // IMPORTANT-2 — versi lama asersinya `isNot(isA<PhaseDisabled>())`: itu
    // tak membedakan "berpindah ke phase konkret" dari "berpindah lalu
    // menggantung SELAMANYA di PhaseUndetermined". Panggilan PERTAMA (selagi
    // sakelar masih mati) sengaja mengembalikan `candidateCount: null`
    // (skeleton) — meniru ensure yang belum sempat menghitung apa pun
    // berguna saat itu. Kalau penjaga tak pernah dilepas, TAK ADA panggilan
    // kedua yang bisa memperbaikinya, dan phase menggantung di
    // PhaseUndetermined selamanya (BUKAN kembali ke PhaseDisabled — enabled
    // sudah true di stream, cuma outcome-nya yang basi).
    when(() => ensureMock(any())).thenAnswer((_) async {
      ensureCalls++;
      if (ensureCalls == 1) {
        return const Right(
          EnsureOutcome(weekKey: _mingguIni, candidateCount: null, env: null),
        );
      }
      return const Right(
        EnsureOutcome(weekKey: _mingguIni, candidateCount: 3, env: _envSehat),
      );
    });

    await sakelar.setEnabled(false);
    final b = buatBloc()..add(const ChallengeStarted());
    await tungguSampai(() => b.state.snapshot != null);
    expect(b.state.snapshot!.phase, isA<PhaseDisabled>()); // prasyarat
    final n1 = ensureCalls;
    expect(n1, 1); // anti-hampa: ensure memang sudah jalan sekali

    // K-2 (ronde 2) — dispatch di SINI urutannya kita yang kendalikan
    // langsung (bukan lewat `_onEnabledToggled`, yang melepas penjaga
    // SESUDAH `await _setEnabled(...)` — TIDAK ada jaminan formal itu
    // selalu mendahului emit `watchEnabled()` berikutnya, meski aman dalam
    // praktik: kelanjutan `await` adalah microtask, sedangkan emit stream
    // menunggu Timer koalesensi 16 ms yang selalu jatuh SESUDAH microtask
    // manapun yang sudah tertunda). Test ini sengaja menunggu penjaga
    // benar-benar `null` DULU sebelum menulis ke datasource, supaya tak
    // bergantung pada jendela race itu sama sekali.
    b.add(const ChallengeEnabledToggled(true)); // lepas penjaga (IMPORTANT-2)
    await tungguSampai(() => b.state.lastEnsuredWeekKey == null);
    await sakelar.setEnabled(true); // baru sekarang stream `enabled` jadi true

    await tungguSampai(
      () =>
          b.state.snapshot?.phase is! PhaseDisabled &&
          b.state.snapshot?.phase is! PhaseUndetermined,
      batas: const Duration(seconds: 3),
    );

    expect(ensureCalls, greaterThan(n1));
    expect(b.state.snapshot!.phase, isNot(isA<PhaseDisabled>()));
    expect(b.state.snapshot!.phase, isNot(isA<PhaseUndetermined>()));
  });

  test('IMPORTANT-2 · ensure gagal (Left) → penjaga dilepas, retry '
      'berikutnya mencoba lagi (bukan terkunci sampai minggu depan)', () async {
    // Skenario "kegagalan transien" dari review: sebelum perbaikan, penjaga
    // sudah terpasang SEBELUM `await _ensure(...)`, jadi `Left` (mis. gagal
    // menulis DB sesaat) mengunci minggu ini sampai minggu depan — nol
    // percobaan ulang. Sesudah perbaikan, `Left` melepas penjaga lagi.
    when(() => ensureMock(any())).thenAnswer((_) async {
      ensureCalls++;
      return const Left(ServerFailure('gagal transien'));
    });

    final b = buatBloc()..add(const ChallengeStarted());
    await tungguSampai(() => b.state.failure != null);
    expect(b.state.lastEnsuredWeekKey, isNull); // penjaga dilepas

    // K-3 (ronde 2) — poll pada `tercatat` (tick DIPROSES), BUKAN pada
    // `ensureCalls == 2` langsung: kalau poll-nya sama persis dengan assert
    // akhir, assert itu hampa (selalu benar begitu poll lolos). Dengan ini,
    // "tick sudah diproses" dan "ensure benar-benar terpanggil lagi" adalah
    // dua hal yang diperiksa terpisah.
    final sebelum = b.tercatat.whereType<ChallengeInputsUpdated>().length;
    await tambahTx(tanggal: DateTime(2026, 9, 8, 10), nominal: 10000);
    await tungguSampai(
      () => b.tercatat.whereType<ChallengeInputsUpdated>().length > sebelum,
    );

    expect(ensureCalls, 2); // retry benar-benar terjadi, bukan terkunci
  });

  test('S-B · perakitan ulang SESUDAH ensure selesai → skeleton Senin pertama '
      'tidak menggantung', () async {
    // Tak ada tulisan tabel apa pun di jalur ini (ensure dipalsukan), jadi
    // satu-satunya yang bisa menyelesaikan skeleton adalah perakitan ulang di
    // dalam `_pastikanMingguIni`.
    when(() => ensureMock(any())).thenAnswer((_) async {
      ensureCalls++;
      await Future<void>.delayed(const Duration(milliseconds: 120));
      return const Right(
        EnsureOutcome(weekKey: _mingguIni, candidateCount: 3, env: _envSehat),
      );
    });

    final b = buatBloc()..add(const ChallengeStarted());
    await _tunggu(500);

    expect(b.state.snapshot!.phase, isA<PhasePreparing>());
  });

  // ── CRITICAL-1 · resetForNewSession membuang state akun lama ──────────────

  group('CRITICAL-1 · resetForNewSession', () {
    test(
      'state PENUH (snapshot + lastOutcome + lastEnsuredWeekKey + failure + '
      'status ready) → resetForNewSession() → SEMUA field kembali ke default',
      () async {
        // K-3 (ronde 2) — versi ronde 1 hanya membangun snapshot/lastOutcome/
        // lastEnsuredWeekKey, jadi mutasi tunggal (nonaktifkan SELURUH
        // `_onSessionReset`) hanya membuktikan asersi PERTAMA (`snapshot`)
        // benar-benar terkunci — `failure`/`status` tak pernah diisi, jadi tak
        // pernah teruji sama sekali, dan mutasi per-field tak bisa dibedakan
        // dari mutasi total. Di sini state dibangun SELENGKAPNYA: `failure`
        // lewat aksi yang sengaja digagalkan.
        when(() => ensureMock(any())).thenAnswer((_) async {
          ensureCalls++;
          return const Right(
            EnsureOutcome(
              weekKey: _mingguIni,
              candidateCount: 3,
              env: _envSehat,
            ),
          );
        });
        when(
          () => skipWeek(any()),
        ).thenAnswer((_) async => Left(ValidationFailure('isi state penuh')));

        final b = buatBloc()..add(const ChallengeStarted());
        await tungguSampai(
          () =>
              b.state.snapshot != null &&
              b.state.lastOutcome != null &&
              b.state.lastEnsuredWeekKey != null,
        );
        b.add(const ChallengeWeekSkipped()); // isi `failure`
        await tungguSampai(() => b.state.failure != null);
        expect(b.state.status, ChallengeViewStatus.ready); // prasyarat

        b.resetForNewSession();
        await tungguSampai(() => b.state.snapshot == null);

        expect(b.state.snapshot, isNull);
        expect(b.state.lastOutcome, isNull);
        expect(b.state.lastEnsuredWeekKey, isNull);
        expect(b.state.failure, isNull);
        expect(b.state.status, ChallengeViewStatus.initial);
      },
    );

    test('akun B "resume" di minggu YANG SAMA sesudah reset → ensure dipanggil '
        'lagi (bukan dipulangkan penjaga akun lama)', () async {
      // Skenario CRITICAL-1 persis: akun A login Senin (ensure sekali,
      // lastEnsuredWeekKey terpasang) → logout → akun B login di minggu
      // yang SAMA. Tanpa reset, `_pastikanMingguIni` memulangkan diri di
      // baris pertama untuk akun B — `ensure` TAK PERNAH dipanggil untuk
      // akun baru.
      final b = buatBloc()..add(const ChallengeStarted());
      await tungguSampai(() => ensureCalls == 1); // akun A: ensure sekali
      final n1 = ensureCalls;

      b.resetForNewSession(); // logout
      await tungguSampai(() => b.state.lastEnsuredWeekKey == null);

      b.add(const ChallengeAppResumed()); // akun B login & resume
      await tungguSampai(() => ensureCalls == n1 + 1);

      expect(ensureCalls, n1 + 1);
    });

    test('_inputsTerakhir dibuang saat reset → resume TANPA stream aktif tidak '
        'merakit snapshot dari bahan akun lama', () async {
      // K-3 (ronde 2) — field privat, tak terbaca langsung dari test. Bukti
      // TAK LANGSUNG: sesudah reset, dispatch HANYA `ChallengeAppResumed`
      // (tanpa `ChallengeStarted` baru → tanpa stream aktif). Satu-satunya
      // bahan yang bisa dipakai `_pastikanMingguIni` untuk merakit ulang
      // snapshot adalah `_inputsTerakhir` — kalau field itu TAK dibuang,
      // snapshot akun LAMA bisa lahir kembali begitu ensure selesai.
      when(() => ensureMock(any())).thenAnswer((_) async {
        ensureCalls++;
        return const Right(
          EnsureOutcome(weekKey: _mingguIni, candidateCount: 3, env: _envSehat),
        );
      });

      final b = buatBloc()..add(const ChallengeStarted());
      await tungguSampai(() => b.state.snapshot != null);

      b.resetForNewSession();
      await tungguSampai(() => b.state.snapshot == null);

      b.add(const ChallengeAppResumed());
      await tungguSampai(() => b.state.lastOutcome != null); // ensure selesai

      expect(b.state.snapshot, isNull);
    });
  });

  // ── K-1 (ronde 2) · asal failure (stream vs aksi) ──────────────────────────

  group('K-1 · pembeda asal failure', () {
    test('stream gagal SAAT snapshot sudah ada → failure terisi, status TETAP '
        'ready, DAN failure bersih begitu stream pulih', () async {
      // Dispatch event langsung (tanpa ChallengeStarted/stream sungguhan) —
      // menguji transisi state handler, bukan jalur galat stream nyata.
      final b = buatBloc();
      const inputsAwal = ChallengeInputs(
        weekThisWeek: null,
        spentThisWeek: 0,
        excludedThisWeek: 0,
        history: [],
        enabled: true,
      );
      b.add(const ChallengeInputsUpdated(inputsAwal));
      await tungguSampai(() => b.state.snapshot != null);
      expect(b.state.status, ChallengeViewStatus.ready); // prasyarat

      b.add(const ChallengeInputsFailed(CacheFailure('gagal baca')));
      await tungguSampai(() => b.state.failure != null);
      expect(b.state.status, ChallengeViewStatus.ready); // TETAP ready

      b.add(const ChallengeInputsUpdated(inputsAwal)); // stream "pulih"
      await tungguSampai(() => b.state.failure == null);

      expect(b.state.failure, isNull);
    });

    test('failure dari AKSI user bertahan lewat tick stream TAK berhubungan '
        '(baru bersih saat aksi berikutnya sukses)', () async {
      when(() => skipWeek(any())).thenAnswer(
        (_) async => Left(ValidationFailure('Minggu ini sudah berjalan.')),
      );

      final b = buatBloc()..add(const ChallengeStarted());
      await tungguSampai(() => b.state.snapshot != null);

      b.add(const ChallengeWeekSkipped());
      await tungguSampai(() => b.state.failure != null);
      expect(b.state.failure, isA<ValidationFailure>()); // prasyarat

      // Tick stream TAK BERHUBUNGAN — transaksi baru, tak menyentuh skipWeek.
      final sebelum = b.tercatat.whereType<ChallengeInputsUpdated>().length;
      await tambahTx(tanggal: DateTime(2026, 9, 8, 10), nominal: 10000);
      await tungguSampai(
        () => b.tercatat.whereType<ChallengeInputsUpdated>().length > sebelum,
      );

      expect(b.state.failure, isA<ValidationFailure>()); // TETAP ada
    });
  });

  // ── Aksi user ─────────────────────────────────────────────────────────────

  test(
    'ChallengeCategoryChanged meneruskan minggu berjalan ke usecase',
    () async {
      final b = buatBloc()..add(const ChallengeStarted());
      await _tunggu();
      b.add(const ChallengeCategoryChanged('transport'));
      await _tunggu();

      verify(
        () => changeCategory(
          const ChangeCategoryParams(
            weekKey: _mingguIni,
            category: 'transport',
          ),
        ),
      ).called(1);
    },
  );

  test('ChallengeWeekSkipped meneruskan minggu berjalan ke usecase', () async {
    final b = buatBloc()..add(const ChallengeStarted());
    await _tunggu();
    b.add(const ChallengeWeekSkipped());
    await _tunggu();

    verify(() => skipWeek(const SkipWeekParams(weekKey: _mingguIni))).called(1);
  });

  test('ChallengeResultDismissed meneruskan weekKey kartu hasil', () async {
    final b = buatBloc()..add(const ChallengeStarted());
    await _tunggu();
    b.add(const ChallengeResultDismissed(20260824));
    await _tunggu();

    verify(
      () => markSeen(const MarkResultSeenParams(weekKey: 20260824)),
    ).called(1);
  });

  test('ChallengeEnabledToggled meneruskan nilai sakelar ke usecase', () async {
    final b = buatBloc()..add(const ChallengeStarted());
    await _tunggu();
    b.add(const ChallengeEnabledToggled(false));
    await _tunggu();

    verify(
      () => setEnabled(const SetChallengeEnabledParams(enabled: false)),
    ).called(1);
  });

  test('aksi gagal → status failure dengan pesan usecase', () async {
    when(() => skipWeek(any())).thenAnswer(
      (_) async => Left(ValidationFailure('Minggu ini sudah berjalan.')),
    );

    final b = buatBloc()..add(const ChallengeStarted());
    await _tunggu();
    b.add(const ChallengeWeekSkipped());
    await _tunggu();

    expect(b.state.failure, isA<ValidationFailure>());
  });
}
