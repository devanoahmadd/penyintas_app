import 'package:drift/drift.dart' hide isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:penyintas_app/core/database/app_database.dart';
import 'package:penyintas_app/core/network/network_info.dart';
import 'package:penyintas_app/core/sync/sync_dispatcher.dart' show toFirestoreOp;
import 'package:penyintas_app/core/utils/app_clock.dart';
import 'package:penyintas_app/features/challenge/domain/entities/challenge_status.dart';
import 'package:penyintas_app/features/challenge/data/datasources/challenge_local_datasource.dart';
import 'package:penyintas_app/features/challenge/data/datasources/challenge_remote_datasource.dart';
import 'package:penyintas_app/features/challenge/data/models/challenge_model.dart';
import 'package:penyintas_app/features/challenge/data/repositories/challenge_repository_impl.dart';

class _MockAuth extends Mock implements FirebaseAuth {}
class _MockUser extends Mock implements User {}
class _MockNetwork extends Mock implements NetworkInfo {}
class _MockRemote extends Mock implements ChallengeRemoteDatasource {}

/// Baris `active` minimal — dipakai S-A untuk menyimulasikan minggu lampau
/// yang belum dievaluasi.
Future<void> _tulisBarisActive(AppDatabase db, int weekKey) =>
    db.into(db.weeklyChallenges).insert(
          WeeklyChallengesCompanion.insert(
            weekKey: Value(weekKey),
            category: const Value('food'),
            targetAmount: const Value(115000),
            baselineAmount: const Value(140000),
            status: ChallengeStatus.active,
            timezone: 'WIB',
            createdAt: DateTime.utc(2026, 8, 24),
            updatedAt: DateTime.utc(2026, 8, 24),
          ),
        );

/// Baris `achieved` yang sudah tuntas — dipakai U50 untuk mengecek
/// `resultSeenAt` lokal bertahan lewat tarikan.
Future<void> _tulisBarisAchieved(
  AppDatabase db,
  int weekKey, {
  DateTime? resultSeenAt,
}) =>
    db.into(db.weeklyChallenges).insert(
          WeeklyChallengesCompanion.insert(
            weekKey: Value(weekKey),
            category: const Value('food'),
            targetAmount: const Value(115000),
            baselineAmount: const Value(140000),
            status: ChallengeStatus.achieved,
            finalSpent: const Value(100000),
            timezone: 'WIB',
            createdAt: DateTime.utc(2026, 8, 31),
            updatedAt: DateTime.utc(2026, 9, 1),
            resultSeenAt: Value(resultSeenAt),
          ),
        );

void main() {
  late AppDatabase db;
  late ChallengeLocalDatasource local;
  late _MockAuth auth;
  late _MockNetwork network;
  late _MockRemote remote;
  late ChallengeRepositoryImpl repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    local = ChallengeLocalDatasourceImpl(db);
    auth = _MockAuth();
    network = _MockNetwork();
    remote = _MockRemote();

    final user = _MockUser();
    when(() => user.uid).thenReturn('uid-nyata-123');
    when(() => auth.currentUser).thenReturn(user);

    repo = ChallengeRepositoryImpl(
      local: local, remote: remote, network: network,
      auth: auth, clock: FixedClock(DateTime(2026, 9, 7, 9)),
    );
  });

  setUpAll(() {
    // `remote.upsertChallenge(any(), any())` butuh fallback untuk
    // `ChallengeModel` — bukan tipe primitif yang sudah dikenal mocktail.
    registerFallbackValue(ChallengeModel(
      weekKey: 0, category: null, targetAmount: null, baselineAmount: null,
      status: ChallengeStatus.active, finalSpent: null, timezone: '',
      createdAt: DateTime.utc(2026), updatedAt: DateTime.utc(2026),
    ));
  });

  tearDown(() async => db.close());

  test('U47 · path berisi uid NYATA dan LOLOS penjaga dispatcher', () async {
    // Pelajaran #252 punya DUA sisi. Sisi yang Rev 1 ingat: uid harus
    // tersubstitusi. Sisi yang Rev 1 lupa: path harus berbentuk DOC PATH PENUH,
    // karena `sync_dispatcher.dart:15-23` menolak segmen ganjil dan
    // `sync_service.dart:88` menghapus item ber-ArgumentError seketika.
    // Karena itu assert-nya memanggil penjaganya, bukan mencocokkan string.
    when(() => network.isConnected).thenAnswer((_) async => false);

    await repo.createChallenge(
      weekKey: 20260907, category: 'food',
      targetAmount: 115000, baselineAmount: 140000,
    );

    final antrian = await db.select(db.syncQueue).getSingle();
    expect(antrian.collectionPath, isNot(contains('{uid}')));
    expect(() => toFirestoreOp(antrian), returnsNormally);
    expect(toFirestoreOp(antrian).path, 'users/uid-nyata-123/challenges/20260907');
  });

  test('S-A · dua minggu diantre offline → KEDUANYA bertahan', () async {
    // Langkah 1 Task 10 menutup SEMUA minggu lampau yang masih active. Dengan
    // purge berbutir koleksi (Rev 1), minggu pertama terbuang saat minggu kedua
    // diproses — dan hilangnya senyap.
    when(() => network.isConnected).thenAnswer((_) async => false);
    await _tulisBarisActive(db, 20260824);
    await _tulisBarisActive(db, 20260831);

    await repo.resolveWeek(
        weekKey: 20260824, status: ChallengeStatus.achieved, finalSpent: 10000);
    await repo.resolveWeek(
        weekKey: 20260831, status: ChallengeStatus.missed, finalSpent: 90000);

    final antrian = await db.select(db.syncQueue).get();
    expect(antrian.map((i) => i.collectionPath), containsAll(<String>[
      'users/uid-nyata-123/challenges/20260824',
      'users/uid-nyata-123/challenges/20260831',
    ]));
  });

  test('M8 · resolveWeek pada weekKey yang TIDAK ada → Left, bukan crash', () async {
    // Companion `resolveWeek` parsial (tanpa timezone/createdAt). Lewat
    // insertOnConflictUpdate ia akan mencoba INSERT dan melanggar NOT NULL.
    when(() => network.isConnected).thenAnswer((_) async => false);

    final hasil = await repo.resolveWeek(
        weekKey: 20260601, status: ChallengeStatus.missed, finalSpent: 0);

    expect(hasil.isLeft(), isTrue);
    expect(await db.select(db.syncQueue).get(), isEmpty);
  });

  // Ditambahkan saat verifikasi sabotase Langkah 8 butir 9. Skenario S-A asli
  // (dua weekKey BERBEDA) tak pernah menyentuh purge salah-path: purge
  // ber-`.equals()` yang ditarget path koleksi tak pernah cocok dengan
  // collectionPath baris mana pun, jadi jadi no-op tanpa efek terlihat.
  // Tujuan purge (§ komentar `_kirim`) adalah mencegah satu weekKey ditulis
  // BERKALI-KALI menumpuk beberapa payload di antrian — jadi kasus yang
  // benar-benar menguji purge adalah weekKey yang SAMA dikirim dua kali.
  test('_kirim · purge membuang antrian LAMA weekKey yang sama sebelum kirim baru',
      () async {
    when(() => network.isConnected).thenAnswer((_) async => false);

    await repo.createChallenge(
      weekKey: 20260907, category: 'food',
      targetAmount: 115000, baselineAmount: 140000,
    );
    await repo.resolveWeek(
        weekKey: 20260907, status: ChallengeStatus.achieved, finalSpent: 100000);

    final antrian = await db.select(db.syncQueue).get();
    expect(
      antrian.where((i) =>
          i.collectionPath == 'users/uid-nyata-123/challenges/20260907'),
      hasLength(1),
      reason: 'purge yang salah target meninggalkan payload createChallenge '
          'LAMA menumpuk bersama payload resolveWeek yang baru',
    );
  });

  // Temuan review Task 7: baris yang sudah isSynced=true lalu DIUBAH lewat
  // _ubahDanKirim (resolveWeek/changeCategory) harus menjatuhkan isSynced,
  // supaya pushPendingChallenges() — jaring pengaman kalau antrian sync-nya
  // sendiri hilang — benar-benar menjemputnya.
  test('resolveWeek offline menjatuhkan isSynced — baris terjemput '
      'pushPendingChallenges (jaring pengaman)', () async {
    // Baris awal SUDAH tersinkron (mis. dibuat saat online sebelumnya).
    await db.into(db.weeklyChallenges).insertOnConflictUpdate(
          WeeklyChallengesCompanion.insert(
            weekKey: const Value(20260907),
            category: const Value('food'),
            targetAmount: const Value(115000),
            baselineAmount: const Value(140000),
            status: ChallengeStatus.active,
            timezone: 'WIB',
            createdAt: DateTime.utc(2026, 9, 7),
            updatedAt: DateTime.utc(2026, 9, 7),
            isSynced: const Value(true),
          ),
        );

    when(() => network.isConnected).thenAnswer((_) async => false);
    final hasil = await repo.resolveWeek(
        weekKey: 20260907, status: ChallengeStatus.achieved, finalSpent: 90000);
    expect(hasil.isRight(), isTrue);

    // isSynced dijatuhkan meski antrian sync ADA — jaring pengaman push
    // harus tetap bisa menjemputnya seandainya antrian itu sendiri hilang.
    expect((await local.findWeek(20260907))!.isSynced, isFalse);
    expect((await local.pendingRows()).map((r) => r.weekKey), contains(20260907));

    // Buktikan jaring pengaman benar-benar bekerja: jaringan pulih, push
    // dipanggil LANGSUNG (bukan lewat antrian) — baris harus terjemput dan
    // ditandai synced kembali.
    when(() => network.isConnected).thenAnswer((_) async => true);
    when(() => remote.upsertChallenge(any(), any())).thenAnswer((_) async {});
    await repo.pushPendingChallenges();

    expect((await local.findWeek(20260907))!.isSynced, isTrue);
  });

  // Kewajiban cakupan dari review Task 6: `pendingRows` belum punya test yang
  // benar-benar memanggilnya lewat jalur publik — hanya menyiapkan datanya
  // saja tidak cukup, ia harus ditarik lewat `pushPendingChallenges`.
  test('pushPendingChallenges · mendorong baris pending lewat pendingRows lalu '
      'menandai synced', () async {
    await _tulisBarisActive(db, 20260907); // isSynced default false = pending
    when(() => network.isConnected).thenAnswer((_) async => true);
    when(() => remote.upsertChallenge(any(), any())).thenAnswer((_) async {});

    final hasil = await repo.pushPendingChallenges();

    expect(hasil.isRight(), isTrue);
    verify(() => remote.upsertChallenge('uid-nyata-123', any())).called(1);
    expect((await local.findWeek(20260907))!.isSynced, isTrue);
  });

  test('U50 · tarikan MEMPERTAHANKAN resultSeenAt lokal', () async {
    await _tulisBarisAchieved(db, 20260831, resultSeenAt: DateTime.utc(2026, 9, 1));
    when(() => remote.fetchChallenges(any(), any())).thenAnswer((_) async => [
          ChallengeModel(
            weekKey: 20260831, category: 'food', targetAmount: 115000,
            baselineAmount: 140000, status: ChallengeStatus.achieved,
            finalSpent: 100000, timezone: 'WIB',
            createdAt: DateTime.utc(2026, 8, 31),
            updatedAt: DateTime.utc(2026, 9, 5),
          ),
        ]);

    await repo.syncChallengesFromRemote();

    expect((await local.findWeek(20260831))!.resultSeenAt, isNotNull);
  });
}
