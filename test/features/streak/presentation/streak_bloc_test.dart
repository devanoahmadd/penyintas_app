import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:penyintas_app/core/error/failures.dart';
import 'package:penyintas_app/core/usecases/usecase.dart';
import 'package:penyintas_app/core/utils/app_clock.dart';
import 'package:penyintas_app/features/streak/domain/entities/streak_meta_values.dart';
import 'package:penyintas_app/features/streak/domain/entities/streak_snapshot.dart';
import 'package:penyintas_app/features/streak/domain/repositories/streak_repository.dart';
import 'package:penyintas_app/features/streak/domain/usecases/mark_today_no_spend_usecase.dart';
import 'package:penyintas_app/features/streak/domain/usecases/undo_today_no_spend_usecase.dart';
import 'package:penyintas_app/features/streak/domain/usecases/watch_streak_snapshot_usecase.dart';
import 'package:penyintas_app/features/streak/presentation/bloc/streak_bloc.dart';
import 'package:penyintas_app/features/streak/presentation/bloc/streak_event.dart';
import 'package:penyintas_app/features/streak/presentation/bloc/streak_state.dart';

class _MockWatch extends Mock implements WatchStreakSnapshotUseCase {}

class _MockMark extends Mock implements MarkTodayNoSpendUseCase {}

class _MockUndo extends Mock implements UndoTodayNoSpendUseCase {}

class _MockRepo extends Mock implements StreakRepository {}

class _FakeMeta extends Fake implements StreakMetaValues {}

StreakSnapshot snap({
  int streak = 0,
  int nextLastSeenDay = 20260905,
  bool anomaly = false,
  int? lastBreakDay,
  int brokenRun = 0,
  bool hasStarted = true,
}) => StreakSnapshot(
  hasStarted: hasStarted,
  activatedDay: 20260901,
  currentStreak: streak,
  longestRuas: streak,
  graceAvailable: 0,
  graceUsedDays: const {},
  todayStatus: DayStatus.pending,
  today: 20260905,
  nextLastSeenDay: nextLastSeenDay,
  clockAnomalyDetected: anomaly,
  lastBreakDay: lastBreakDay,
  brokenRunLength: brokenRun,
  markedDays: const {},
  markedDaysAll: const {},
  transactionDays: const {},
);

/// Aliran yang TIDAK PERNAH ditutup selama masih dilanggan — itulah sifat
/// `StreakRepositoryImpl.watchSnapshot()` yang ditiru di sini.
///
/// Yang TIDAK ditiru, supaya tidak menyesatkan: watchSnapshot() membuat
/// `StreamController` BARU tiap panggilan, tanpa seed, dan menutup dirinya
/// lewat `onCancel`. Yang berumur sepanjang repository singleton hanyalah
/// `_pemicu`, bukan aliran snapshot-nya.
///
/// Penting, bukan kosmetik: `Stream.value(...)` MENUTUP dirinya sendiri, jadi
/// `emit.onEach` selesai dan handler `StreakSubscribed` ikut selesai SEBELUM
/// `readMeta()` yang di-await di dalam `onData` sempat kembali. Emitter-nya
/// sudah `_isCompleted`, sehingga emisi `ready` tidak pernah mendarat dan
/// seluruh test akan menatap `loading` selamanya.
Stream<StreakSnapshot> aliran(List<StreakSnapshot> isi) {
  final c = StreamController<StreakSnapshot>();
  for (final s in isi) {
    c.add(s);
  }
  return c.stream;
}

void main() {
  setUpAll(() => registerFallbackValue(_FakeMeta()));

  late _MockWatch watch;
  late _MockMark mark;
  late _MockUndo undo;
  late _MockRepo repo;
  late FixedClock clock;
  var bootstrapDone = true;

  StreakBloc buat() => StreakBloc(
    watchSnapshot: watch,
    markToday: mark,
    undoToday: undo,
    repository: repo,
    clock: clock,
    isBootstrapDone: () => bootstrapDone,
    // Dipersingkat agar test S6 tidak menunggu 20 detik.
    restoringGrace: const Duration(milliseconds: 60),
  );

  /// Penyimpanan meta yang benar-benar mengingat — dibutuhkan tiap kali test
  /// memeriksa BERAPA KALI `saveMeta` dipanggil.
  void metaBerstatus({
    StreakMetaValues awal = StreakMetaValues.empty,
    Duration tunda = Duration.zero,
    Duration tundaSimpan = Duration.zero,
  }) {
    var tersimpan = awal;
    when(() => repo.readMeta()).thenAnswer((_) async {
      // Nilai difoto SAAT pembacaan DIMULAI, bukan saat ia selesai — itulah
      // semantik baca database yang sesungguhnya, dan itulah satu-satunya cara
      // jendela lost-update C1 bisa terbuka di test. Mock yang membaca
      // `tersimpan` sesudah penundaan diam-diam menyembunyikan bug-nya.
      final foto = tersimpan;
      if (tunda > Duration.zero) await Future<void>.delayed(tunda);
      return foto;
    });
    when(() => repo.saveMeta(any())).thenAnswer((inv) async {
      // Cermin sengaja ASIMETRIS terhadap `readMeta` di atas, dan asimetri
      // itulah yang benar: pembacaan MENGAMATI di awal, penulisan MENGIKAT
      // di akhir. Kalau `tersimpan` di-set sebelum penundaan, tulisan itu
      // seolah sudah komit padahal `await`-nya belum kembali — dan jendela
      // "reset lewat selagi saveMeta tertunda" tak akan pernah terbuka.
      if (tundaSimpan > Duration.zero) {
        await Future<void>.delayed(tundaSimpan);
      }
      tersimpan = inv.positionalArguments.first as StreakMetaValues;
    });
  }

  Future<void> tunggu(int ms) =>
      Future<void>.delayed(Duration(milliseconds: ms));

  setUp(() {
    watch = _MockWatch();
    mark = _MockMark();
    undo = _MockUndo();
    repo = _MockRepo();
    clock = FixedClock(DateTime(2026, 9, 5, 10));
    bootstrapDone = true;
    when(() => repo.readMeta()).thenAnswer((_) async => StreakMetaValues.empty);
    when(() => repo.saveMeta(any())).thenAnswer((_) async {});
    when(() => repo.requestRecompute()).thenReturn(null);
    when(() => repo.dispose()).thenReturn(null);
    when(() => mark(const NoParams())).thenAnswer((_) async => const Right(null));
    when(() => undo(const NoParams())).thenAnswer((_) async => const Right(null));
  });

  group('T18 — invarian tulis StreakMeta', () {
    blocTest<StreakBloc, StreakState>(
      'putaran kedua tanpa perubahan data TIDAK menulis StreakMeta',
      setUp: () {
        when(
          () => watch(),
        ).thenAnswer((_) => aliran([snap(streak: 3), snap(streak: 3)]));
        metaBerstatus();
      },
      build: buat,
      act: (b) => b.add(StreakSubscribed()),
      wait: const Duration(milliseconds: 50),
      verify: (_) {
        verify(() => repo.saveMeta(any())).called(1);
      },
    );
  });

  group('maxSeenDay hanya naik', () {
    blocTest<StreakBloc, StreakState>(
      'cabang koreksi jam menurunkan lastSeenDay tapi TIDAK maxSeenDay',
      setUp: () {
        when(() => repo.readMeta()).thenAnswer(
          (_) async => StreakMetaValues.empty.copyWith(
            lastSeenDay: 20261005,
            maxSeenDay: 20261005,
          ),
        );
        when(() => watch()).thenAnswer(
          (_) => aliran([
            snap(streak: 1, nextLastSeenDay: 20260905, anomaly: true),
          ]),
        );
      },
      build: buat,
      act: (b) => b.add(StreakSubscribed()),
      wait: const Duration(milliseconds: 50),
      verify: (_) {
        final ditulis =
            verify(() => repo.saveMeta(captureAny())).captured.last
                as StreakMetaValues;
        expect(
          ditulis.lastSeenDay,
          20260905,
          reason: 'turun — itu yang menutup jebakan',
        );
        expect(ditulis.maxSeenDay, 20261005, reason: 'TIDAK PERNAH turun');
      },
    );

    blocTest<StreakBloc, StreakState>(
      'anomali dicatat sekali saat transisi — snapshot anomali KEDUA tidak '
      'menaikkannya lagi',
      setUp: () {
        metaBerstatus(
          awal: StreakMetaValues.empty.copyWith(
            lastSeenDay: 20261005,
            maxSeenDay: 20261005,
          ),
        );
        // DUA snapshot anomali beruntun: satu snapshot saja tidak pernah bisa
        // membuktikan kata "transisi" di judul test ini.
        when(() => watch()).thenAnswer(
          (_) => aliran([
            snap(streak: 1, nextLastSeenDay: 20260905, anomaly: true),
            snap(streak: 1, nextLastSeenDay: 20260905, anomaly: true),
          ]),
        );
      },
      build: buat,
      act: (b) => b.add(StreakSubscribed()),
      wait: const Duration(milliseconds: 50),
      verify: (_) {
        final ditulis =
            verify(() => repo.saveMeta(captureAny())).captured.last
                as StreakMetaValues;
        expect(ditulis.clockAnomalyCount, 1);
      },
    );
  });

  group('T24 — riwayat belum tiba ≠ streak nol', () {
    blocTest<StreakBloc, StreakState>(
      'restoring selama bootstrap belum selesai DAN belum ada hari aman',
      setUp: () {
        bootstrapDone = false;
        when(() => watch()).thenAnswer((_) => aliran([snap(hasStarted: false)]));
      },
      build: buat,
      act: (b) => b.add(StreakSubscribed()),
      wait: const Duration(milliseconds: 40),
      expect: () => [
        isA<StreakState>().having(
          (s) => s.status,
          'status',
          StreakStatus.loading,
        ),
        isA<StreakState>().having(
          (s) => s.status,
          'status',
          StreakStatus.restoring,
        ),
      ],
    );

    blocTest<StreakBloc, StreakState>(
      'user baru yang bootstrap-nya SUDAH selesai langsung ready, bukan restoring',
      setUp: () {
        bootstrapDone = true;
        when(() => watch()).thenAnswer((_) => aliran([snap(hasStarted: false)]));
      },
      build: buat,
      act: (b) => b.add(StreakSubscribed()),
      wait: const Duration(milliseconds: 40),
      verify: (b) => expect(b.state.status, StreakStatus.ready),
    );

    blocTest<StreakBloc, StreakState>(
      'T38 — restoring PUNYA BATAS: luruh jadi ready walau bootstrap tak '
      'kunjung selesai',
      setUp: () {
        bootstrapDone = false;
        when(() => watch()).thenAnswer((_) => aliran([snap(hasStarted: false)]));
      },
      build: buat,
      act: (b) => b.add(StreakSubscribed()),
      wait: const Duration(milliseconds: 200), // > restoringGrace 60 ms
      verify: (b) => expect(
        b.state.status,
        StreakStatus.ready,
        reason: 'empty state yang jujur mengalahkan skeleton abadi',
      ),
    );
  });

  group('T45 — resetForNewSession melepaskan jaring pengaman (D-16)', () {
    blocTest<StreakBloc, StreakState>(
      'akun berikutnya dalam sesi proses yang sama tetap mendapat restoring, '
      'bukan langsung ready karena akun SEBELUMNYA pernah menghabiskan grace',
      setUp: () {
        bootstrapDone = false;
        when(() => watch()).thenAnswer((_) => aliran([snap(hasStarted: false)]));
      },
      build: buat,
      act: (b) async {
        b.add(StreakSubscribed());
        await Future<void>.delayed(const Duration(milliseconds: 200));
        expect(b.state.status, StreakStatus.ready);

        b.resetForNewSession();

        b.add(StreakSubscribed());
      },
      wait: const Duration(milliseconds: 30), // << restoringGrace 60 ms
      verify: (b) => expect(
        b.state.status,
        StreakStatus.restoring,
        reason: 'jaring pengaman T24/S6 wajib berlaku lagi untuk akun '
            'berikutnya, bukan cuma sekali seumur proses',
      ),
    );
  });

  group('T37 — berlangganan ulang tidak mengedipkan angka', () {
    blocTest<StreakBloc, StreakState>(
      'StreakSubscribed kedua SESUDAH ready tidak mengembalikan status ke loading',
      setUp: () {
        when(() => watch()).thenAnswer((_) => aliran([snap(streak: 5)]));
        metaBerstatus();
      },
      build: buat,
      act: (b) async {
        b.add(StreakSubscribed());
        await Future<void>.delayed(const Duration(milliseconds: 30));
        b.add(StreakSubscribed());
      },
      wait: const Duration(milliseconds: 60),
      expect: () => [
        isA<StreakState>().having(
          (s) => s.status,
          'status',
          StreakStatus.loading,
        ),
        isA<StreakState>().having((s) => s.status, 'status', StreakStatus.ready),
      ],
      // Persis dua state. Emisi `loading` kedua berarti tile berkedip dari
      // angka nyata ke "Mulai hari ini" tiap kali user membuka dashboard.
    );

    blocTest<StreakBloc, StreakState>(
      'StreakSubscribed kedua saat serapan masih berjalan tetap berakhir ready',
      setUp: () {
        when(() => watch()).thenAnswer((_) => aliran([snap(streak: 5)]));
        // Ditunda supaya pembatalan restartable() mendarat TEPAT saat serapan
        // masih menunggu.
        when(() => repo.readMeta()).thenAnswer((_) async {
          await Future<void>.delayed(const Duration(milliseconds: 20));
          return StreakMetaValues.empty;
        });
      },
      build: buat,
      act: (b) async {
        b.add(StreakSubscribed());
        await Future<void>.delayed(const Duration(milliseconds: 10));
        b.add(StreakSubscribed());
      },
      wait: const Duration(milliseconds: 150),
      verify: (b) => expect(b.state.status, StreakStatus.ready),
    );
  });

  group('perayaan ruas', () {
    blocTest<StreakBloc, StreakState>(
      'ruas 3 tercapai → pendingCelebration terisi; StreakMilestoneShown '
      'menyimpannya dan mengosongkan slot',
      setUp: () {
        when(() => watch()).thenAnswer((_) => aliran([snap(streak: 3)]));
        metaBerstatus();
      },
      build: buat,
      act: (b) async {
        b.add(StreakSubscribed());
        await Future<void>.delayed(const Duration(milliseconds: 30));
        expect(b.state.pendingCelebration, 3);
        b.add(StreakMilestoneShown(3));
      },
      wait: const Duration(milliseconds: 60),
      verify: (b) {
        expect(b.state.pendingCelebration, isNull);
        final ditulis =
            verify(() => repo.saveMeta(captureAny())).captured.last
                as StreakMetaValues;
        expect(ditulis.lastCelebratedRuas, 3);
      },
    );
  });

  group('T22 — momen ruas putus', () {
    blocTest<StreakBloc, StreakState>(
      'ruas 40 putus → unacknowledgedBreakRun 40; sesudah diakui jadi null',
      setUp: () {
        metaBerstatus();
        when(() => watch()).thenAnswer(
          (_) =>
              aliran([snap(streak: 0, lastBreakDay: 20260904, brokenRun: 40)]),
        );
      },
      build: buat,
      act: (b) async {
        b.add(StreakSubscribed());
        await Future<void>.delayed(const Duration(milliseconds: 30));
        expect(
          b.state.unacknowledgedBreakRun,
          40,
          reason: 'BUKAN 0 — yang disebut adalah panjang ruas yang dicapai',
        );
        b.add(StreakBreakAcknowledged());
      },
      wait: const Duration(milliseconds: 60),
      verify: (b) {
        expect(b.state.unacknowledgedBreakRun, isNull);
        final ditulis =
            verify(() => repo.saveMeta(captureAny())).captured.last
                as StreakMetaValues;
        expect(
          ditulis.acknowledgedBreakDay,
          20260904,
          reason: 'tanpa persistensi, banner hidup lagi di cold start '
              'berikutnya walau user sudah menutupnya',
        );
      },
    );
  });

  group('galat', () {
    late StreamController<StreakSnapshot> kanal;

    blocTest<StreakBloc, StreakState>(
      'M6 — galat SESUDAH snapshot mendarat: angka lama dipertahankan, tidak '
      'diganti nol',
      setUp: () {
        kanal = StreamController<StreakSnapshot>();
        kanal.add(snap(streak: 7));
        when(() => watch()).thenAnswer((_) => kanal.stream);
        metaBerstatus();
      },
      build: buat,
      act: (b) async {
        b.add(StreakSubscribed());
        await tunggu(40);
        expect(b.state.snapshot, isNotNull);
        kanal.addError(Exception('putus'));
      },
      wait: const Duration(milliseconds: 40),
      verify: (b) {
        expect(b.state.status, StreakStatus.failure);
        expect(
          b.state.snapshot?.currentStreak,
          7,
          reason: 'inilah yang dijanjikan judulnya — angka terakhir bertahan',
        );
      },
    );

    blocTest<StreakBloc, StreakState>(
      'error di stream snapshot → status failure, snapshot lama TIDAK diganti '
      'angka nol',
      setUp: () {
        when(
          () => watch(),
        ).thenAnswer((_) => Stream<StreakSnapshot>.error(Exception('putus')));
      },
      build: buat,
      act: (b) => b.add(StreakSubscribed()),
      wait: const Duration(milliseconds: 50),
      verify: (b) {
        expect(b.state.status, StreakStatus.failure);
        expect(b.state.snapshot, isNull);
      },
    );
  });

  group('C1 — tulisan StreakMeta tidak saling menimpa', () {
    late StreamController<StreakSnapshot> kanal;

    blocTest<StreakBloc, StreakState>(
      'StreakMilestoneShown yang bersaing dengan serapan snapshot tidak hilang '
      'tertimpa meta basi',
      setUp: () {
        kanal = StreamController<StreakSnapshot>();
        kanal.add(snap(streak: 3));
        when(() => watch()).thenAnswer((_) => kanal.stream);
        metaBerstatus(tunda: const Duration(milliseconds: 30));
      },
      build: buat,
      act: (b) async {
        b.add(StreakSubscribed());
        await tunggu(50);
        expect(b.state.pendingCelebration, 3);

        // Pembacaan milestone berangkat lebih dulu...
        b.add(StreakMilestoneShown(3));
        await tunggu(10);
        // ...lalu serapan snapshot kedua membaca meta yang MASIH basi. Tanpa
        // antrean bersama, tulisannya mendarat belakangan dan mengembalikan
        // lastCelebratedRuas ke 0 — toast ruas 3 lalu muncul untuk kedua
        // kalinya.
        kanal.add(snap(streak: 3, nextLastSeenDay: 20260906));
      },
      wait: const Duration(milliseconds: 150),
      verify: (_) {
        final ditulis =
            verify(() => repo.saveMeta(captureAny())).captured.last
                as StreakMetaValues;
        expect(
          ditulis.lastCelebratedRuas,
          3,
          reason: 'perayaan yang sudah dikonsumsi tidak boleh hilang',
        );
        expect(
          ditulis.lastSeenDay,
          20260906,
          reason: 'serapan snapshot juga tidak boleh hilang',
        );
      },
    );
  });

  group('C2 — reset sesi membuang data akun lama', () {
    blocTest<StreakBloc, StreakState>(
      'resetForNewSession mengosongkan state DAN menghidupkan lagi gerbang '
      'loading untuk akun berikutnya',
      setUp: () {
        when(() => watch()).thenAnswer((_) => aliran([snap(streak: 5)]));
        metaBerstatus();
      },
      build: buat,
      act: (b) async {
        b.add(StreakSubscribed());
        await tunggu(30);
        expect(b.state.snapshot, isNotNull);
        expect(b.state.pendingCelebration, 3);

        b.resetForNewSession();
        await tunggu(20);
        expect(
          b.state.snapshot,
          isNull,
          reason: 'angka streak akun sebelumnya tidak boleh menyeberang',
        );
        expect(
          b.state.pendingCelebration,
          isNull,
          reason: 'perayaan akun sebelumnya tidak boleh meledak di sesi ini',
        );

        b.add(StreakSubscribed());
      },
      wait: const Duration(milliseconds: 60),
      expect: () => [
        isA<StreakState>().having(
          (s) => s.status,
          'status',
          StreakStatus.loading,
        ),
        isA<StreakState>().having((s) => s.status, 'status', StreakStatus.ready),
        isA<StreakState>().having(
          (s) => s.status,
          'status',
          StreakStatus.initial,
        ),
        // Gerbang `loading` HIDUP LAGI — inilah yang mati kalau reset hanya
        // menyentuh field privat: `state.snapshot != null` menekannya.
        isA<StreakState>().having(
          (s) => s.status,
          'status',
          StreakStatus.loading,
        ),
        isA<StreakState>().having((s) => s.status, 'status', StreakStatus.ready),
      ],
    );
  });

  group('I1 — galat tidak menetap di state', () {
    late StreamController<StreakSnapshot> kanal;

    blocTest<StreakBloc, StreakState>(
      'failure dibersihkan oleh snapshot segar DAN oleh mark yang berhasil',
      setUp: () {
        kanal = StreamController<StreakSnapshot>();
        kanal.add(snap(streak: 1));
        when(() => watch()).thenAnswer((_) => kanal.stream);
        metaBerstatus();
        when(
          () => mark(const NoParams()),
        ).thenAnswer((_) async => const Left(CacheFailure()));
      },
      build: buat,
      act: (b) async {
        b.add(StreakSubscribed());
        await tunggu(30);

        b.add(StreakTodayMarked());
        await tunggu(20);
        expect(b.state.failure, isNotNull);

        kanal.add(snap(streak: 2));
        await tunggu(30);
        expect(
          b.state.failure,
          isNull,
          reason: 'snapshot segar mengakhiri galat lama — `ready` + `failure` '
              'sekaligus adalah kombinasi tanpa arti',
        );

        b.add(StreakTodayMarked());
        await tunggu(20);
        expect(b.state.failure, isNotNull);

        when(
          () => mark(const NoParams()),
        ).thenAnswer((_) async => const Right(null));
        b.add(StreakTodayMarked());
      },
      wait: const Duration(milliseconds: 40),
      verify: (b) => expect(
        b.state.failure,
        isNull,
        reason: 'mark yang berhasil mengakhiri galat percobaan sebelumnya',
      ),
    );
  });

  group('I2 — galat serapan tidak ditelan diam-diam', () {
    blocTest<StreakBloc, StreakState>(
      'readMeta melempar → disalurkan ke Bloc.onError dan jadi status failure, '
      'bukan skeleton abadi',
      setUp: () {
        when(() => watch()).thenAnswer((_) => aliran([snap(streak: 1)]));
        when(() => repo.readMeta()).thenThrow(Exception('drift mati'));
      },
      build: buat,
      act: (b) => b.add(StreakSubscribed()),
      wait: const Duration(milliseconds: 50),
      errors: () => [isA<Exception>()],
      verify: (b) => expect(b.state.status, StreakStatus.failure),
    );
  });

  group('I3 — event yang sebelumnya nol test', () {
    blocTest<StreakBloc, StreakState>(
      'StreakRefreshed memaksa repository menghitung ulang — ia pelepas normal '
      'state restoring',
      setUp: () {
        when(() => watch()).thenAnswer((_) => aliran([]));
      },
      build: buat,
      act: (b) => b.add(StreakRefreshed()),
      wait: const Duration(milliseconds: 30),
      verify: (_) => verify(() => repo.requestRecompute()).called(1),
    );

    blocTest<StreakBloc, StreakState>(
      'StreakTodayMarkUndone memanggil usecase dan menaruh galatnya di state',
      setUp: () {
        when(() => watch()).thenAnswer((_) => aliran([]));
        when(
          () => undo(const NoParams()),
        ).thenAnswer((_) async => const Left(CacheFailure()));
      },
      build: buat,
      act: (b) => b.add(StreakTodayMarkUndone()),
      wait: const Duration(milliseconds: 30),
      verify: (b) {
        verify(() => undo(const NoParams())).called(1);
        expect(b.state.failure, isA<CacheFailure>());
      },
    );
  });

  group('guard tap-ganda', () {
    blocTest<StreakBloc, StreakState>(
      'dua StreakTodayMarked beruntun hanya memanggil usecase sekali',
      setUp: () {
        when(() => watch()).thenAnswer((_) => aliran([]));
        when(() => mark(const NoParams())).thenAnswer((_) async {
          await Future<void>.delayed(const Duration(milliseconds: 40));
          return const Right(null);
        });
      },
      build: buat,
      act: (b) {
        b.add(StreakTodayMarked());
        b.add(StreakTodayMarked());
      },
      wait: const Duration(milliseconds: 120),
      verify: (_) => verify(() => mark(const NoParams())).called(1),
    );
  });

  group('B1 — kepemilikan lifecycle repository', () {
    test('close() TIDAK menutup StreakRepository yang dipakai bersama', () async {
      when(() => watch()).thenAnswer((_) => aliran([]));
      final b = buat();
      await b.close();
      verifyNever(() => repo.dispose());
    });
  });

  group('IB1 — reset sesi membatalkan serapan dari langganan lama', () {
    late StreamController<StreakSnapshot> kanal;

    blocTest<StreakBloc, StreakState>(
      'snapshot yang tiba dari langganan SEBELUM reset tidak menimpa balik '
      'StreakState() kosong sesudahnya',
      setUp: () {
        // StreamController manual, BUKAN `aliran(...)` — kanal ini harus
        // tetap bisa menerima emisi SESUDAH reset, bukan diisi di muka.
        kanal = StreamController<StreakSnapshot>();
        when(() => watch()).thenAnswer((_) => kanal.stream);
        metaBerstatus();
      },
      build: buat,
      act: (b) async {
        b.add(StreakSubscribed());
        await tunggu(
          20,
        ); // langganan sudah terpasang, belum ada snapshot apa pun

        b.resetForNewSession();
        await tunggu(10);
        expect(b.state.snapshot, isNull);

        // Langganan LAMA (kanal) TIDAK dibatalkan oleh StreakSessionReset —
        // restartable() hanya membatalkan emitter lama saat StreakSubscribed
        // BARU datang. Pancarkan satu snapshot susulan, meniru notifikasi
        // Drift yang dipicu clearAllLocalData() saat logout.
        kanal.add(snap(streak: 9));
      },
      wait: const Duration(milliseconds: 60),
      verify: (b) {
        expect(
          b.state.snapshot,
          isNull,
          reason:
              'serapan dari langganan sesi LAMA tidak boleh menimpa balik '
              'StreakState() kosong dengan data akun lama',
        );
      },
    );
  });

  group('IB2 — cermin C1 untuk jalur acknowledgedBreakDay', () {
    late StreamController<StreakSnapshot> kanal;

    blocTest<StreakBloc, StreakState>(
      'StreakBreakAcknowledged yang bersaing dengan serapan snapshot tidak '
      'hilang tertimpa meta basi',
      setUp: () {
        kanal = StreamController<StreakSnapshot>();
        kanal.add(snap(streak: 0, lastBreakDay: 20260904, brokenRun: 40));
        when(() => watch()).thenAnswer((_) => kanal.stream);
        metaBerstatus(tunda: const Duration(milliseconds: 30));
      },
      build: buat,
      act: (b) async {
        b.add(StreakSubscribed());
        await tunggu(50);
        expect(b.state.unacknowledgedBreakRun, 40);

        // Pengakuan banner putus berangkat lebih dulu...
        b.add(StreakBreakAcknowledged());
        await tunggu(10);
        // ...lalu serapan snapshot kedua membaca meta yang MASIH basi. Tanpa
        // antrean bersama, tulisannya mendarat belakangan dan mengembalikan
        // acknowledgedBreakDay ke 0 — banner "ruas putus" hidup lagi setelah
        // ditutup.
        kanal.add(
          snap(
            streak: 0,
            lastBreakDay: 20260904,
            brokenRun: 40,
            nextLastSeenDay: 20260906,
          ),
        );
      },
      wait: const Duration(milliseconds: 150),
      verify: (_) {
        final ditulis =
            verify(() => repo.saveMeta(captureAny())).captured.last
                as StreakMetaValues;
        expect(
          ditulis.acknowledgedBreakDay,
          20260904,
          reason: 'pengakuan yang sudah dikonsumsi tidak boleh hilang',
        );
        expect(
          ditulis.lastSeenDay,
          20260906,
          reason: 'serapan snapshot juga tidak boleh hilang',
        );
      },
    );
  });

  group('IB1 — tiap penjaga generasi terkunci sendiri-sendiri', () {
    late StreamController<StreakSnapshot> kanal;

    // Grup IB1 sebelumnya hanya membuktikan "ada SETIDAKNYA satu penjaga":
    // resep S9 membuang keduanya sekaligus. Dibuang satu per satu, keduanya
    // hijau — penjaga yang tersisa menutupi gejala milik penjaga yang hilang.
    // Dua test di bawah memerahkan penjaga yang BERBEDA, lewat akibat yang
    // berbeda pula: yang satu tulisan meta, yang lain emisi state.

    blocTest<StreakBloc, StreakState>(
      'reset selagi readMeta tertunda → meta akun lama TIDAK ditulis ke '
      'penyimpanan akun baru',
      setUp: () {
        kanal = StreamController<StreakSnapshot>();
        kanal.add(snap(streak: 7));
        when(() => watch()).thenAnswer((_) => kanal.stream);
        metaBerstatus(tunda: const Duration(milliseconds: 40));
      },
      build: buat,
      act: (b) async {
        b.add(StreakSubscribed());
        // Reset mendarat SELAGI readMeta masih tertunda. Penjaga (b) tidak
        // bisa menolong di sini: ia berdiri SESUDAH saveMeta, jadi tulisannya
        // sudah terlanjur mendarat saat ia sempat memeriksa apa pun.
        await tunggu(15);
        b.resetForNewSession();
      },
      wait: const Duration(milliseconds: 120),
      verify: (_) {
        verifyNever(() => repo.saveMeta(any()));
      },
    );

    blocTest<StreakBloc, StreakState>(
      'reset selagi saveMeta tertunda → state akun lama TIDAK di-emit '
      'sesudahnya',
      setUp: () {
        kanal = StreamController<StreakSnapshot>();
        kanal.add(snap(streak: 7));
        when(() => watch()).thenAnswer((_) => kanal.stream);
        metaBerstatus(tundaSimpan: const Duration(milliseconds: 40));
      },
      build: buat,
      act: (b) async {
        b.add(StreakSubscribed());
        // Kali ini readMeta lewat seketika, jadi penjaga (a) SUDAH meloloskan
        // serapan ini dengan benar — generasinya memang masih cocok saat itu.
        // Reset baru mendarat sesudahnya, selagi saveMeta tertunda. Hanya
        // penjaga (b) yang berdiri di antara titik itu dan emit.
        await tunggu(15);
        b.resetForNewSession();
      },
      wait: const Duration(milliseconds: 120),
      verify: (b) {
        expect(
          b.state.snapshot,
          isNull,
          reason:
              'serapan yang generasinya kedaluwarsa selagi saveMeta tertunda '
              'tidak boleh mendarat di state sesi baru',
        );
      },
    );
  });
}
