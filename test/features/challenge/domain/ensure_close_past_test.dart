import 'package:dartz/dartz.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:penyintas_app/core/database/app_database.dart';
import 'package:penyintas_app/core/network/network_info.dart';
import 'package:penyintas_app/core/usecases/usecase.dart';
import 'package:penyintas_app/core/utils/app_clock.dart';
import 'package:penyintas_app/features/challenge/data/datasources/challenge_local_datasource.dart';
import 'package:penyintas_app/features/challenge/data/datasources/challenge_remote_datasource.dart';
import 'package:penyintas_app/features/challenge/data/datasources/challenge_settings_datasource.dart';
import 'package:penyintas_app/features/challenge/data/repositories/challenge_repository_impl.dart';
import 'package:penyintas_app/features/challenge/domain/entities/challenge_status.dart';
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

class _MockChallengeRepository extends Mock implements ChallengeRepository {}

// Senin 2026-09-07 .. Minggu 2026-09-13 — "minggu ini" di seluruh berkas ini.
const _mingguIni = 20260907;

/// Dua kategori yang secara default MASIH ada di daftar limitable user —
/// dipakai sebagai fallback supaya test yang tidak sedang menguji "kategori
/// lenyap" (U62) tidak diam-diam ikut kena cabang `skipped`.
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
    slug: 'kopi-senja',
    isBuiltIn: false,
    isLimitable: true,
    type: 'expense',
    sortOrder: 1,
  ),
];

void main() {
  setUpAll(() {
    registerFallbackValue(const NoParams());
  });

  late AppDatabase db;
  late ChallengeLocalDatasource local;
  late ChallengeSettingsDatasource sakelar;
  late ChallengeRepository repo;
  late _MockGetLimitable getLimitable;
  late FixedClock clock;
  late EnsureAndResolveChallenge usecase;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    local = ChallengeLocalDatasourceImpl(db);
    sakelar = ChallengeSettingsDatasourceImpl(db);

    final auth = _MockAuth();
    // Tanpa uid: `_kirim` di repo berhenti sebelum menyentuh jaringan/antrian,
    // jadi test ini bisa fokus murni ke efek lokal (kecuali U76, yang justru
    // memanfaatkan itu untuk membuktikan NOL item antrian baru).
    when(() => auth.currentUser).thenReturn(null);

    clock = FixedClock(DateTime(2026, 9, 7, 9));
    repo = ChallengeRepositoryImpl(
      local: local,
      remote: _MockRemote(),
      network: _MockNetwork(),
      auth: auth,
      clock: clock,
    );

    getLimitable = _MockGetLimitable();
    when(() => getLimitable(any()))
        .thenAnswer((_) async => const Right(_kategoriDefault));

    usecase = EnsureAndResolveChallenge(
      repo: repo,
      local: local,
      getLimitable: getLimitable,
      env: _MockEnvPort(),
      settings: sakelar,
      clock: clock,
    );
  });

  tearDown(() async => db.close());

  Future<void> tulisBaris({
    required int weekKey,
    String? kategori = 'food',
    ChallengeStatus status = ChallengeStatus.active,
    int? targetAmount = 100000,
    DateTime? resultSeenAt,
  }) => db.into(db.weeklyChallenges).insert(
    WeeklyChallengesCompanion.insert(
      weekKey: Value(weekKey),
      category: Value(kategori),
      targetAmount: Value(targetAmount),
      baselineAmount: const Value(140000),
      status: status,
      timezone: 'WIB',
      createdAt: DateTime.utc(2026, 8, 1),
      updatedAt: DateTime.utc(2026, 8, 1),
      resultSeenAt: Value(resultSeenAt),
    ),
  );

  Future<void> tambahTx({
    required int hari,
    int bulan = 9,
    required int nominal,
    String kategori = 'food',
  }) => db.into(db.transactions).insert(
    TransactionsCompanion.insert(
      txId: 'tx-$bulan-$hari-$nominal-$kategori-${DateTime.now().microsecondsSinceEpoch}',
      amount: nominal,
      category: kategori,
      type: 'expense',
      date: DateTime(2026, bulan, hari, 12),
      createdAt: DateTime(2026, bulan, hari, 12),
      updatedAt: DateTime(2026, bulan, hari, 12),
    ),
  );

  group('langkah 1 · tutup minggu lampau', () {
    test('U60 · baris active minggu lalu ditutup jadi achieved/missed', () async {
      await tulisBaris(weekKey: 20260831, targetAmount: 100000);
      await tambahTx(hari: 2, nominal: 40000); // di dalam minggu 20260831
      clock.at = DateTime(2026, 9, 7, 9); // Senin berikutnya

      await usecase(const NoParams());

      final row = await local.findWeek(20260831);
      expect(
        row!.status,
        anyOf(ChallengeStatus.achieved, ChallengeStatus.missed),
      );
      expect(row.finalSpent, isNotNull);
      expect(row.resolvedAt, isNotNull);
    });

    test('U61 · dua baris lampau active sekaligus → KEDUANYA ditutup', () async {
      await tulisBaris(weekKey: 20260817, targetAmount: 100000);
      await tambahTx(hari: 18, bulan: 8, nominal: 50000); // achieved
      await tulisBaris(weekKey: 20260824, targetAmount: 100000);
      await tambahTx(hari: 25, bulan: 8, nominal: 150000); // missed
      clock.at = DateTime(2026, 9, 7, 9);

      await usecase(const NoParams());

      final baris1 = await local.findWeek(20260817);
      final baris2 = await local.findWeek(20260824);
      expect(baris1!.status, ChallengeStatus.achieved);
      expect(baris1.finalSpent, 50000);
      expect(baris1.resolvedAt, isNotNull);
      expect(baris2!.status, ChallengeStatus.missed);
      expect(baris2.finalSpent, 150000);
      expect(baris2.resolvedAt, isNotNull);
    });

    test('U62 · kategori lenyap → skipped, dan finalSpent TETAP diisi', () async {
      await tulisBaris(
        weekKey: 20260831,
        kategori: 'kopi-senja',
        status: ChallengeStatus.active,
      );
      await tambahTx(hari: 1, bulan: 9, nominal: 200000, kategori: 'kopi-senja');
      // Kategori dihapus user — deleteCategory TIDAK menghapus transaksinya,
      // jadi angkanya masih ada dan layak dibekukan.
      when(() => getLimitable(any()))
          .thenAnswer((_) async => const Right(<CategoryEntity>[]));
      clock.at = DateTime(2026, 9, 7, 9);

      await usecase(const NoParams());

      final row = await local.findWeek(20260831);
      expect(row!.status, ChallengeStatus.skipped);
      expect(row.finalSpent, 200000); // bukan null, dan bukan 0
      expect(row.resolvedAt, isNotNull);
    });

    test(
      'U34 · setelah ditutup, hapus transaksi minggu itu lalu ensure lagi → '
      'finalSpent TIDAK berubah',
      () async {
        await tulisBaris(weekKey: 20260831, targetAmount: 100000);
        await tambahTx(hari: 2, nominal: 40000);
        clock.at = DateTime(2026, 9, 7, 9);

        await usecase(const NoParams());
        final sebelum = await local.findWeek(20260831);
        expect(sebelum!.finalSpent, 40000);
        expect(sebelum.status, ChallengeStatus.achieved);

        // Transaksi minggu itu dihapus SESUDAH baris ditutup.
        await (db.delete(
          db.transactions,
        )..where((t) => t.category.equals('food'))).go();

        await usecase(const NoParams());

        final sesudah = await local.findWeek(20260831);
        expect(sesudah!.finalSpent, 40000, reason: 'beku, tidak dihitung ulang');
        expect(sesudah.status, ChallengeStatus.achieved);
      },
    );
  });

  group('U76 (DIBALIK) · sakelar mati tidak menyentuh minggu berjalan', () {
    test('baris active minggu INI tetap active meski sakelar mati', () async {
      // Keputusan 1. Baris `active` minggu ini dengan sakelar mati hanya bisa
      // datang dari device lain — dan menutupnya di sini membunuh minggu yang
      // sedang berjalan di sana, permanen, karena mergeRank membuat `skipped`
      // menang atas `active`.
      await tulisBaris(weekKey: 20260907, status: ChallengeStatus.active);
      await sakelar.setEnabled(false);
      clock.at = DateTime(2026, 9, 9, 9); // Rabu, minggu yang sama

      await usecase(const NoParams());

      final row = await local.findWeek(20260907);
      expect(row!.status, ChallengeStatus.active);
      expect(row.resolvedAt, isNull);
      expect(await db.select(db.syncQueue).get(), isEmpty);
    });
  });

  group('langkah 1c · rapikan hasil lama (D22)', () {
    test('U114 · tiga hasil belum dilihat → dua terlama ditandai', () async {
      for (final w in [20260817, 20260824, 20260831]) {
        await tulisBaris(
          weekKey: w,
          status: ChallengeStatus.achieved,
          resultSeenAt: null,
        );
      }
      clock.at = DateTime(2026, 9, 7, 9);

      await usecase(const NoParams());

      expect((await local.findWeek(20260831))!.resultSeenAt, isNull);
      expect((await local.findWeek(20260824))!.resultSeenAt, isNotNull);
      expect((await local.findWeek(20260817))!.resultSeenAt, isNotNull);
    });

    test('U114 · hanya SATU hasil belum dilihat → tidak ada yang ditandai', () async {
      await tulisBaris(
        weekKey: 20260831,
        status: ChallengeStatus.achieved,
        resultSeenAt: null,
      );
      clock.at = DateTime(2026, 9, 7, 9);

      await usecase(const NoParams());

      expect((await local.findWeek(20260831))!.resultSeenAt, isNull);
    });

    // Catatan verifikasi: kalau kandidat satu-satunya kebetulan menjadi
    // `keepWeekKey`, ia SELALU mengecualikan dirinya sendiri di klausa WHERE
    // `markOlderResultsSeen` (S-C) — jadi memanggilnya dengan keepWeekKey =
    // dirinya sendiri pun menyentuh NOL baris, dan test di atas TIDAK bisa
    // membedakan "repo.markOlderResultsSeen dipanggil tapi tak berefek" dari
    // "repo.markOlderResultsSeen TIDAK dipanggil sama sekali". Repo nyata
    // diganti mock di sini SUPAYA panggilannya sendiri bisa diverifikasi —
    // ini yang benar-benar mengunci sabotase `hasilBaru.length > 1 → >= 1`.
    test(
      'U114 · hanya SATU hasil belum dilihat → repo.markOlderResultsSeen '
      'TIDAK PERNAH dipanggil',
      () async {
        final repoMock = _MockChallengeRepository();
        final usecaseKhusus = EnsureAndResolveChallenge(
          repo: repoMock,
          local: local,
          getLimitable: getLimitable,
          env: _MockEnvPort(),
          settings: sakelar,
          clock: clock,
        );
        await tulisBaris(
          weekKey: 20260831,
          status: ChallengeStatus.achieved,
          resultSeenAt: null,
        );
        clock.at = DateTime(2026, 9, 7, 9);

        await usecaseKhusus(const NoParams());

        verifyNever(
          () => repoMock.markOlderResultsSeen(
            keepWeekKey: any(named: 'keepWeekKey'),
          ),
        );
      },
    );
  });

  group('S-B · EnsureOutcome', () {
    test(
      'ensure di luar jendela pembuatan → candidateCount dan env null',
      () async {
        clock.at = DateTime(2026, 9, 10, 9); // Kamis, di luar Senin–Selasa

        final hasil = await usecase(const NoParams());

        expect(hasil.isRight(), isTrue);
        hasil.fold((_) => fail('seharusnya Right'), (outcome) {
          expect(outcome.weekKey, _mingguIni);
          expect(outcome.candidateCount, isNull);
          expect(outcome.env, isNull);
        });
      },
    );
  });
}
