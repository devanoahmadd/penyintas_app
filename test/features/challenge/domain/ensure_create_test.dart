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
import 'package:penyintas_app/features/challenge/domain/entities/challenge_candidate.dart';
import 'package:penyintas_app/features/challenge/domain/entities/challenge_environment.dart';
import 'package:penyintas_app/features/challenge/domain/entities/challenge_status.dart';
import 'package:penyintas_app/features/challenge/domain/entities/ensure_outcome.dart';
import 'package:penyintas_app/features/challenge/domain/ports/challenge_environment_port.dart';
import 'package:penyintas_app/features/challenge/domain/repositories/challenge_repository.dart';
import 'package:penyintas_app/features/challenge/domain/usecases/ensure_and_resolve_challenge.dart';
import 'package:penyintas_app/features/transaction/domain/entities/category_entity.dart';
import 'package:penyintas_app/features/transaction/domain/usecases/get_limitable_categories_usecase.dart';

class _MockAuth extends Mock implements FirebaseAuth {}

class _MockNetwork extends Mock implements NetworkInfo {}

class _MockRemote extends Mock implements ChallengeRemoteDatasource {}

class _MockGetLimitable extends Mock implements GetLimitableCategoriesUseCase {}

class _MockEnvPort extends Mock implements ChallengeEnvironmentPort {}

// Senin 2026-09-07 .. Minggu 2026-09-13 — "minggu ini" di seluruh berkas ini.
const _mingguIni = 20260907;

// Empat minggu basis (T2) yang mendahuluinya. Semuanya Senin.
const _minggu4Lalu = 20260810;
const _minggu3Lalu = 20260817;
const _minggu2Lalu = 20260824;
const _minggu1Lalu = 20260831;

const _envSehat = ChallengeEnvironment(
  budgetConfigured: true,
  survivalActive: false,
);
const _envSurvival = ChallengeEnvironment(
  budgetConfigured: true,
  survivalActive: true,
);
const _envTanpaAnggaran = ChallengeEnvironment(
  budgetConfigured: false,
  survivalActive: false,
);

/// Tiga kategori yang boleh diberi batas anggaran. Persis tiga, supaya
/// `candidateCount` yang dilaporkan S-B punya angka yang bisa dipastikan.
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

void main() {
  setUpAll(() => registerFallbackValue(const NoParams()));

  late AppDatabase db;
  late ChallengeLocalDatasource local;
  late ChallengeSettingsDatasource sakelar;
  late ChallengeRepository repo;
  late _MockGetLimitable getLimitable;
  late _MockEnvPort env;
  late FixedClock clock;
  late EnsureAndResolveChallenge usecase;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    local = ChallengeLocalDatasourceImpl(db);
    sakelar = ChallengeSettingsDatasourceImpl(db);

    final auth = _MockAuth();
    final network = _MockNetwork();
    // Tanpa uid: `_kirim` berhenti sebelum menyentuh jaringan/antrian, jadi
    // berkas ini bisa fokus penuh ke efek LOKAL pembuatan baris. Efek antrian
    // sudah punya berkasnya sendiri (`challenge_sync_queue_test.dart`).
    when(() => auth.currentUser).thenReturn(null);
    when(() => network.isConnected).thenAnswer((_) async => false);

    clock = FixedClock(DateTime(2026, 9, 7, 9)); // Senin, di jendela

    getLimitable = _MockGetLimitable();
    when(
      () => getLimitable(any()),
    ).thenAnswer((_) async => const Right(_kategoriDefault));

    repo = ChallengeRepositoryImpl(
      local: local,
      remote: _MockRemote(),
      network: network,
      auth: auth,
      clock: clock,
      getLimitable: getLimitable,
      settings: sakelar,
    );

    env = _MockEnvPort();
    when(() => env.read()).thenAnswer((_) async => const Right(_envSehat));

    usecase = EnsureAndResolveChallenge(
      repo: repo,
      local: local,
      getLimitable: getLimitable,
      env: env,
      settings: sakelar,
      clock: clock,
    );

    // Sakelar fitur menyala — fallback datasource adalah MATI (D3), jadi tanpa
    // baris ini seluruh berkas lolos di langkah 3 tanpa pernah menguji apa pun.
    await sakelar.setEnabled(true);
  });

  tearDown(() async => db.close());

  // ── Perkakas ──────────────────────────────────────────────────────────────

  Future<void> tambahTx({
    required int bulan,
    required int hari,
    required int nominal,
    required String kategori,
  }) => db
      .into(db.transactions)
      .insert(
        TransactionsCompanion.insert(
          txId: 'tx-$bulan-$hari-$kategori-$nominal',
          amount: nominal,
          category: kategori,
          type: 'expense',
          date: DateTime(2026, bulan, hari, 12),
          createdAt: DateTime(2026, bulan, hari, 12),
          updatedAt: DateTime(2026, bulan, hari, 12),
        ),
      );

  /// Satu kategori dengan belanja di DUA minggu basis — cukup untuk lolos
  /// `kMinBaselineWeeksWithData`. Basisnya = [perMinggu].
  Future<void> beriBasis(String kategori, int perMinggu) async {
    await tambahTx(
      bulan: 8,
      hari: 18,
      nominal: perMinggu,
      kategori: kategori,
    ); // minggu 20260817
    await tambahTx(
      bulan: 8,
      hari: 25,
      nominal: perMinggu,
      kategori: kategori,
    ); // minggu 20260824
  }

  /// Tiga kandidat layak, basis menurun: food 200rb > transport 150rb >
  /// hiburan 100rb. Teratas = `food`.
  Future<void> siapkanTigaKandidat() async {
    await beriBasis('food', 200000);
    await beriBasis('transport', 150000);
    await beriBasis('hiburan', 100000);
  }

  Future<void> tulisBaris({
    required int weekKey,
    required ChallengeStatus status,
    String? kategori = 'food',
    int? targetAmount = 170000,
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
          timezone: 'WIB',
          createdAt: DateTime.utc(2026, 8, 1),
          updatedAt: DateTime.utc(2026, 8, 1),
          resultSeenAt: Value(resultSeenAt),
        ),
      );

  Future<EnsureOutcome> jalankan() async {
    final hasil = await usecase(const NoParams());
    return hasil.fold(
      (f) => fail('seharusnya Right, dapat Left($f)'),
      (o) => o,
    );
  }

  // ── Langkah 2 · idempoten ─────────────────────────────────────────────────

  group('langkah 2 · idempoten', () {
    test(
      'U52 · dua kali ensure di hari yang sama → TEPAT SATU baris',
      () async {
        await siapkanTigaKandidat();

        await usecase(const NoParams());
        await usecase(const NoParams());

        final semua = await db.select(db.weeklyChallenges).get();
        expect(semua, hasLength(1));
        expect(semua.single.status, ChallengeStatus.active);
      },
    );

    test(
      'U52 · ensure kedua (Selasa) TIDAK menulis ulang baris yang sudah ada',
      () async {
        // Asersi yang benar-benar mengunci langkah 2. "Tepat satu baris" saja
        // TIDAK mengunci: weekKey adalah PRIMARY KEY dan `_buatDanKirim`
        // memakai upsert, jadi penulisan kedua pun hanya menimpa baris yang
        // sama dan jumlahnya tetap satu. `updatedAt` yang bergeser adalah
        // jejak yang tersisa dari penulisan ulang itu.
        await siapkanTigaKandidat();
        await usecase(const NoParams());
        final sebelum = (await local.findWeek(_mingguIni))!.updatedAt;

        clock.at = DateTime(2026, 9, 8, 9); // Selasa — masih di jendela
        await usecase(const NoParams());

        expect((await local.findWeek(_mingguIni))!.updatedAt, sebelum);
      },
    );

    test('U74 · baris skipped minggu ini → status TETAP skipped', () async {
      await siapkanTigaKandidat();
      await tulisBaris(weekKey: _mingguIni, status: ChallengeStatus.skipped);
      await sakelar.setEnabled(true); // dinyalakan lagi sesudah dilewati

      await usecase(const NoParams());

      expect(
        (await local.findWeek(_mingguIni))!.status,
        ChallengeStatus.skipped,
      );
    });

    test('U74 · baris skipped minggu ini → TIDAK ada baris baru', () async {
      await siapkanTigaKandidat();
      await tulisBaris(weekKey: _mingguIni, status: ChallengeStatus.skipped);
      await sakelar.setEnabled(true);

      await usecase(const NoParams());

      expect(await db.select(db.weeklyChallenges).get(), hasLength(1));
    });

    test(
      'U56 · baris active + env survival di hari Kamis → tetap active',
      () async {
        await tulisBaris(weekKey: _mingguIni, status: ChallengeStatus.active);
        when(
          () => env.read(),
        ).thenAnswer((_) async => const Right(_envSurvival));
        clock.at = DateTime(2026, 9, 10, 9); // Kamis

        await usecase(const NoParams());

        expect(
          (await local.findWeek(_mingguIni))!.status,
          ChallengeStatus.active,
        );
      },
    );

    test(
      'U56 · baris sudah ada → port lingkungan TIDAK dibaca sama sekali (Kamis)',
      () async {
        await tulisBaris(weekKey: _mingguIni, status: ChallengeStatus.active);
        clock.at = DateTime(2026, 9, 10, 9); // Kamis

        await usecase(const NoParams());

        verifyNever(() => env.read());
      },
    );

    test(
      'U56 · baris sudah ada DI DALAM jendela (Selasa) → port lingkungan tetap '
      'TIDAK dibaca',
      () async {
        // Varian yang lebih galak dari yang di atas: hari Kamis, langkah 4
        // sudah menghentikan alur lebih dulu, jadi `verifyNever` di sana masih
        // hijau kalau bacaan env dipindah ke antara langkah 2 dan 4. Hari
        // Selasa tak punya perlindungan itu — satu-satunya yang menahan
        // bacaan env adalah langkah 2 itu sendiri.
        await siapkanTigaKandidat();
        await tulisBaris(weekKey: _mingguIni, status: ChallengeStatus.active);
        clock.at = DateTime(2026, 9, 8, 9); // Selasa

        await usecase(const NoParams());

        verifyNever(() => env.read());
      },
    );
  });

  // ── Langkah 3–4 · gerbang murah ───────────────────────────────────────────

  group('langkah 3–4 · gerbang murah', () {
    test('langkah 3 · sakelar mati → tidak ada baris dibuat', () async {
      await siapkanTigaKandidat();
      await sakelar.setEnabled(false);

      await usecase(const NoParams());

      expect(await local.findWeek(_mingguIni), isNull);
    });

    test('langkah 3 · sakelar mati → port lingkungan tidak dibaca', () async {
      await siapkanTigaKandidat();
      await sakelar.setEnabled(false);

      await usecase(const NoParams());

      verifyNever(() => env.read());
    });

    test('U53 · hari Rabu, belum ada baris → TIDAK ada baris dibuat', () async {
      await siapkanTigaKandidat();
      clock.at = DateTime(2026, 9, 9, 9); // Rabu — di luar Senin–Selasa

      await usecase(const NoParams());

      expect(await local.findWeek(_mingguIni), isNull);
    });
  });

  // ── Langkah 6 · satu bacaan lingkungan, tiga keputusan ────────────────────

  group('langkah 6 · lingkungan', () {
    test('U54 · survivalActive → baris berstatus held', () async {
      await siapkanTigaKandidat();
      when(() => env.read()).thenAnswer((_) async => const Right(_envSurvival));

      await usecase(const NoParams());

      expect((await local.findWeek(_mingguIni))!.status, ChallengeStatus.held);
    });

    test(
      'U54 · baris held: category, targetAmount, baselineAmount NULL',
      () async {
        // T11 — minggu ini tak pernah punya tantangan, dan riwayat merender
        // "—". Mengisi ketiganya membuat kartu hasil mengklaim target yang tak
        // pernah user setujui.
        await siapkanTigaKandidat();
        when(
          () => env.read(),
        ).thenAnswer((_) async => const Right(_envSurvival));

        await usecase(const NoParams());

        final row = (await local.findWeek(_mingguIni))!;
        expect(row.category, isNull);
        expect(row.targetAmount, isNull);
        expect(row.baselineAmount, isNull);
      },
    );

    test('U55 · held Senin, env sehat Selasa → TETAP held (final)', () async {
      await siapkanTigaKandidat();
      when(() => env.read()).thenAnswer((_) async => const Right(_envSurvival));
      await usecase(const NoParams());
      expect((await local.findWeek(_mingguIni))!.status, ChallengeStatus.held);

      when(() => env.read()).thenAnswer((_) async => const Right(_envSehat));
      clock.at = DateTime(2026, 9, 8, 9); // Selasa — masih di jendela
      await usecase(const NoParams());

      expect((await local.findWeek(_mingguIni))!.status, ChallengeStatus.held);
    });

    test(
      'U57 · env Left → TIDAK menulis apa pun, khususnya bukan held',
      () async {
        // `held` bersifat FINAL dan tak bisa dibatalkan. Menuliskannya atas
        // keadaan yang tak diketahui adalah aksi tak-terbalik yang dipicu
        // ketidaktahuan.
        await siapkanTigaKandidat();
        when(
          () => env.read(),
        ).thenAnswer((_) async => Left(CacheFailure('tak terbaca')));

        await usecase(const NoParams());

        expect(await local.findWeek(_mingguIni), isNull);
      },
    );

    test('U58 · gagal Senin tidak mengunci minggu — Selasa berhasil', () async {
      await siapkanTigaKandidat();
      when(
        () => env.read(),
      ).thenAnswer((_) async => Left(CacheFailure('tak terbaca')));
      await usecase(const NoParams());

      when(() => env.read()).thenAnswer((_) async => const Right(_envSehat));
      clock.at = DateTime(2026, 9, 8, 9); // Selasa, masih di jendela
      await usecase(const NoParams());

      expect(
        (await local.findWeek(_mingguIni))!.status,
        ChallengeStatus.active,
      );
    });

    test(
      'U59 · budgetConfigured false → tidak ada baris, khususnya bukan held',
      () async {
        // D16 — user tanpa anggaran akan ter-`held` PERMANEN tiap Senin,
        // selamanya, tanpa penjelasan. Gerbang ini yang mencegahnya.
        await siapkanTigaKandidat();
        when(
          () => env.read(),
        ).thenAnswer((_) async => const Right(_envTanpaAnggaran));

        await usecase(const NoParams());

        expect(await local.findWeek(_mingguIni), isNull);
      },
    );

    test('lingkungan dibaca TEPAT SEKALI pada minggu yang berhasil', () async {
      await siapkanTigaKandidat();

      await usecase(const NoParams());

      verify(() => env.read()).called(1);
    });
  });

  // ── T17 · determinisme pilihan ────────────────────────────────────────────

  group('T17 · pilihan deterministik', () {
    test(
      'dua kandidat berbasis SAMA → slug abjad lebih kecil yang dipakai',
      () async {
        await beriBasis('transport', 120000);
        await beriBasis('hiburan', 120000);

        await usecase(const NoParams());

        expect((await local.findWeek(_mingguIni))!.category, 'hiburan');
      },
    );

    test('urutan kandidat STABIL di dua pemanggilan getCandidates', () async {
      await beriBasis('transport', 120000);
      await beriBasis('hiburan', 120000);

      final a = await repo.getCandidates(_mingguIni);
      final b = await repo.getCandidates(_mingguIni);

      String teratas(Either<Failure, List<ChallengeCandidate>> e) =>
          e.getOrElse(() => const []).first.category;
      expect(teratas(a), 'hiburan');
      expect(teratas(b), 'hiburan');
    });
  });

  // ── M5 · jendela riwayat getCandidates = 12 ───────────────────────────────

  group('M5 · rem rotasi lewat getCandidates', () {
    test('tiga kemenangan berturut yang DIDAHULUI tiga minggu held tetap '
        'memicu rotasi', () async {
      // `consecutiveWins` memperlakukan `held` sebagai TRANSPARAN. Dengan
      // jendela riwayat 5 (`kRotationWins + 2`), tiga `held` di depan sudah
      // cukup mendorong kemenangan ketiga keluar jendela — dan rem rotasi T5
      // mati diam-diam tanpa satu pun test kalkulator memerah, karena test
      // kalkulator menyuapi `history` langsung. Jendelanya 12.
      await beriBasis('food', 200000); // basis lebih besar → tanpa rem, food
      await beriBasis('transport', 100000);

      for (final w in [_minggu1Lalu, _minggu2Lalu, _minggu3Lalu]) {
        await tulisBaris(
          weekKey: w,
          status: ChallengeStatus.held,
          kategori: null,
          targetAmount: null,
        );
      }
      for (final w in [_minggu4Lalu, 20260803, 20260727]) {
        await tulisBaris(
          weekKey: w,
          status: ChallengeStatus.achieved,
          kategori: 'food',
          resultSeenAt: DateTime.utc(2026, 9, 1),
        );
      }

      await usecase(const NoParams());

      expect((await local.findWeek(_mingguIni))!.category, 'transport');
    });
  });

  // ── S-B · bentuk EnsureOutcome di tiap jalan keluar ───────────────────────

  group('S-B · jalan keluar langkah jendela (Rabu)', () {
    test('candidateCount TETAP null — belum sempat dihitung', () async {
      await siapkanTigaKandidat();
      clock.at = DateTime(2026, 9, 9, 9); // Rabu

      expect((await jalankan()).candidateCount, isNull);
    });

    test('env null', () async {
      await siapkanTigaKandidat();
      clock.at = DateTime(2026, 9, 9, 9);

      expect((await jalankan()).env, isNull);
    });

    test('port lingkungan TIDAK dipanggil sama sekali', () async {
      await siapkanTigaKandidat();
      clock.at = DateTime(2026, 9, 9, 9);

      await usecase(const NoParams());

      verifyNever(() => env.read());
    });
  });

  group('S-B · jalan keluar langkah kandidat (kandidat kosong)', () {
    test('candidateCount 0 — DIHITUNG, memang tak ada yang layak', () async {
      // `null` ≠ `0`. Memampatkannya membuat kegagalan baca database tampil ke
      // user sebagai "belum cukup data" — tuduhan yang salah alamat.
      expect((await jalankan()).candidateCount, 0);
    });

    test('env null', () async {
      expect((await jalankan()).env, isNull);
    });

    test('port lingkungan TIDAK dipanggil sama sekali', () async {
      await usecase(const NoParams());

      verifyNever(() => env.read());
    });
  });

  group('S-B · jalan keluar kandidat tak terbaca (getCandidates Left)', () {
    setUp(() {
      when(
        () => getLimitable(any()),
      ).thenAnswer((_) async => Left(CacheFailure('kategori tak terbaca')));
    });

    test('candidateCount TETAP null — bukan 0', () async {
      // "Gagal dibaca" dan "memang tak ada yang layak" adalah dua jawaban
      // berbeda, dan user berhak tidak dituduh kurang data ketika yang gagal
      // sebetulnya database.
      await siapkanTigaKandidat();

      expect((await jalankan()).candidateCount, isNull);
    });

    test('port lingkungan TIDAK dipanggil sama sekali', () async {
      await siapkanTigaKandidat();

      await usecase(const NoParams());

      verifyNever(() => env.read());
    });
  });

  group('S-B · jalan keluar lingkungan gagal (port Left)', () {
    test('candidateCount = jumlah NYATA kandidat', () async {
      await siapkanTigaKandidat();
      when(
        () => env.read(),
      ).thenAnswer((_) async => Left(CacheFailure('tak terbaca')));

      expect((await jalankan()).candidateCount, 3);
    });

    test('env null', () async {
      await siapkanTigaKandidat();
      when(
        () => env.read(),
      ).thenAnswer((_) async => Left(CacheFailure('tak terbaca')));

      expect((await jalankan()).env, isNull);
    });
  });

  group('S-B · jalan keluar anggaran belum diatur', () {
    // Jalan keluar ini UNIK di antara sembilan: ia terminal (user tanpa
    // anggaran berakhir di sini SETIAP Senin–Selasa, bukan sesekali) DAN ia
    // tidak menulis baris apa pun — jadi tingkat 2 presedensi (`week != null`)
    // tak pernah menolongnya. Satu-satunya yang membuat layar merender
    // `PhaseBudgetNotSet` alih-alih skeleton adalah BENTUK outcome-nya:
    // `candidateCount` nyata DAN `env` terisi. U59 hanya menjaga "tidak ada
    // baris"; bentuknya harus dikunci terpisah, di sini.
    setUp(() {
      when(
        () => env.read(),
      ).thenAnswer((_) async => const Right(_envTanpaAnggaran));
    });

    test('candidateCount = jumlah NYATA kandidat', () async {
      await siapkanTigaKandidat();

      expect((await jalankan()).candidateCount, 3);
    });

    test('env TERISI — bukan null', () async {
      // `env` yang jatuh ke null di sini membuat `resolveChallengePhase`
      // menjawab `PhaseUndetermined`: skeleton yang tak kunjung selesai,
      // permanen, untuk setiap user yang belum mengatur anggaran.
      await siapkanTigaKandidat();

      expect((await jalankan()).env, _envTanpaAnggaran);
    });
  });

  group('S-B · jalan keluar semua sehat', () {
    test('candidateCount = jumlah NYATA kandidat', () async {
      await siapkanTigaKandidat();

      expect((await jalankan()).candidateCount, 3);
    });

    test('env TERISI', () async {
      await siapkanTigaKandidat();

      expect((await jalankan()).env, _envSehat);
    });

    test('weekKey = minggu berjalan', () async {
      await siapkanTigaKandidat();

      expect((await jalankan()).weekKey, _mingguIni);
    });
  });
}
