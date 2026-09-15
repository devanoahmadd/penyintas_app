import 'dart:async';

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

  test(
    'U115b · stream memilih hasil belum dilihat dengan weekKey TERBESAR',
    () async {
      // Penjaga anti-hampa untuk U115: membuktikan jalur `pendingResult` memang
      // dilalui, jadi "nol tulisan" di atas bukan kebetulan karena stream diam.
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
    },
  );

  // ── U68 · penjaga satu-minggu-satu-ensure ─────────────────────────────────

  test('U68 · stream diawasi lama TANPA pergantian minggu → ensure TIDAK '
      'dipanggil lagi sesudah yang pertama', () async {
    pakaiEnsureAsli();
    await beriBasis('food', 200000);
    await tulisBaris(weekKey: _mingguLalu, status: ChallengeStatus.active);

    buatBloc().add(const ChallengeStarted());
    await _tunggu(400);

    // Tiga perubahan tabel transaksi — tiap satunya memicu emit stream.
    for (var i = 0; i < 3; i++) {
      await tambahTx(tanggal: DateTime(2026, 9, 8, 10), nominal: 10000);
      await _tunggu(120);
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
    // memerahkan satu test pun. Jendelanya cuma terbuka selama ensure masih
    // berjalan — dan ensure nyata memang lambat (ia membaca dashboard dengan
    // anggaran tiga detik), jadi jendela itu bukan hipotesis.
    when(() => ensureMock(any())).thenAnswer((_) async {
      ensureCalls++;
      await Future<void>.delayed(const Duration(milliseconds: 400));
      return Right(
        EnsureOutcome(
          weekKey: weekKeyOf(clock.now()),
          candidateCount: null,
          env: null,
        ),
      );
    });

    buatBloc().add(const ChallengeStarted());
    await _tunggu(150); // ensure sudah berjalan, belum selesai
    await tambahTx(tanggal: DateTime(2026, 9, 8, 10), nominal: 10000);
    await _tunggu(600); // lewat titik selesai ensure

    expect(ensureCalls, 1);
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
    buatBloc().add(const ChallengeStarted());
    await _tunggu();

    clock.at = DateTime(2026, 9, 9, 9); // Rabu di minggu yang sama
    await tambahTx(tanggal: DateTime(2026, 9, 9, 10), nominal: 10000);
    await _tunggu();

    expect(bloc!.state.snapshot!.daysLeft, 5); // 8 - weekday(Rabu=3)
  });

  // ── U97 · satu phase untuk tile dan halaman ───────────────────────────────

  test(
    'U97 · tile dan halaman membaca phase yang IDENTIK dari satu bloc',
    () async {
      final b = buatBloc();
      final tile = <ChallengePhase>[];
      final halaman = <ChallengePhase>[];
      final s1 = b.stream.listen((s) {
        if (s.snapshot != null) tile.add(s.snapshot!.phase);
      });
      final s2 = b.stream.listen((s) {
        if (s.snapshot != null) halaman.add(s.snapshot!.phase);
      });

      b.add(const ChallengeStarted());
      await _tunggu();
      await s1.cancel();
      await s2.cancel();

      expect(identical(tile.last, halaman.last), isTrue);
    },
  );

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
      await _tunggu();
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
      await _tunggu(400);

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
    await _tunggu(400);

    expect(b.state.snapshot!.phase, isA<PhasePreparing>());
  });

  test('S-B · sakelar dinyalakan dari Pengaturan, tanpa perubahan tabel lain → '
      'phase berpindah dari disabled', () async {
    await sakelar.setEnabled(false);
    final b = buatBloc()..add(const ChallengeStarted());
    await _tunggu();
    expect(b.state.snapshot!.phase, isA<PhaseDisabled>()); // prasyarat

    await sakelar.setEnabled(true);
    await _tunggu();

    expect(b.state.snapshot!.phase, isNot(isA<PhaseDisabled>()));
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
