import 'dart:convert';

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

class _MockRemote extends Mock implements StreakMarkRemoteDatasource {}

class _MockNetwork extends Mock implements NetworkInfo {}

class _MockAuth extends Mock implements FirebaseAuth {}

class _MockUser extends Mock implements User {}

class _FakeMark extends Fake implements StreakMarkModel {}

/// Datasource nyata dengan SATU jendela race yang bisa disuntik.
///
/// Ia hanya dipakai test race `pushPendingMarks()`: [saatBacaBelumNaik]
/// dijalankan TEPAT sesudah `readUnsyncedMarks()` mengembalikan daftarnya dan
/// SEBELUM loop dorongan sempat membaca ulang baris lewat `findMark()`. Daftar
/// yang dikembalikan sengaja tetap yang BASI — persis yang dipegang loop di
/// produksi ketika user menekan sesuatu di jendela itu.
class _LocalDenganRace extends StreakLocalDatasourceImpl {
  _LocalDenganRace(super.db);

  Future<void> Function()? saatBacaBelumNaik;

  @override
  Future<List<StreakDayMark>> readUnsyncedMarks() async {
    final basi = await super.readUnsyncedMarks();
    final hook = saatBacaBelumNaik;
    saatBacaBelumNaik = null; // sekali pakai — bukan pemicu berulang
    if (hook != null) await hook();
    return basi;
  }
}

/// Datasource nyata dengan jendela race di antara `markSynced()` (fix2
/// `pushPendingMarks()` menunggu di sini) dan purge fix2 (TEMUAN R3):
/// keduanya operasi DB TERPISAH, bukan satu transaksi, jadi user bisa
/// menekan Undo TEPAT di antara keduanya.
class _LocalDenganRaceMarkSynced extends StreakLocalDatasourceImpl {
  _LocalDenganRaceMarkSynced(super.db);

  Future<void> Function()? saatSesudahMarkSynced;

  @override
  Future<void> markSynced(int dayKey) async {
    await super.markSynced(dayKey);
    final hook = saatSesudahMarkSynced;
    saatSesudahMarkSynced = null; // sekali pakai
    if (hook != null) await hook();
  }
}

void main() {
  setUpAll(() => registerFallbackValue(_FakeMark()));

  late AppDatabase db;
  late StreakLocalDatasource local;
  late _MockRemote remote;
  late _MockNetwork network;
  late _MockAuth auth;
  late StreakRepositoryImpl repo;
  late FixedClock clock;

  const path = 'users/u1/streak_marks/20260905';

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    local = StreakLocalDatasourceImpl(db);
    remote = _MockRemote();
    network = _MockNetwork();
    auth = _MockAuth();
    final user = _MockUser();
    when(() => user.uid).thenReturn('u1');
    when(() => auth.currentUser).thenReturn(user);
    when(() => network.isConnected).thenAnswer((_) async => true);
    when(() => remote.saveMark(any())).thenAnswer((_) async {});
    when(() => remote.deleteMark(any())).thenAnswer((_) async {});
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

  Future<List<SyncQueueData>> antrean() => db.select(db.syncQueue).get();
  Future<StreakDayMark?> baris(int dayKey) => (db.select(
    db.streakDayMarks,
  )..where((t) => t.dayKey.equals(dayKey))).getSingleOrNull();

  group('markToday — jalur normal', () {
    test('menyimpan baris lokal dan mendorong ke remote saat online', () async {
      final hasil = await repo.markToday();
      expect(hasil.isRight(), isTrue);
      final row = await baris(20260905);
      expect(row, isNotNull);
      expect(row!.viaClockCorrection, isFalse);
      expect(row.isSynced, isTrue);
      verify(() => remote.saveMark(any())).called(1);
      expect(await antrean(), isEmpty);
    });

    test('mengantre saat offline', () async {
      when(() => network.isConnected).thenAnswer((_) async => false);
      await repo.markToday();
      final q = await antrean();
      expect(q, hasLength(1));
      expect(q.single.collectionPath, path);
      expect(q.single.operation, SyncOperation.create);
    });

    test(
      'T31 — menandai hari yang SUDAH ditandai tidak menulis ulang apa pun',
      () async {
        await repo.markToday(); // tersinkron (online)
        clearInteractions(remote);

        final hasil = await repo.markToday();

        expect(hasil.isRight(), isTrue, reason: 'no-op, bukan galat');
        final row = await baris(20260905);
        expect(
          row!.isSynced,
          isTrue,
          reason: 'status sinkron tak boleh ter-reset',
        );
        verifyNever(() => remote.saveMark(any()));
        expect(await antrean(), isEmpty, reason: 'tak ada kiriman kedua');
      },
    );

    test('guard T11 — mode netral penjaga jam MENOLAK penandaan', () async {
      // lastSeenDay 6 Sep, jam device 5 Sep → selisih 1 hari.
      await local.saveMeta(
        StreakMetaValues.empty.copyWith(
          lastSeenDay: 20260906,
          maxSeenDay: 20260906,
        ),
      );
      final hasil = await repo.markToday();
      expect(hasil.isLeft(), isTrue);
      expect(await baris(20260905), isNull, reason: 'tak ada baris tercipta');
      verifyNever(() => remote.saveMark(any()));
    });
  });

  group('T26/T27/T28 — viaClockCorrection', () {
    test(
      'T26 — jam mundur > 2 hari di bawah maxSeenDay → baris DITANDAI',
      () async {
        // PENYIMPANGAN SADAR DARI RENCANA: rencana menulis lastSeenDay 20260905
        // di sini. Dengan nilai itu, sabotase "ganti pembanding ke lastSeenDay"
        // memerahkan T26 DAN T28 sekaligus — dan test yang merah bersama tidak
        // membuktikan siapa yang menjaga apa. Nilai di bawah adalah keadaan yang
        // sesungguhnya sesaat sesudah jam dimundurkan: meta belum tersentuh
        // siapa pun, jadi KEDUA field masih tinggi. T26 mengunci "tandanya
        // menyala"; T28 sendirian yang mengunci "pembandingnya maxSeenDay".
        await local.saveMeta(
          StreakMetaValues.empty.copyWith(
            lastSeenDay: 20260930,
            maxSeenDay: 20260930,
          ),
        );
        await repo.markToday();
        expect((await baris(20260905))!.viaClockCorrection, isTrue);
        // Dan ia tak ikut replay:
        expect(await local.readMarkedDays(), isEmpty);
      },
    );

    test(
      'T27 — offline berhari-hari dengan jam akurat TIDAK memicu tanda',
      () async {
        // maxSeenDay tertinggal jauh di belakang; hari ini jauh di DEPANnya.
        await local.saveMeta(
          StreakMetaValues.empty.copyWith(
            lastSeenDay: 20260820,
            maxSeenDay: 20260820,
          ),
        );
        await repo.markToday();
        expect((await baris(20260905))!.viaClockCorrection, isFalse);
        expect(await local.readMarkedDays(), {20260905});
      },
    );

    test('T28 — URUTAN EKSEKUSI: lastSeenDay sudah diturunkan bloc lebih dulu, '
        'tanda TETAP menyala karena pembandingnya maxSeenDay', () async {
      // Persis keadaan sesudah snapshot dihitung di cabang "koreksi jam":
      // StreakBloc menulis lastSeenDay := today (selisih jadi NOL), sementara
      // maxSeenDay TIDAK pernah turun.
      await local.saveMeta(
        StreakMetaValues.empty.copyWith(
          lastSeenDay: 20260905, // sudah diturunkan!
          maxSeenDay: 20261005, // sisa dari jam yang dulu dimajukan
        ),
      );
      await repo.markToday();
      expect(
        (await baris(20260905))!.viaClockCorrection,
        isTrue,
        reason:
            'inilah bug Rev 4 yang test ini kunci — membandingkan '
            'lastSeenDay di sini SELALU memberi nol',
      );
    });

    test('T29 — baris bertanda TIDAK PERNAH diantre maupun didorong', () async {
      await local.saveMeta(
        StreakMetaValues.empty.copyWith(
          lastSeenDay: 20260930,
          maxSeenDay: 20260930,
        ),
      );
      await repo.markToday();
      expect(
        await antrean(),
        isEmpty,
        reason: 'yang tidak pernah dikirim tidak bisa dicuci oleh reinstall',
      );
      verifyNever(() => remote.saveMark(any()));
    });

    test('ambang penjaga diukur dalam HARI, bukan jarak angka yyyymmdd — '
        'pergantian bulan tidak boleh menandai hari yang jujur', () async {
      // maxSeenDay 1 Okt, hari device 30 Sep: mundur SEHARI (jam device baru
      // saja diperbaiki dari maju satu hari). Pengurangan mentah memberi
      // 20261001 - 2 = 20260999 dan menyimpulkan 20260930 < 20260999 → TANDA
      // MENYALA untuk user yang tak curang apa pun.
      clock.at = DateTime(2026, 9, 30, 10);
      await local.saveMeta(
        StreakMetaValues.empty.copyWith(
          lastSeenDay: 20260925, // jauh di belakang → mode netral tak menyala
          maxSeenDay: 20261001,
        ),
      );
      await repo.markToday();
      expect(
        (await baris(20260930))!.viaClockCorrection,
        isFalse,
        reason: 'selisihnya SATU hari, bukan 71',
      );
    });
  });

  group('T16/T25 — jalur hapus & anti-race', () {
    test(
      'T16 — undo atas penanda yang SUDAH tersinkron mengantre delete',
      () async {
        await repo.markToday(); // tersinkron langsung (online)
        await repo.unmarkToday();
        expect(await baris(20260905), isNull);
        final q = await antrean();
        expect(q, hasLength(1));
        expect(q.single.operation, SyncOperation.delete);
        expect(q.single.collectionPath, path);
      },
    );

    test(
      'undo atas penanda yang BELUM pernah terkirim tidak mengantre apa pun',
      () async {
        when(() => network.isConnected).thenAnswer((_) async => false);
        await repo.markToday(); // create menunggu di antrean
        await repo.unmarkToday();
        expect(
          await antrean(),
          isEmpty,
          reason: 'dokumen remote memang belum pernah ada',
        );
      },
    );

    test('T25 — delete basi tidak boleh menghapus penanda yang baru '
        'ditandai ulang', () async {
      await repo.markToday(); // tersinkron
      await repo.unmarkToday(); // delete masuk antrean
      expect((await antrean()).single.operation, SyncOperation.delete);

      // Blip jaringan: dispatch gagal, item TETAP di antrean (perilaku
      // _processQueue yang sesungguhnya). Lalu user menandai ulang hari
      // yang sama.
      when(() => network.isConnected).thenAnswer((_) async => false);
      await repo.markToday();

      final q = await antrean();
      expect(
        q.where((e) => e.operation == SyncOperation.delete),
        isEmpty,
        reason: 'delete basi WAJIB dibuang sebelum create baru diantre',
      );
      expect(q.where((e) => e.operation == SyncOperation.create), hasLength(1));
    });

    test(
      'T32 — mengurungkan baris BERTANDA tidak mengantre delete apa pun',
      () async {
        await local.saveMeta(
          StreakMetaValues.empty.copyWith(
            lastSeenDay: 20260930,
            maxSeenDay: 20260930,
          ),
        );
        await repo.markToday(); // tercipta bertanda, tak pernah diantre
        expect((await baris(20260905))!.viaClockCorrection, isTrue);

        await repo.unmarkToday();

        expect(await baris(20260905), isNull, reason: 'lokal tetap terhapus');
        expect(
          await antrean(),
          isEmpty,
          reason:
              'baris bertanda tak pernah punya dokumen remote — mengantre '
              'delete justru menghapus penanda sah milik device lain',
        );
        verifyNever(() => remote.deleteMark(any()));
      },
    );

    test(
      'D-8 — undo saat tidak ada penanda hari ini adalah no-op penuh',
      () async {
        // Persis keadaan bila tengah malam lewat selagi SnackBar undo hidup:
        // hari sudah berganti, dan hari BARU ini belum pernah ditandai.
        final hasil = await repo.unmarkToday();

        expect(hasil.isRight(), isTrue);
        expect(
          await antrean(),
          isEmpty,
          reason:
              'tidak boleh mengantre delete untuk hari yang tak pernah '
              'diurungkan siapa pun',
        );
        verifyNever(() => remote.deleteMark(any()));
      },
    );
  });

  group('race pushPendingMarks × jalur tulis (D-15)', () {
    test('baris yang diurungkan lalu DITANDAI ULANG sebagai bertanda tepat di '
        'jendela readUnsyncedMarks→findMark tidak jadi didorong', () async {
      // Baris jujur yang belum pernah naik (antreannya sudah kedaluwarsa
      // 7 hari) — persis kandidat yang pushPendingMarks() bangun untuk itu.
      final racing = _LocalDenganRace(db);
      final repoRace = StreakRepositoryImpl(
        local: racing,
        remote: remote,
        network: network,
        auth: auth,
        clock: clock,
        epochDay: 20260901,
      );
      addTearDown(repoRace.dispose);

      await racing.insertMark(
        dayKey: 20260905,
        markedAt: DateTime.utc(2026, 9, 5, 3),
        timezone: 'WIB',
        viaClockCorrection: false,
      );
      // Jam device sudah dimundurkan jauh; meta belum tersentuh siapa pun.
      await racing.saveMeta(
        StreakMetaValues.empty.copyWith(
          lastSeenDay: 20260930,
          maxSeenDay: 20260930,
        ),
      );

      // JENDELA RACE: daftar "belum naik" sudah dipegang loop, lalu user
      // menekan undo dan menandai ulang. Penandaan ulang itu BERTANDA —
      // inilah satu-satunya jalur di codebase yang benar-benar MENGUBAH
      // viaClockCorrection pada hari yang sudah punya baris.
      racing.saatBacaBelumNaik = () async {
        // Jaringan padam sekejap TEPAT selama dua ketukan itu. Bukan hiasan:
        // tanpa ini test ini juga ikut merah saat penjaga MILIK markToday()
        // (`if (viaClockCorrection) return`) yang dirusak — padahal yang
        // hendak dikunci di sini semata-mata penjaga baca-ulang milik
        // pushPendingMarks(). Satu test, satu penjaga. pushPendingMarks()
        // sendiri sudah melewati gerbang `isConnected`-nya di atas, jadi
        // padamnya tidak menyentuh jalur yang sedang diuji.
        when(() => network.isConnected).thenAnswer((_) async => false);
        await repoRace.unmarkToday();
        await repoRace.markToday();
        when(() => network.isConnected).thenAnswer((_) async => true);
      };

      final naik = await repoRace.pushPendingMarks();

      expect(naik, 0, reason: 'tak ada yang sah untuk didorong');
      verifyNever(() => remote.saveMark(any()));
      final row = await baris(20260905);
      expect(row!.viaClockCorrection, isTrue);
      expect(
        row.isSynced,
        isFalse,
        reason: 'baris bertanda tak boleh pernah dicap tersinkron',
      );
      // M5 — antrean di akhir race ini BUKAN kosong: satu `delete` basi
      // (dari `unmarkToday()` di dalam hook, atas baris jujur semula) masih
      // menunggu. Itu BENAR — delete berasal dari undo pada baris jujur,
      // dan mark-ulang bertanda tidak boleh membatalkannya. Nyatakan
      // sebagai asersi supaya keadaan ini tidak diam-diam berubah.
      final q = await antrean();
      expect(q, hasLength(1));
      expect(q.single.operation, SyncOperation.delete);
    });
  });

  group('TEMUAN C1/I1/I2/I3/I4 — Ronde Perbaikan 1', () {
    test(
      'C1 — mark offline lalu pushPendingMarks() lalu undo mengantre '
      'TEPAT satu delete (dokumen remote tak boleh jadi yatim)',
      () async {
        when(() => network.isConnected).thenAnswer((_) async => false);
        await repo.markToday(); // create menunggu di antrean, isSynced=false
        expect((await antrean()).single.operation, SyncOperation.create);

        when(() => network.isConnected).thenAnswer((_) async => true);
        final naik = await repo.pushPendingMarks();
        expect(naik, 1);
        final rowSesudahPush = await baris(20260905);
        expect(
          rowSesudahPush!.isSynced,
          isTrue,
          reason: 'dokumen remote sudah ada lewat pushPendingMarks()',
        );

        await repo.unmarkToday();

        final q = await antrean();
        expect(
          q,
          hasLength(1),
          reason:
              'delete WAJIB diantre — dokumen remote sudah dibuat lewat '
              'pushPendingMarks(), bukan lewat SyncQueue',
        );
        expect(q.single.operation, SyncOperation.delete);
        expect(q.single.collectionPath, path);
      },
    );

    test(
      'C1 (minimal, terisolasi dari fix menyeluruh) — row.isSynced=true '
      'dengan create basi tersisa di antrean tetap mengantre delete',
      () async {
        // Keadaan disuntik LANGSUNG (bukan lewat pushPendingMarks()) supaya
        // test ini murni mengunci penjaga `!row.isSynced` milik unmarkToday()
        // — TIDAK bergantung pada purge di pushPendingMarks() (fix
        // menyeluruh, dikunci test terpisah di bawah).
        await local.insertMark(
          dayKey: 20260905,
          markedAt: DateTime.utc(2026, 9, 5, 3),
          timezone: 'WIB',
          viaClockCorrection: false,
        );
        await local.markSynced(20260905);
        await local.addToSyncQueue(
          itemId: '20260905',
          collectionPath: path,
          data: const {'dayKey': 20260905},
          operation: SyncOperation.create,
        );

        await repo.unmarkToday();

        final q = await antrean();
        expect(
          q,
          hasLength(1),
          reason:
              'row.isSynced=true berarti dokumen remote memang ada — '
              'delete WAJIB diantre meski createDibuang > 0',
        );
        expect(q.single.operation, SyncOperation.delete);
      },
    );

    test(
      'C1 (menyeluruh) — pushPendingMarks() membuang create basi dari '
      'antrean sesudah mendorong baris langsung',
      () async {
        when(() => network.isConnected).thenAnswer((_) async => false);
        await repo.markToday(); // create menunggu di antrean
        expect((await antrean()).single.operation, SyncOperation.create);

        when(() => network.isConnected).thenAnswer((_) async => true);
        final naik = await repo.pushPendingMarks();
        expect(naik, 1);

        expect(
          await antrean(),
          isEmpty,
          reason:
              'create basi WAJIB dibuang begitu baris naik langsung lewat '
              'pushPendingMarks() — tak boleh menunggu TTL 7 hari tanpa '
              'guna',
        );
      },
    );

    test(
      'I1 — ambang penjaga netral diukur dalam HARI, bukan jarak angka '
      'yyyymmdd — pergantian bulan tidak boleh meloloskan penandaan curang',
      () async {
        // lastSeenDay 1 Okt, jam device mundur ke 30 Sep: kalender selisih
        // 1 hari → penjaga netral WAJIB menolak. Pengurangan yyyymmdd
        // mentah (20261001 - 20260930 = 71) akan salah menyimpulkan aman.
        clock.at = DateTime(2026, 9, 30, 10);
        await local.saveMeta(
          StreakMetaValues.empty.copyWith(
            lastSeenDay: 20261001,
            maxSeenDay: 20261001,
          ),
        );
        final hasil = await repo.markToday();
        expect(hasil.isLeft(), isTrue);
        expect(
          await baris(20260930),
          isNull,
          reason: 'tak ada baris tercipta — penjaga netral menolak',
        );
      },
    );

    test(
      'I2 — online tapi push ke remote gagal → baris lokal tetap tercipta '
      'dan diantre, bukan dibuang',
      () async {
        when(() => remote.saveMark(any())).thenThrow(Exception('boom'));

        final hasil = await repo.markToday();

        expect(hasil.isRight(), isTrue, reason: 'gagal push bukan galat user');
        expect(await baris(20260905), isNotNull);
        final q = await antrean();
        expect(q, hasLength(1));
        expect(q.single.operation, SyncOperation.create);
      },
    );

    test(
      'I3 — payload yang diantre saat offline berisi field yang benar',
      () async {
        when(() => network.isConnected).thenAnswer((_) async => false);
        await repo.markToday();

        final q = await antrean();
        final data = jsonDecode(q.single.data) as Map<String, dynamic>;
        expect(data['dayKey'], 20260905);
        expect(data['markedAt'], isA<int>());
        expect(data['timezone'], isA<String>());
        expect(data['updatedAt'], isA<int>());
      },
    );

    test(
      'I4 — baris terhapus tepat di jendela readUnsyncedMarks→findMark '
      'tidak jadi didorong',
      () async {
        final racing = _LocalDenganRace(db);
        final repoRace = StreakRepositoryImpl(
          local: racing,
          remote: remote,
          network: network,
          auth: auth,
          clock: clock,
          epochDay: 20260901,
        );
        addTearDown(repoRace.dispose);

        await racing.insertMark(
          dayKey: 20260905,
          markedAt: DateTime.utc(2026, 9, 5, 3),
          timezone: 'WIB',
          viaClockCorrection: false,
        );

        // Jendela race: baris lenyap (mis. diurungkan) TEPAT sesudah daftar
        // "belum naik" dipegang loop dan SEBELUM baca-ulang findMark().
        racing.saatBacaBelumNaik = () async {
          await racing.deleteMark(20260905);
        };

        final naik = await repoRace.pushPendingMarks();

        expect(naik, 0, reason: 'baris sudah lenyap, tak ada yang sah');
        verifyNever(() => remote.saveMark(any()));
        expect(await baris(20260905), isNull);
      },
    );
  });

  group('TEMUAN R3 — Ronde Perbaikan 2', () {
    test(
      'delete SAH yang diantre TEPAT antara markSynced() dan purge fix2 '
      'harus SELAMAT, bukan ikut termakan',
      () async {
        final racing = _LocalDenganRaceMarkSynced(db);
        final repoRace = StreakRepositoryImpl(
          local: racing,
          remote: remote,
          network: network,
          auth: auth,
          clock: clock,
          epochDay: 20260901,
        );
        addTearDown(repoRace.dispose);

        when(() => network.isConnected).thenAnswer((_) async => false);
        await repoRace.markToday(); // create menunggu di antrean
        when(() => network.isConnected).thenAnswer((_) async => true);

        // Jendela race NYATA: markSynced() sukses (baris sudah isSynced di
        // DB), TAPI purge fix2 belum sempat jalan — dua panggilan DB
        // terpisah, bukan satu transaksi. User menekan Undo tepat di sini;
        // unmarkToday() jalan SAMPAI SELESAI dan mengantre delete yang SAH.
        racing.saatSesudahMarkSynced = () async {
          await repoRace.unmarkToday();
        };

        final naik = await repoRace.pushPendingMarks();

        expect(naik, 1, reason: 'push-nya sendiri tetap sukses');
        final q = await antrean();
        expect(
          q,
          hasLength(1),
          reason:
              'delete SAH dari unmarkToday() tak boleh dimakan purge fix2 '
              'yang tak berfilter operasi',
        );
        expect(q.single.operation, SyncOperation.delete);
        expect(q.single.collectionPath, path);
      },
    );
  });
}
