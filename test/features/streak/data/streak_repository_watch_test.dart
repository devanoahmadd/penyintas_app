import 'package:dartz/dartz.dart';
import 'package:drift/native.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:penyintas_app/core/database/app_database.dart';
import 'package:penyintas_app/core/error/failures.dart';
import 'package:penyintas_app/core/network/network_info.dart';
import 'package:penyintas_app/core/utils/app_clock.dart';
import 'package:penyintas_app/features/streak/data/datasources/streak_local_datasource.dart';
import 'package:penyintas_app/features/streak/data/datasources/streak_mark_remote_datasource.dart';
import 'package:penyintas_app/features/streak/data/repositories/streak_repository_impl.dart';
import 'package:penyintas_app/features/streak/data/models/streak_mark_model.dart';
import 'package:penyintas_app/features/streak/domain/entities/streak_snapshot.dart';

class _MockRemote extends Mock implements StreakMarkRemoteDatasource {}

class _MockNetwork extends Mock implements NetworkInfo {}

class _MockAuth extends Mock implements FirebaseAuth {}

class _MockUser extends Mock implements User {}

class _FakeMark extends Fake implements StreakMarkModel {}

void main() {
  // Mock disimpan di VARIABEL, bukan dibuat anonim di konstruktor — test
  // `syncMarksFromRemote` di Step 4b men-stub `remote` dan `network`.
  setUpAll(() => registerFallbackValue(_FakeMark()));

  late AppDatabase db;
  late StreakLocalDatasource local;
  late _MockRemote remote;
  late _MockNetwork network;
  late _MockAuth auth;
  late StreakRepositoryImpl repo;
  late FixedClock clock;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    local = StreakLocalDatasourceImpl(db);
    remote = _MockRemote();
    network = _MockNetwork();
    auth = _MockAuth();
    final user = _MockUser();
    when(() => user.uid).thenReturn('u1');
    when(() => auth.currentUser).thenReturn(user);
    clock = FixedClock(DateTime(2026, 9, 5, 10));
    repo = StreakRepositoryImpl(
      local: local,
      remote: remote,
      network: network,
      auth: auth,
      clock: clock,
      epochDay: 20260901,
    );
  });
  tearDown(() async {
    repo.dispose();
    await db.close();
  });

  test('emisi pertama datang tanpa perubahan data apa pun', () async {
    final snap = await repo.watchSnapshot().first;
    expect(snap.hasStarted, isFalse);
    expect(snap.today, 20260905);
  });

  test('penanda baru memicu emisi ulang dengan streak yang naik', () async {
    final emisi = <StreakSnapshot>[];
    final sub = repo.watchSnapshot().listen(emisi.add);
    await Future<void>.delayed(const Duration(milliseconds: 250));

    await local.insertMark(
      dayKey: 20260905,
      markedAt: DateTime.utc(2026, 9, 5, 3),
      timezone: 'WIB',
      viaClockCorrection: false,
    );
    await Future<void>.delayed(const Duration(milliseconds: 250));
    await sub.cancel();

    expect(emisi.last.currentStreak, 1);
    expect(emisi.last.todayStatus, DayStatus.safe);
  });

  test('dua perubahan beruntun dalam 150 ms hanya menghasilkan SATU emisi '
      'tambahan (debounce)', () async {
    final emisi = <StreakSnapshot>[];
    final sub = repo.watchSnapshot().listen(emisi.add);
    await Future<void>.delayed(const Duration(milliseconds: 250));
    final sebelum = emisi.length;

    await local.insertMark(
      dayKey: 20260903,
      markedAt: DateTime.utc(2026, 9, 3),
      timezone: 'WIB',
      viaClockCorrection: false,
    );
    await local.insertMark(
      dayKey: 20260904,
      markedAt: DateTime.utc(2026, 9, 4),
      timezone: 'WIB',
      viaClockCorrection: false,
    );
    await Future<void>.delayed(const Duration(milliseconds: 250));
    await sub.cancel();

    expect(
      emisi.length - sebelum,
      1,
      reason: 'satu batch penyimpanan menyentuh dua tabel yang keduanya '
          'diawasi — tanpa debounce kalkulator berjalan dua kali',
    );
  });

  test(
    'requestRecompute memicu emisi walau data tak berubah — dipakai timer '
    'tengah malam',
    () async {
      final emisi = <StreakSnapshot>[];
      final sub = repo.watchSnapshot().listen(emisi.add);
      await Future<void>.delayed(const Duration(milliseconds: 250));
      final sebelum = emisi.length;

      clock.at = DateTime(2026, 9, 6, 0, 1);
      repo.requestRecompute();
      await Future<void>.delayed(const Duration(milliseconds: 250));
      await sub.cancel();

      expect(emisi.length, sebelum + 1);
      expect(
        emisi.last.today,
        20260906,
        reason: 'hari berganti tanpa perubahan tabel',
      );
    },
  );

  test(
    'D-17 — penanda viaClockCorrection masuk markedDaysAll TAPI TIDAK '
    'menghitung ruas',
    () async {
      final emisi = <StreakSnapshot>[];
      final sub = repo.watchSnapshot().listen(emisi.add);
      await Future<void>.delayed(const Duration(milliseconds: 250));

      await local.insertMark(
        dayKey: 20260905,
        markedAt: DateTime.utc(2026, 9, 5, 3),
        timezone: 'WIB',
        viaClockCorrection: true,
      );
      await Future<void>.delayed(const Duration(milliseconds: 250));
      await sub.cancel();

      expect(
        emisi.last.markedDaysAll.contains(20260905),
        isTrue,
        reason: 'markedDaysAll MENTAH — penanda hasil koreksi jam tetap '
            'harus terlihat di sana (dipakai aturan CTA)',
      );
      expect(
        emisi.last.hasStarted,
        isFalse,
        reason: 'tapi kalkulator DILARANG membacanya — tidak boleh '
            'menghitung ruas sama sekali',
      );
      expect(emisi.last.currentStreak, 0);
    },
  );

  group('isTodaySafe', () {
    test('true saat hari ini punya penanda', () async {
      await local.insertMark(
        dayKey: 20260905,
        markedAt: DateTime.utc(2026, 9, 5),
        timezone: 'WIB',
        viaClockCorrection: false,
      );
      expect(await repo.isTodaySafe(), isTrue);
    });

    test('false saat hari ini kosong', () async {
      expect(await repo.isTodaySafe(), isFalse);
    });

    test('false — BUKAN lempar — saat lapisan bawah gagal', () async {
      await db.close(); // paksa galat
      expect(await repo.isTodaySafe(), isFalse);
    });
  });

  test('syncMarksFromRemote menarik penanda dan tidak menimpa baris lokal', () async {
    when(() => network.isConnected).thenAnswer((_) async => true);
    when(() => remote.getMarks(sinceDayKey: any(named: 'sinceDayKey')))
        .thenAnswer((_) async => [
              StreakMarkModel(
                dayKey: 20260902,
                markedAt: DateTime.utc(2026, 9, 2),
                timezone: 'WIB',
              ),
            ]);
    final hasil = await repo.syncMarksFromRemote();
    expect(hasil, const Right<Failure, int>(1));
    expect(await local.readMarkedDays(), {20260902});
  });

  test('offline → no-op, bukan galat', () async {
    when(() => network.isConnected).thenAnswer((_) async => false);
    expect(await repo.syncMarksFromRemote(), const Right<Failure, int>(0));
    verifyNever(() => remote.getMarks(sinceDayKey: any(named: 'sinceDayKey')));
  });

  test('T33 — penanda yang belum pernah tersinkron DIDORONG naik lebih dulu', () async {
    // CATATAN PENYIMPANGAN DARI RENCANA: draf rencana memanggil
    // `repo.syncMarksFromRemote()` di sini, tapi kode `syncMarksFromRemote()`
    // yang diberikan rencana sendiri TARIK SAJA (komentar "D-9" di
    // implementasi) — dorongan sudah dipindah ke `pushPendingMarks()`
    // ("Rev 2 menaruh dorongan lebih dulu di sini" = fosil revisi lama).
    // Assersi test ini (dorongan naik, viaClockCorrection dikecualikan,
    // isSynced jadi true) persis perilaku `pushPendingMarks()` — jadi
    // dipanggil di sini, bukan `syncMarksFromRemote()`.
    when(() => network.isConnected).thenAnswer((_) async => true);
    when(() => remote.saveMark(any())).thenAnswer((_) async {});

    // Persis keadaan sesudah antrean kedaluwarsa 7 hari: baris ada di lokal,
    // dokumennya tidak pernah tercipta di Firestore.
    await local.insertMark(
      dayKey: 20260903,
      markedAt: DateTime.utc(2026, 9, 3),
      timezone: 'WIB',
      viaClockCorrection: false,
    );
    await local.insertMark(
      dayKey: 20260904,
      markedAt: DateTime.utc(2026, 9, 4),
      timezone: 'WIB',
      viaClockCorrection: true,
    );

    await repo.pushPendingMarks();

    final terkirim = verify(() => remote.saveMark(captureAny()))
        .captured
        .cast<StreakMarkModel>()
        .map((m) => m.dayKey)
        .toList();
    expect(
      terkirim,
      [20260903],
      reason: 'baris bertanda TIDAK PERNAH naik ke Firestore (spec §4.7)',
    );
    expect(
      (await local.findMark(20260903))!.isSynced,
      isTrue,
      reason: 'sesudah naik ia tidak boleh didorong lagi tiap login',
    );
  });

  test(
    'T44 — undo yang menang race SELAGI pushPendingMarks di udara '
    'menghapus balik dokumen yang baru saja terunggah (D-15)',
    () async {
      when(() => network.isConnected).thenAnswer((_) async => true);
      when(() => remote.getMarks(sinceDayKey: any(named: 'sinceDayKey')))
          .thenAnswer((_) async => const <StreakMarkModel>[]);

      await local.insertMark(
        dayKey: 20260905,
        markedAt: DateTime.utc(2026, 9, 5),
        timezone: 'WIB',
        viaClockCorrection: false,
      );

      // Simulasikan tepat jendela race: begitu `saveMark` "sampai" di remote,
      // user sudah mengurungkan baris itu di lokal — sebelum
      // `pushPendingMarks()` sempat membaca ulang dan menandainya sinkron.
      when(() => remote.saveMark(any())).thenAnswer((_) async {
        await local.deleteMark(20260905);
      });
      when(() => remote.deleteMark(any())).thenAnswer((_) async {});

      final naik = await repo.pushPendingMarks();

      expect(
        naik,
        0,
        reason: 'baris yang lenyap di tengah jalan tidak dihitung naik',
      );
      verify(() => remote.deleteMark(20260905)).called(1);
      expect(
        await local.hasMark(20260905),
        isFalse,
        reason: 'undo user tidak boleh dibatalkan diam-diam oleh dorongan '
            'bootstrap miliknya sendiri',
      );
    },
  );
}
