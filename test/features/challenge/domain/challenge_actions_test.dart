import 'package:dartz/dartz.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:penyintas_app/core/database/app_database.dart';
import 'package:penyintas_app/core/error/failures.dart';
import 'package:penyintas_app/core/utils/app_clock.dart';
import 'package:penyintas_app/features/challenge/data/datasources/challenge_local_datasource.dart';
import 'package:penyintas_app/features/challenge/data/datasources/challenge_settings_datasource.dart';
import 'package:penyintas_app/features/challenge/domain/challenge_calculator.dart';
import 'package:penyintas_app/features/challenge/domain/entities/challenge_candidate.dart';
import 'package:penyintas_app/features/challenge/domain/entities/challenge_status.dart';
import 'package:penyintas_app/features/challenge/domain/repositories/challenge_repository.dart';
import 'package:penyintas_app/features/challenge/domain/usecases/change_challenge_category.dart';
import 'package:penyintas_app/features/challenge/domain/usecases/mark_challenge_result_seen.dart';
import 'package:penyintas_app/features/challenge/domain/usecases/set_challenge_enabled.dart';
import 'package:penyintas_app/features/challenge/domain/usecases/skip_challenge_week.dart';

class _MockChallengeRepository extends Mock implements ChallengeRepository {}

// Senin 2026-09-07 .. Minggu 2026-09-13 — "minggu ini" di seluruh berkas ini.
// Sama dengan konstanta di ensure_create_test.dart supaya tanggalnya konsisten
// lintas berkas test fitur ini.
const _mingguIni = 20260907;

void main() {
  setUpAll(() => registerFallbackValue(ChallengeStatus.active));

  late AppDatabase db;
  late ChallengeLocalDatasource ds;
  late ChallengeSettingsDatasource settings;
  late _MockChallengeRepository repo;
  late FixedClock clock;

  late ChangeChallengeCategory gantiPos;
  late SkipChallengeWeek lewati;
  late SetChallengeEnabled setEnabled;
  late MarkChallengeResultSeen tandaiHasil;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    ds = ChallengeLocalDatasourceImpl(db);
    settings = ChallengeSettingsDatasourceImpl(db);
    clock = FixedClock(DateTime(2026, 9, 7, 9)); // Senin, di jendela
    repo = _MockChallengeRepository();

    // ── Stub PENERUS bawaan — bukan mock kosong ──────────────────────────────
    // `repo` di sini adalah Mock, tapi tiga method tulisnya diberi jawaban
    // DEFAULT yang benar-benar menulis ke `ds` — persis efek implementasi
    // nyata di `challenge_repository_impl.dart`. Tanpa ini, `ds.findWeek(...)`
    // di tiap test tidak akan pernah mencerminkan apa yang dilakukan usecase,
    // dan assert pada baris jadi assert pada data yang tidak pernah disentuh.
    //
    // Tiap test BOLEH menimpa stub ini (mis. U75) — stub yang didaftarkan
    // belakangan menang.
    when(
      () => repo.changeCategory(
        weekKey: any(named: 'weekKey'),
        category: any(named: 'category'),
        targetAmount: any(named: 'targetAmount'),
        baselineAmount: any(named: 'baselineAmount'),
      ),
    ).thenAnswer((inv) async {
      await ds.updateWeek(
        inv.namedArguments[#weekKey] as int,
        WeeklyChallengesCompanion(
          category: Value(inv.namedArguments[#category] as String),
          targetAmount: Value(inv.namedArguments[#targetAmount] as int),
          baselineAmount: Value(inv.namedArguments[#baselineAmount] as int),
        ),
      );
      return const Right(null);
    });

    when(
      () => repo.resolveWeek(
        weekKey: any(named: 'weekKey'),
        status: any(named: 'status'),
        finalSpent: any(named: 'finalSpent'),
      ),
    ).thenAnswer((inv) async {
      await ds.updateWeek(
        inv.namedArguments[#weekKey] as int,
        WeeklyChallengesCompanion(
          status: Value(inv.namedArguments[#status] as ChallengeStatus),
          finalSpent: Value(inv.namedArguments[#finalSpent] as int),
          resolvedAt: Value(clock.now().toUtc()),
        ),
      );
      return const Right(null);
    });

    when(() => repo.markResultSeen(any())).thenAnswer((inv) async {
      await ds.markResultSeen(
        weekKey: inv.positionalArguments[0] as int,
        at: clock.now().toUtc(),
      );
      return const Right(null);
    });

    // Kandidat default: satu pos ('transport'), dipakai tiap test yang tidak
    // menimpanya sendiri (mis. dua kasus M7 — mereka tak pernah mestinya
    // sampai ke sini, tapi kalau penjaga status hilang, stub ini yang
    // membuat "row-nya benar-benar berubah jadi transport" bisa dibuktikan
    // lewat nilai, bukan lewat exception mock yang tak ketemu stub).
    when(() => repo.getCandidates(any())).thenAnswer(
      (_) async => const Right([
        ChallengeCandidate(category: 'transport', baseline: 96000, target: 80000),
      ]),
    );

    gantiPos = ChangeChallengeCategory(repo: repo, local: ds, clock: clock);
    lewati = SkipChallengeWeek(repo: repo, local: ds, clock: clock);
    setEnabled = SetChallengeEnabled(
      repo: repo,
      local: ds,
      settings: settings,
      clock: clock,
    );
    tandaiHasil = MarkChallengeResultSeen(repo: repo);
  });

  tearDown(() => db.close());

  // ── Perkakas ──────────────────────────────────────────────────────────────

  int _txCounter = 0;

  Future<void> _tulisBaris({
    int weekKey = _mingguIni,
    ChallengeStatus status = ChallengeStatus.active,
    String? kategori = 'food',
    int? target = 100000,
    int? basis = 120000,
    bool isSynced = false,
  }) => db
      .into(db.weeklyChallenges)
      .insert(
        WeeklyChallengesCompanion.insert(
          weekKey: Value(weekKey),
          category: Value(kategori),
          targetAmount: Value(target),
          baselineAmount: Value(basis),
          status: status,
          timezone: 'WIB',
          createdAt: DateTime.utc(2026, 9, 1),
          updatedAt: DateTime.utc(2026, 9, 1),
          isSynced: Value(isSynced),
        ),
      );

  /// Transaksi expense biasa (bukan tetap, bukan hasil tagihan) — masuk hitungan
  /// `spentInWeek`. Tanggal default Senin minggu ini, supaya otomatis terhitung
  /// di [_mingguIni] tanpa perlu diulang tiap panggilan.
  Future<void> _tambahTransaksi({
    required int nominal,
    String kategori = 'food',
    DateTime? tanggal,
  }) {
    final t = tanggal ?? DateTime(2026, 9, 7, 12);
    _txCounter++;
    return db
        .into(db.transactions)
        .insert(
          TransactionsCompanion.insert(
            txId: 'tx-$_txCounter',
            amount: nominal,
            category: kategori,
            type: 'expense',
            date: t,
            createdAt: t,
            updatedAt: t,
          ),
        );
  }

  // ── ChangeChallengeCategory (T7 + T14) ──────────────────────────────────────

  group('ChangeChallengeCategory', () {
    test('U63 · ganti pos MENGHITUNG ULANG target dan basis', () async {
      // Tanpa ini ada pintu belakang menang gratis: pilih pos termurah sambil
      // menyandang target pos termahal.
      clock.at = DateTime(2026, 9, 7, 9);
      await _tulisBaris(kategori: 'food', target: 115000, basis: 140000);
      // Kedua kandidat WAJIB membawa target hasil computeTarget yang sebenarnya:
      // 96000 × 0,85 = 81.600 → floor kelipatan 5.000 = 80.000. Rev 1 menulis
      // 81.000 di sini — angka yang tak bisa dihasilkan rumus mana pun, dan test
      // yang memalsukan aritmetika mengajarkan aritmetika yang salah ke pembaca
      // berikutnya.
      when(() => repo.getCandidates(any())).thenAnswer(
        (_) async => const Right([
          ChallengeCandidate(category: 'food', baseline: 140000, target: 115000),
          ChallengeCandidate(category: 'transport', baseline: 96000, target: 80000),
        ]),
      );

      await gantiPos(
        const ChangeCategoryParams(weekKey: _mingguIni, category: 'transport'),
      );

      final row = await ds.findWeek(_mingguIni);
      expect(row!.category, 'transport');
      expect(row.targetAmount, 80000);
      expect(row.baselineAmount, 96000);
      // Penjaga tambahan: apa pun yang ditulis, ia harus konsisten dengan rumus.
      expect(row.targetAmount, computeTarget(row.baselineAmount!));
    });

    test(
      'U64 · ganti pos ke kategori di luar daftar kandidat → Left, baris tidak berubah',
      () async {
        clock.at = DateTime(2026, 9, 7, 9);
        await _tulisBaris(kategori: 'food', target: 115000, basis: 140000);
        // Kandidat default hanya 'transport' — 'hiburan' sengaja tidak ada.

        final hasil = await gantiPos(
          const ChangeCategoryParams(weekKey: _mingguIni, category: 'hiburan'),
        );

        expect(hasil.isLeft(), isTrue);
        final row = await ds.findWeek(_mingguIni);
        expect(row!.category, 'food');
        expect(row.targetAmount, 115000);
        expect(row.baselineAmount, 140000);
      },
    );

    test('U65 · ganti pos hari Rabu → Left, baris tidak berubah', () async {
      clock.at = DateTime(2026, 9, 9, 9); // Rabu — di luar jendela
      await _tulisBaris(kategori: 'food', target: 115000, basis: 140000);

      final hasil = await gantiPos(
        const ChangeCategoryParams(weekKey: _mingguIni, category: 'transport'),
      );

      expect(hasil.isLeft(), isTrue);
      final row = await ds.findWeek(_mingguIni);
      expect(row!.category, 'food');
      expect(row.targetAmount, 115000);
    });

    test(
      'M7 · ganti pos pada baris held → Right diam, baris tidak berubah',
      () async {
        clock.at = DateTime(2026, 9, 7, 9); // Senin, di jendela
        await _tulisBaris(
          status: ChallengeStatus.held,
          kategori: null,
          target: null,
          basis: null,
        );

        final hasil = await gantiPos(
          const ChangeCategoryParams(weekKey: _mingguIni, category: 'transport'),
        );

        expect(hasil.isRight(), isTrue);
        final row = await ds.findWeek(_mingguIni);
        expect(row!.status, ChallengeStatus.held);
        expect(row.category, isNull);
        expect(row.targetAmount, isNull);
      },
    );

    test(
      'M7 · ganti pos pada baris skipped → Right diam, baris tidak berubah',
      () async {
        clock.at = DateTime(2026, 9, 7, 9); // Senin, di jendela
        await _tulisBaris(
          status: ChallengeStatus.skipped,
          kategori: null,
          target: null,
          basis: null,
        );

        final hasil = await gantiPos(
          const ChangeCategoryParams(weekKey: _mingguIni, category: 'transport'),
        );

        expect(hasil.isRight(), isTrue);
        final row = await ds.findWeek(_mingguIni);
        expect(row!.status, ChallengeStatus.skipped);
        expect(row.category, isNull);
        expect(row.targetAmount, isNull);
      },
    );
  });

  // ── SkipChallengeWeek (T15) ─────────────────────────────────────────────────

  group('SkipChallengeWeek', () {
    test('U66 · lewati hari Rabu → Left, baris tetap active', () async {
      clock.at = DateTime(2026, 9, 9, 9); // Rabu — di luar jendela
      await _tulisBaris(status: ChallengeStatus.active);

      final hasil = await lewati(const SkipWeekParams(weekKey: _mingguIni));

      expect(hasil.isLeft(), isTrue);
      final row = await ds.findWeek(_mingguIni);
      expect(row!.status, ChallengeStatus.active);
    });

    test(
      'U67 · lewati Senin, sudah terpakai 34.000 → skipped, finalSpent terisi',
      () async {
        clock.at = DateTime(2026, 9, 7, 9); // Senin — di jendela
        await _tulisBaris(status: ChallengeStatus.active, kategori: 'food');
        await _tambahTransaksi(nominal: 34000, kategori: 'food');

        final hasil = await lewati(const SkipWeekParams(weekKey: _mingguIni));

        expect(hasil.isRight(), isTrue);
        final row = await ds.findWeek(_mingguIni);
        expect(row!.status, ChallengeStatus.skipped);
        expect(row.finalSpent, 34000);
        expect(row.resolvedAt, isNotNull);
      },
    );
  });

  // ── SetChallengeEnabled (T16) ────────────────────────────────────────────────

  group('SetChallengeEnabled', () {
    test(
      'U72 · matikan sakelar dengan baris minggu ini active → ditutup skipped',
      () async {
        clock.at = DateTime(2026, 9, 7, 9); // Senin
        await _tulisBaris(status: ChallengeStatus.active, kategori: 'food');
        await _tambahTransaksi(nominal: 34000, kategori: 'food');

        final hasil = await setEnabled(
          const SetChallengeEnabledParams(enabled: false),
        );

        expect(hasil.isRight(), isTrue);
        final row = await ds.findWeek(_mingguIni);
        expect(row!.status, ChallengeStatus.skipped);
        expect(row.finalSpent, 34000);
        expect(await settings.isEnabled(), isFalse);
      },
    );

    test(
      'U73 · matikan sakelar hari Jumat tetap boleh (T16 tidak terkunci jendela)',
      () async {
        clock.at = DateTime(2026, 9, 11, 9); // Jumat, minggu yang sama
        await _tulisBaris(status: ChallengeStatus.active, kategori: 'food');

        final hasil = await setEnabled(
          const SetChallengeEnabledParams(enabled: false),
        );

        expect(hasil.isRight(), isTrue);
        final row = await ds.findWeek(_mingguIni);
        expect(row!.status, ChallengeStatus.skipped);
      },
    );

    test(
      'U75 · resolveWeek gagal → sakelar TIDAK ikut berubah',
      () async {
        // Urutan mengikat: tutup baris DULU, baru balik sakelar. Urutan
        // terbalik lolos semua test lain.
        //
        // PERBAIKAN dari berkas warisan: sakelar harus dimulai ON supaya
        // "tetap true" ada artinya. Tanpa baris ini, `settings.isEnabled()`
        // default `false` (kolom `challengeEnabled` & `_fallback` sama-sama
        // `false`) dan assersi di bawah gagal untuk implementasi APA PUN,
        // benar maupun salah — bukan cuma untuk sabotase.
        await settings.setEnabled(true);
        await _tulisBaris(status: ChallengeStatus.active);
        when(
          () => repo.resolveWeek(
            weekKey: any(named: 'weekKey'),
            status: any(named: 'status'),
            finalSpent: any(named: 'finalSpent'),
          ),
        ).thenAnswer((_) async => Left(CacheFailure('gagal')));

        final hasil = await setEnabled(
          const SetChallengeEnabledParams(enabled: false),
        );

        expect(hasil.isLeft(), isTrue);
        expect(await settings.isEnabled(), isTrue);
      },
    );

    test(
      'U74 · nyalakan lagi minggu yang sama dengan baris skipped → tidak ada baris baru',
      () async {
        clock.at = DateTime(2026, 9, 7, 9); // Senin
        await _tulisBaris(
          status: ChallengeStatus.skipped,
          kategori: null,
          target: null,
          basis: null,
        );

        final hasil = await setEnabled(
          const SetChallengeEnabledParams(enabled: true),
        );

        expect(hasil.isRight(), isTrue);
        final semua = await db.select(db.weeklyChallenges).get();
        expect(semua, hasLength(1));
        expect(semua.single.status, ChallengeStatus.skipped);
        expect(await settings.isEnabled(), isTrue);
      },
    );
  });

  // ── MarkChallengeResultSeen (D11) ────────────────────────────────────────────

  group('MarkChallengeResultSeen', () {
    test(
      'U77 · tandai hasil pada baris achieved isSynced=true → isSynced TETAP true',
      () async {
        await _tulisBaris(status: ChallengeStatus.achieved, isSynced: true);

        final hasil = await tandaiHasil(
          const MarkResultSeenParams(weekKey: _mingguIni),
        );

        expect(hasil.isRight(), isTrue);
        final row = await ds.findWeek(_mingguIni);
        expect(row!.resultSeenAt, isNotNull);
        expect(row.isSynced, isTrue);
      },
    );
  });
}
