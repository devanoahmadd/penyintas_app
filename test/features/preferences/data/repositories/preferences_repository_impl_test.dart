import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:penyintas_app/features/preferences/data/datasources/preferences_local_datasource.dart';
import 'package:penyintas_app/features/preferences/data/datasources/preferences_remote_datasource.dart';
import 'package:penyintas_app/features/preferences/data/models/preferences_model.dart';
import 'package:penyintas_app/features/preferences/data/repositories/preferences_repository_impl.dart';
import 'package:penyintas_app/features/preferences/domain/entities/preferences_entity.dart';

class _MockLocal extends Mock implements PreferencesLocalDatasource {}

class _MockRemote extends Mock implements PreferencesRemoteDatasource {}

class _FakePrefs extends Fake implements PreferencesEntity {}

void main() {
  late _MockLocal local;
  late _MockRemote remote;
  late PreferencesRepositoryImpl repo;

  setUpAll(() => registerFallbackValue(_FakePrefs()));
  setUp(() {
    local = _MockLocal();
    remote = _MockRemote();
    repo = PreferencesRepositoryImpl(local: local, remote: remote);
    // T-1 default stubs (override per-test bila perlu).
    when(() => local.markMirrored(any())).thenAnswer((_) async {});
    when(() => local.hasPendingMirror()).thenAnswer((_) async => true);
  });

  test('read(): local ada → kembalikan local', () async {
    when(() => local.read()).thenAnswer(
      (_) async =>
          PreferencesEntity.defaults.copyWith(timezone: 'Europe/Moscow'),
    );
    final got = await repo.read();
    expect(got.timezone, 'Europe/Moscow');
  });

  test('read(): local kosong → defaults', () async {
    when(() => local.read()).thenAnswer((_) async => null);
    final got = await repo.read();
    expect(got, PreferencesEntity.defaults);
  });

  test(
    'save(): tulis local LALU mirror LALU markMirrored, return Right(unit)',
    () async {
      when(() => local.write(any())).thenAnswer((_) async {});
      when(() => remote.mirror(any())).thenAnswer((_) async {});
      final r = await repo.save(PreferencesEntity.defaults);
      expect(r, const Right(unit));
      verifyInOrder([
        () => local.write(any()),
        () => remote.mirror(any()),
        () => local.markMirrored(
          any(),
        ), // T-1: tandai clean setelah mirror sukses
      ]);
    },
  );

  test(
    'save(): mirror gagal → local tetap tersimpan, return Right(unit) (non-fatal)',
    () async {
      when(() => local.write(any())).thenAnswer((_) async {});
      when(() => remote.mirror(any())).thenThrow(Exception('offline'));
      final r = await repo.save(PreferencesEntity.defaults);
      expect(r, const Right(unit));
      verify(() => local.write(any())).called(1);
      verifyNever(
        () => local.markMirrored(any()),
      ); // T-1: gagal → tetap dirty (retry launch)
    },
  );

  test('save(): local gagal → Left(CacheFailure)', () async {
    when(() => local.write(any())).thenThrow(Exception('disk full'));
    final r = await repo.save(PreferencesEntity.defaults);
    expect(r.isLeft(), true);
    verifyNever(() => remote.mirror(any()));
  });

  group('syncOnLaunch', () {
    PreferencesModel completedRemote() => PreferencesModel.fromEntity(
      PreferencesEntity.defaults.copyWith(
        timezone: 'Europe/Moscow',
        currentCountry: 'RU',
        currentCity: 'Moscow',
        isPerantau: true,
        profileCompleted: true,
      ),
    );

    test(
      'bootstrap: local belum selesai + remote selesai → seed local dari remote',
      () async {
        when(() => local.read()).thenAnswer(
          (_) async => PreferencesEntity.defaults,
        ); // profileCompleted=false
        when(() => remote.fetch()).thenAnswer((_) async => completedRemote());
        when(() => local.write(any())).thenAnswer((_) async {});
        when(() => remote.mirror(any())).thenAnswer((_) async {});

        final r = await repo.syncOnLaunch(budgetOnboardingCompleted: false);
        expect(r, const Right(unit));
        final seeded =
            verify(() => local.write(captureAny())).captured.single
                as PreferencesEntity;
        expect(seeded.profileCompleted, true);
        expect(seeded.timezone, 'Europe/Moscow'); // dipulihkan dari cloud
      },
    );

    test(
      'ratchet + DIRTY: local selesai & belum tersinkron → mirror retry (T-1)',
      () async {
        when(() => local.read()).thenAnswer(
          (_) async =>
              PreferencesEntity.defaults.copyWith(profileCompleted: true),
        );
        when(
          () => local.hasPendingMirror(),
        ).thenAnswer((_) async => true); // dirty
        when(() => remote.mirror(any())).thenAnswer((_) async {});

        final r = await repo.syncOnLaunch(budgetOnboardingCompleted: true);
        expect(r, const Right(unit));
        verifyNever(
          () => remote.fetch(),
        ); // local authoritative → tak baca remote
        verify(
          () => remote.mirror(any()),
        ).called(1); // dirty → retry mirror best-effort
      },
    );

    test(
      'T-1 anti-clobber: local selesai & CLEAN → TAK mirror (cloud tak ditimpa)',
      () async {
        when(() => local.read()).thenAnswer(
          (_) async =>
              PreferencesEntity.defaults.copyWith(profileCompleted: true),
        );
        when(
          () => local.hasPendingMirror(),
        ).thenAnswer((_) async => false); // clean

        final r = await repo.syncOnLaunch(budgetOnboardingCompleted: true);
        expect(r, const Right(unit));
        verifyNever(() => remote.fetch());
        verifyNever(
          () => remote.mirror(any()),
        ); // KRUSIAL: clean → cloud (device lain) tak ditimpa
      },
    );

    test(
      'smart-default akun lama: local belum + remote null + budget selesai → set profileCompleted',
      () async {
        when(
          () => local.read(),
        ).thenAnswer((_) async => PreferencesEntity.defaults);
        when(
          () => remote.fetch(),
        ).thenAnswer((_) async => null); // belum ada doc preferences
        when(() => local.write(any())).thenAnswer((_) async {});
        when(() => remote.mirror(any())).thenAnswer((_) async {});

        final r = await repo.syncOnLaunch(budgetOnboardingCompleted: true);
        expect(r, const Right(unit));
        final written =
            verify(() => local.write(captureAny())).captured.single
                as PreferencesEntity;
        expect(
          written.profileCompleted,
          true,
          reason: 'akun lama tak dipaksa ulang profil',
        );
      },
    );

    test(
      'user baru: local belum + remote null + budget belum → TAK set profileCompleted',
      () async {
        when(
          () => local.read(),
        ).thenAnswer((_) async => PreferencesEntity.defaults);
        when(() => remote.fetch()).thenAnswer((_) async => null);
        when(() => remote.mirror(any())).thenAnswer((_) async {});

        final r = await repo.syncOnLaunch(budgetOnboardingCompleted: false);
        expect(r, const Right(unit));
        verifyNever(() => local.write(any())); // biar guard → needsProfile
      },
    );

    test('mirror gagal → tetap Right (non-fatal, W5)', () async {
      when(() => local.read()).thenAnswer(
        (_) async =>
            PreferencesEntity.defaults.copyWith(profileCompleted: true),
      );
      when(() => remote.mirror(any())).thenThrow(Exception('offline'));
      final r = await repo.syncOnLaunch(budgetOnboardingCompleted: true);
      expect(r, const Right(unit));
    });

    test(
      'fetch timeout → local tak berubah → Right (fail-safe needsProfile)',
      () async {
        final slowRepo = PreferencesRepositoryImpl(
          local: local,
          remote: remote,
          syncTimeout: const Duration(milliseconds: 10),
        );
        when(
          () => local.read(),
        ).thenAnswer((_) async => PreferencesEntity.defaults);
        when(() => remote.fetch()).thenAnswer((_) async {
          await Future<void>.delayed(
            const Duration(seconds: 1),
          ); // lampaui timeout
          return completedRemote();
        });
        when(() => remote.mirror(any())).thenAnswer((_) async {});

        final r = await slowRepo.syncOnLaunch(budgetOnboardingCompleted: false);
        expect(r, const Right(unit));
        verifyNever(
          () => local.write(any()),
        ); // bootstrap gagal → local tetap default
      },
    );

    test(
      'F-D1 anti-clobber: fetch GAGAL + budget selesai (akun lama) → TAK tulis, TAK mirror',
      () async {
        // Bug lama: timeout disamakan dgn "doc absen" → smart-default menimpa profil
        // cloud asli dgn defaults via full-doc set. Sekarang fetchFailed ≠ absent.
        final slowRepo = PreferencesRepositoryImpl(
          local: local,
          remote: remote,
          syncTimeout: const Duration(milliseconds: 10),
        );
        when(
          () => local.read(),
        ).thenAnswer((_) async => PreferencesEntity.defaults);
        when(() => remote.fetch()).thenAnswer((_) async {
          await Future<void>.delayed(const Duration(seconds: 1));
          return completedRemote(); // cloud SEBENARNYA punya profil — tak boleh hilang
        });
        when(() => remote.mirror(any())).thenAnswer((_) async {});

        final r = await slowRepo.syncOnLaunch(budgetOnboardingCompleted: true);
        expect(r, const Right(unit));
        verifyNever(() => local.write(any())); // tak menulis defaults
        verifyNever(
          () => remote.mirror(any()),
        ); // KRUSIAL: tak overwrite cloud asli
      },
    );

    test(
      'F-D2 lindungi parsial: remote ADA tapi belum selesai → TAK tulis, TAK mirror',
      () async {
        when(
          () => local.read(),
        ).thenAnswer((_) async => PreferencesEntity.defaults);
        when(() => remote.fetch()).thenAnswer(
          (_) async => PreferencesModel.fromEntity(
            PreferencesEntity.defaults.copyWith(
              currentCountry: 'ID',
              currentCity: 'Jakarta',
            ),
          ),
        ); // progres parsial device lain (profileCompleted=false)
        when(() => remote.mirror(any())).thenAnswer((_) async {});

        final r = await repo.syncOnLaunch(budgetOnboardingCompleted: false);
        expect(r, const Right(unit));
        verifyNever(() => local.write(any()));
        verifyNever(
          () => remote.mirror(any()),
        ); // jangan timpa parsial dgn local kosong
      },
    );

    test(
      'F-D4 trust-boundary (Temuan 2): remote completed TAPI all-defaults (tanpa kota, zona default) → TAK seed',
      () async {
        when(
          () => local.read(),
        ).thenAnswer((_) async => PreferencesEntity.defaults);
        // Temuan 2: lewat fromFirestore (JALUR PRODUKSI), bukan fromEntity. Doc all-defaults
        // + profileCompleted:true lolos rules tapi BUKAN profil asli (tak ada kota, zona
        // default) — mis. klien lama/buggy. fromFirestore meng-clamp timezone kosong → default,
        // jadi cek "non-kosong" lama SELALU true; gerbang baru menolak by penanda profil asli.
        when(() => remote.fetch()).thenAnswer(
          (_) async => PreferencesModel.fromFirestore(const {
            'timezone': 'Asia/Jakarta',
            'baseCurrency': 'IDR',
            'homeCurrency': 'IDR',
            'language': 'id',
            'currentCountry': 'ID',
            'homeCountry': 'ID',
            'isPerantau': false,
            'profileCompleted': true,
            'schemaVersion': 1,
          }),
        );
        when(() => remote.mirror(any())).thenAnswer((_) async {});

        final r = await repo.syncOnLaunch(budgetOnboardingCompleted: false);
        expect(r, const Right(unit));
        verifyNever(
          () => local.write(any()),
        ); // jangan seed "completed" yg semu
      },
    );

    test(
      'F-D4 (Temuan 2): remote completed dgn kota asli → SEED (gerbang lolos utk profil sahih)',
      () async {
        when(
          () => local.read(),
        ).thenAnswer((_) async => PreferencesEntity.defaults);
        when(() => remote.fetch()).thenAnswer(
          (_) async => PreferencesModel.fromFirestore(const {
            'timezone': 'Asia/Jakarta',
            'baseCurrency': 'IDR',
            'homeCurrency': 'IDR',
            'language': 'id',
            'currentCountry': 'ID',
            'currentCity': 'Jakarta',
            'homeCountry': 'ID',
            'isPerantau': false,
            'profileCompleted': true,
            'schemaVersion': 1,
          }),
        );
        when(() => local.write(any())).thenAnswer((_) async {});
        when(() => remote.mirror(any())).thenAnswer((_) async {});

        final r = await repo.syncOnLaunch(budgetOnboardingCompleted: false);
        expect(r, const Right(unit));
        final seeded =
            verify(() => local.write(captureAny())).captured.single
                as PreferencesEntity;
        expect(seeded.profileCompleted, true);
        expect(seeded.currentCity, 'Jakarta');
      },
    );
  });
}
