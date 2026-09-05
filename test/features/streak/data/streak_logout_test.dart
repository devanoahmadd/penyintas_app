// Task 10 — logout & lintas akun.
//
// ⚠️ CACAT RENCANA: snippet asli di rencana memanggil `computeStreak(...)`
// TANPA `markedDaysAll`, padahal tanda tangan sebenarnya
// (`lib/features/streak/domain/streak_calculator.dart`) mewajibkannya. Semua
// pemanggilan di bawah sudah disesuaikan agar meng-compile — lihat kode
// sumber, bukan rencana, untuk tanda tangan sebenarnya.
//
// Task ini TIDAK membuat kode produksi baru. Bila salah satu test di sini
// gagal, itu bug nyata — dilaporkan, bukan dilonggarkan asersinya.
import 'package:drift/native.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:penyintas_app/core/database/app_database.dart';
import 'package:penyintas_app/core/network/network_info.dart';
import 'package:penyintas_app/core/utils/app_clock.dart';
import 'package:penyintas_app/features/streak/data/datasources/streak_local_datasource.dart';
import 'package:penyintas_app/features/streak/data/datasources/streak_mark_remote_datasource.dart';
import 'package:penyintas_app/features/streak/data/models/streak_mark_model.dart';
import 'package:penyintas_app/features/streak/data/repositories/streak_repository_impl.dart';
import 'package:penyintas_app/features/streak/domain/entities/streak_meta_values.dart';
import 'package:penyintas_app/features/streak/domain/streak_calculator.dart';

class _MockRemote extends Mock implements StreakMarkRemoteDatasource {}

class _MockNetwork extends Mock implements NetworkInfo {}

class _MockAuth extends Mock implements FirebaseAuth {}

class _MockUser extends Mock implements User {}

class _FakeMark extends Fake implements StreakMarkModel {}

void main() {
  setUpAll(() => registerFallbackValue(_FakeMark()));

  late AppDatabase db;
  late StreakLocalDatasource ds;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    ds = StreakLocalDatasourceImpl(db);
  });
  tearDown(() => db.close());

  test('KEBERSIHAN — akun B tidak melihat penanda akun A', () async {
    await ds.insertMark(
      dayKey: 20260902,
      markedAt: DateTime.utc(2026, 9, 2),
      timezone: 'WIB',
      viaClockCorrection: false,
    );
    await ds.saveMeta(
      StreakMetaValues.empty.copyWith(
        lastSeenDay: 20260902,
        maxSeenDay: 20260902,
      ),
    );

    await db.clearAllLocalData(); // logout

    expect(await ds.readMarkedDays(), isEmpty);
    expect(
      await ds.readMeta(),
      StreakMetaValues.empty,
      reason:
          'baris streak_meta ikut tersapu dan TIDAK dibuat ulang — '
          'readMeta wajib tahan itu, bukan melempar',
    );
  });

  test(
    'T15 — KETAHANAN: logout lalu login ulang mengembalikan streak UTUH',
    () async {
      // Akun A: 10 hari aman berturut, semuanya sudah tersinkron.
      for (var i = 1; i <= 10; i++) {
        await ds.insertMark(
          dayKey: 20260900 + i,
          markedAt: DateTime.utc(2026, 9, i),
          timezone: 'WIB',
          viaClockCorrection: false,
        );
      }
      final ditandaiSebelum = await ds.readMarkedDays();
      final sebelum = computeStreak(
        markedDays: ditandaiSebelum,
        markedDaysAll: ditandaiSebelum,
        transactionDays: const {},
        epochDay: 20260901,
        lastSeenDay: 20260910,
        today: 20260910,
      );
      expect(sebelum.currentStreak, 10);
      expect(sebelum.activatedDay, 20260901);

      // Logout menyapu semuanya.
      await db.clearAllLocalData();
      expect(await ds.readMarkedDays(), isEmpty);

      // Login ulang: gerbang bootstrap menarik penanda kembali dari Firestore.
      await ds.upsertMarksFromRemote([
        for (var i = 1; i <= 10; i++)
          StreakMarkModel(
            dayKey: 20260900 + i,
            markedAt: DateTime.utc(2026, 9, i),
            timezone: 'WIB',
          ),
      ]);

      final ditandaiSesudah = await ds.readMarkedDays();
      final sesudah = computeStreak(
        markedDays: ditandaiSesudah,
        markedDaysAll: ditandaiSesudah,
        transactionDays: const {},
        epochDay: 20260901,
        lastSeenDay:
            0, // StreakMeta tersapu — mulai dari nol, itu tidak apa-apa
        today: 20260910,
      );
      expect(
        sesudah.currentStreak,
        10,
        reason:
            'streak 10 hari tidak boleh lenyap hanya karena user login ulang',
      );
      expect(
        sesudah.activatedDay,
        20260901,
        reason:
            'activatedDay TERHITUNG ULANG dari hari aman pertama, '
            'bukan disetel ke hari ini',
      );
      expect(sesudah.hasStarted, isTrue);
    },
  );

  group('T10-a — cabang uid == null: nol percobaan sync', () {
    // Baris lokal tercipta/terhapus seperti biasa, hasilnya Right(null), TAPI
    // TIDAK ADA percobaan sync sama sekali — bahkan network.isConnected pun
    // tidak pernah ditanya. Ini beda dari "diantre offline" (yang tetap
    // menulis satu baris ke sync_queue).
    late _MockRemote remote;
    late _MockNetwork network;
    late _MockAuth auth;
    late FixedClock clock;
    late StreakRepositoryImpl repo;

    setUp(() {
      remote = _MockRemote();
      network = _MockNetwork();
      auth = _MockAuth();
      when(() => auth.currentUser).thenReturn(null); // belum login
      when(() => network.isConnected).thenAnswer((_) async => true);
      when(() => remote.saveMark(any())).thenAnswer((_) async {});
      when(() => remote.deleteMark(any())).thenAnswer((_) async {});
      clock = FixedClock(DateTime(2026, 9, 5, 10));
      repo = StreakRepositoryImpl(
        local: ds,
        remote: remote,
        network: network,
        auth: auth,
        clock: clock,
        epochDay: 20260901,
      );
    });
    tearDown(() => repo.dispose());

    test(
      'markToday — baris lokal tetap tercipta, sync_queue tetap kosong',
      () async {
        final hasil = await repo.markToday();

        expect(hasil.isRight(), isTrue);
        expect(await ds.readMarkedDays(), {20260905});
        expect(
          await db.select(db.syncQueue).get(),
          isEmpty,
          reason:
              'belum login — bukan "diantre offline", nol percobaan sync '
              'sama sekali',
        );
        verifyNever(() => remote.saveMark(any()));
        verifyNever(() => network.isConnected);
      },
    );

    test(
      'unmarkToday — baris lokal tetap terhapus, sync_queue tetap kosong',
      () async {
        await ds.insertMark(
          dayKey: 20260905,
          markedAt: DateTime.utc(2026, 9, 5),
          timezone: 'WIB',
          viaClockCorrection: false,
        );

        final hasil = await repo.unmarkToday();

        expect(hasil.isRight(), isTrue);
        expect(await ds.hasMark(20260905), isFalse);
        expect(await db.select(db.syncQueue).get(), isEmpty);
        verifyNever(() => remote.deleteMark(any()));
        verifyNever(() => network.isConnected);
      },
    );
  });

  test('T10-b — penanda PERTAMA akun baru (meta kosong pasca logout) TIDAK '
      'ditandai viaClockCorrection', () async {
    // Akun LAMA meninggalkan jejak jam tinggi sebelum logout.
    await ds.insertMark(
      dayKey: 20260810,
      markedAt: DateTime.utc(2026, 8, 10),
      timezone: 'WIB',
      viaClockCorrection: false,
    );
    await ds.saveMeta(
      StreakMetaValues.empty.copyWith(
        lastSeenDay: 20260810,
        maxSeenDay: 20260810,
      ),
    );

    await db.clearAllLocalData(); // logout — streak_meta ikut tersapu
    expect(await ds.readMeta(), StreakMetaValues.empty);

    // Login akun BARU, tandai hari ini untuk pertama kalinya.
    final remote = _MockRemote();
    final network = _MockNetwork();
    final auth = _MockAuth();
    final user = _MockUser();
    when(() => user.uid).thenReturn('uidBaru');
    when(() => auth.currentUser).thenReturn(user);
    when(() => network.isConnected).thenAnswer((_) async => true);
    when(() => remote.saveMark(any())).thenAnswer((_) async {});
    final clock = FixedClock(DateTime(2026, 9, 5, 10));
    final repo = StreakRepositoryImpl(
      local: ds,
      remote: remote,
      network: network,
      auth: auth,
      clock: clock,
      epochDay: 20260901,
    );
    addTearDown(repo.dispose);

    await repo.markToday();

    final row = await ds.findMark(20260905);
    expect(row, isNotNull);
    expect(
      row!.viaClockCorrection,
      isFalse,
      reason:
          'akun baru tanpa riwayat jam tidak boleh dicap koreksi jam '
          'hanya karena maxSeenDay masih nol — addDays(0, -2) menghitung '
          'mundur dari tanggal tak bermakna',
    );
  });

  test(
    'T10-c — item sync_queue milik akun LAMA tidak boleh selamat logout',
    () async {
      await ds.addToSyncQueue(
        itemId: '20260901',
        collectionPath: 'users/uidLama/streak_marks/20260901',
        data: const {'dayKey': 20260901},
        operation: SyncOperation.create,
      );
      expect(await db.select(db.syncQueue).get(), hasLength(1));

      await db.clearAllLocalData();

      expect(
        await db.select(db.syncQueue).get(),
        isEmpty,
        reason:
            'item yang selamat akan didispatch dengan kredensial akun baru '
            'dan ditolak firestore.rules',
      );
    },
  );
}
