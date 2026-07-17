import 'dart:async';
import 'package:flutter/widgets.dart' show AppLifecycleState;
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:penyintas_app/features/app_lock/domain/entities/app_lock_config.dart';
import 'package:penyintas_app/features/app_lock/domain/repositories/app_lock_repository.dart';
import 'package:penyintas_app/features/app_lock/presentation/cubit/app_lock_cubit.dart';
import 'package:penyintas_app/features/app_lock/presentation/cubit/app_lock_state.dart';

class _MockRepo extends Mock implements AppLockRepository {}

AppLockConfig _cfg({
  bool enabled = true,
  bool hasPin = true,
  bool biometricEnabled = false,
  String? ownerUid = 'uid-1',
}) => AppLockConfig(
  enabled: enabled,
  hasPin: hasPin,
  biometricEnabled: biometricEnabled,
  ownerUid: ownerUid,
);

void main() {
  late _MockRepo repo;
  late StreamController<String?> uidCtrl;

  setUp(() {
    repo = _MockRepo();
    uidCtrl = StreamController<String?>.broadcast();
    when(() => repo.isBiometricAvailable()).thenAnswer((_) async => false);
    when(() => repo.getFailedAttempts()).thenAnswer((_) async => 0);
    when(() => repo.getLockedUntilMs()).thenAnswer((_) async => 0);
    when(() => repo.resetFailedAttempts()).thenAnswer((_) async {});
  });

  tearDown(() => uidCtrl.close());

  AppLockCubit build({String? uid = 'uid-1', DateTime Function()? clock}) =>
      AppLockCubit(
        repo: repo,
        currentUid: () => uid,
        uidChanges: uidCtrl.stream,
        clock: clock,
      );

  test('init: enabled + uid match → locked (cold start)', () async {
    when(() => repo.readConfig()).thenAnswer((_) async => _cfg());
    final c = build();
    await c.init();
    expect(c.state, isA<AppLockLocked>());
  });

  test('init: disabled config → disabled', () async {
    when(() => repo.readConfig()).thenAnswer(
      (_) async => _cfg(enabled: false, hasPin: false, ownerUid: null),
    );
    final c = build();
    await c.init();
    expect(c.state, isA<AppLockDisabled>());
  });

  test('init: uid ≠ ownerUid → disabled (uid-scope)', () async {
    when(
      () => repo.readConfig(),
    ).thenAnswer((_) async => _cfg(ownerUid: 'uid-OTHER'));
    final c = build(uid: 'uid-1');
    await c.init();
    expect(c.state, isA<AppLockDisabled>());
  });

  test(
    'init: enabled tapi uid belum resolve → tahan Unknown (fail-closed), lalu ikut emisi uid',
    () async {
      // Restorasi Firebase Auth async di cold start: currentUser bisa null
      // sesaat. JANGAN emit Disabled (pass-through = bocor privasi) — tahan
      // shade sampai emisi authStateChanges pertama.
      when(() => repo.readConfig()).thenAnswer((_) async => _cfg());
      String? uid;
      final c = AppLockCubit(
        repo: repo,
        currentUid: () => uid,
        uidChanges: uidCtrl.stream,
      );
      await c.init();
      expect(c.state, isA<AppLockUnknown>());
      uid = 'uid-1';
      uidCtrl.add('uid-1');
      await Future<void>.delayed(Duration.zero);
      expect(c.state, isA<AppLockLocked>());
      await c.close();
    },
  );

  test(
    'init: enabled, emisi uid pertama = null (benar-benar logout) → disabled',
    () async {
      when(() => repo.readConfig()).thenAnswer((_) async => _cfg());
      final c = build(uid: null);
      await c.init();
      expect(c.state, isA<AppLockUnknown>());
      uidCtrl.add(null);
      await Future<void>.delayed(Duration.zero);
      expect(c.state, isA<AppLockDisabled>());
      await c.close();
    },
  );

  test('submitPin benar → unlocked + reset attempts', () async {
    when(() => repo.readConfig()).thenAnswer((_) async => _cfg());
    when(() => repo.verifyPin('123456')).thenAnswer((_) async => true);
    final c = build();
    await c.init();
    await c.submitPin('123456');
    expect(c.state, const AppLockUnlocked(obscured: false));
    verify(() => repo.resetFailedAttempts()).called(1);
  });

  test('submitPin salah → tetap locked + recordFailedAttempt', () async {
    when(() => repo.readConfig()).thenAnswer((_) async => _cfg());
    when(() => repo.verifyPin('000000')).thenAnswer((_) async => false);
    when(() => repo.recordFailedAttempt()).thenAnswer((_) async {});
    when(() => repo.getFailedAttempts()).thenAnswer((_) async => 1);
    final c = build();
    await c.init();
    await c.submitPin('000000');
    expect(c.state, isA<AppLockLocked>());
    verify(() => repo.recordFailedAttempt()).called(1);
  });

  test('forgotPin memanggil disableLock lalu emit disabled', () async {
    when(() => repo.readConfig()).thenAnswer((_) async => _cfg());
    when(() => repo.disableLock()).thenAnswer((_) async {});
    final c = build();
    await c.init();
    await c.forgotPin();
    verify(() => repo.disableLock()).called(1);
    expect(c.state, isA<AppLockDisabled>());
  });

  test('init: readConfig() melempar (keystore korup) → fail-closed ke Locked, '
      'BUKAN tersangkut Unknown selamanya', () async {
    // Regresi kritis: AppLockSecureStoreImpl.read() tidak fail-safe (beda dari
    // BiometricDataSourceImpl) — kegagalan storage melempar sampai ke init()
    // SEBELUM _unknownFallback sempat diset. Tanpa try/catch, error async ini
    // hanya tercatat ke Crashlytics dan cubit tersangkut AppLockUnknown
    // selamanya → AppLockGate menampilkan PrivacyShade permanen tanpa jalan
    // keluar (app "brick" total). Fail-closed ke Locked itu recoverable:
    // LockScreen render, user bisa tekan "Lupa PIN?" → forgotPin().
    when(() => repo.readConfig()).thenThrow(Exception('keystore korup'));
    final c = build();
    await expectLater(c.init(), completes);
    expect(c.state, isA<AppLockLocked>());
  });

  test('forgotPin tetap emit Disabled walau disableLock() JUGA melempar '
      '(escape hatch harus tetap jalan saat storage korup)', () async {
    // Lanjutan skenario di atas: dari Locked akibat storage korup, escape
    // hatch "Lupa PIN?" -> forgotPin() sendiri memanggil _repo.disableLock()
    // yang melakukan _store.delete() tanpa guard — kalau ikut melempar, user
    // akan tetap terjebak di balik shade tanpa jalan keluar sama sekali. Fail
    // OPEN di sini disengaja & diminta eksplisit (user memang sedang minta
    // reset & akan sign-out setelahnya) — beda dari init() yang wajib
    // fail-closed.
    when(() => repo.readConfig()).thenThrow(Exception('keystore korup'));
    when(() => repo.disableLock()).thenThrow(Exception('keystore korup'));
    final c = build();
    await c.init();
    expect(c.state, isA<AppLockLocked>());
    await expectLater(c.forgotPin(), completes);
    expect(c.state, isA<AppLockDisabled>());
  });

  test('tryBiometric sukses → unlocked', () async {
    when(
      () => repo.readConfig(),
    ).thenAnswer((_) async => _cfg(biometricEnabled: true));
    when(() => repo.isBiometricAvailable()).thenAnswer((_) async => true);
    when(() => repo.authenticateBiometric(any())).thenAnswer((_) async => true);
    final c = build();
    await c.init();
    await c.tryBiometric('buka');
    expect(c.state, const AppLockUnlocked(obscured: false));
  });

  test('uidChanges ke null (sign-out) → disabled', () async {
    when(() => repo.readConfig()).thenAnswer((_) async => _cfg());
    String? uid =
        'uid-1'; // WAJIB String? — `var` menginfer String non-nullable
    final c = AppLockCubit(
      repo: repo,
      currentUid: () => uid,
      uidChanges: uidCtrl.stream,
    );
    await c.init();
    expect(c.state, isA<AppLockLocked>());
    uid = null;
    uidCtrl.add(null);
    await Future<void>.delayed(Duration.zero);
    expect(c.state, isA<AppLockDisabled>());
  });

  test(
    'submitPin saat lockout aktif → ditolak tanpa verifyPin (defense-in-depth)',
    () async {
      when(() => repo.readConfig()).thenAnswer((_) async => _cfg());
      final now = DateTime(2026, 1, 1, 12);
      when(
        () => repo.getLockedUntilMs(),
      ).thenAnswer((_) async => now.millisecondsSinceEpoch + 30000);
      final c = build(clock: () => now);
      await c.init();
      await c.submitPin('123456');
      expect(c.state, isA<AppLockLocked>());
      verifyNever(() => repo.verifyPin(any()));
    },
  );

  test(
    'submitPin saat jeda lockout sudah kedaluwarsa (getLockedUntilMs pasif) → tetap verifyPin, bukan tertahan permanen',
    () async {
      // Regresi guard: getLockedUntilMs() sengaja pasif — tetap mengembalikan
      // timestamp LAMPAU setelah jeda berakhir (tak pernah self-clear). Guard
      // WAJIB banding `>` terhadap clock sekarang, BUKAN `!= 0` — kalau
      // diregresikan ke `!= 0`, timestamp lampau ini akan selalu dibaca sebagai
      // "masih lockout" dan user terkunci selamanya dari aplikasinya sendiri.
      when(() => repo.readConfig()).thenAnswer((_) async => _cfg());
      final now = DateTime(2026, 1, 1, 12);
      when(
        () => repo.getLockedUntilMs(),
      ).thenAnswer((_) async => now.millisecondsSinceEpoch - 1000);
      when(() => repo.verifyPin('123456')).thenAnswer((_) async => true);
      final c = build(clock: () => now);
      await c.init();
      await c.submitPin('123456');
      expect(c.state, const AppLockUnlocked(obscured: false));
      verify(() => repo.verifyPin(any())).called(1);
    },
  );

  group('onSettingsChanged (sinkronisasi Settings → cubit)', () {
    test(
      'lock baru dinyalakan dari Settings → unlocked (bukan langsung terkunci)',
      () async {
        when(() => repo.readConfig()).thenAnswer(
          (_) async => _cfg(enabled: false, hasPin: false, ownerUid: null),
        );
        final c = build();
        await c.init();
        expect(c.state, isA<AppLockDisabled>());
        // Settings memanggil setPin → config berubah:
        when(() => repo.readConfig()).thenAnswer((_) async => _cfg());
        await c.onSettingsChanged();
        expect(c.state, const AppLockUnlocked(obscured: false));
      },
    );

    test(
      'lock dimatikan dari Settings → disabled (cegah terkunci dgn PIN terhapus)',
      () async {
        when(() => repo.readConfig()).thenAnswer((_) async => _cfg());
        when(() => repo.verifyPin('123456')).thenAnswer((_) async => true);
        final c = build();
        await c.init();
        await c.submitPin('123456');
        expect(c.state, const AppLockUnlocked(obscured: false));
        // Settings memanggil disableLock → config berubah:
        when(() => repo.readConfig()).thenAnswer(
          (_) async => _cfg(enabled: false, hasPin: false, ownerUid: null),
        );
        await c.onSettingsChanged();
        expect(c.state, isA<AppLockDisabled>());
      },
    );
  });

  group('lifecycle', () {
    setUp(() {
      when(() => repo.readConfig()).thenAnswer((_) async => _cfg());
      when(() => repo.verifyPin('123456')).thenAnswer((_) async => true);
    });

    test(
      'inactive saat unlocked → obscured (shade), tak mulai grace-clock',
      () async {
        final c = build();
        await c.init();
        await c.submitPin('123456'); // unlocked
        c.onLifecycle(AppLifecycleState.inactive);
        expect(c.state, const AppLockUnlocked(obscured: true));
      },
    );

    test(
      'inactive semata (tanpa paused/hidden) → resume tetap unlocked walau clock maju 120 detik '
      '(membuktikan inactive benar-benar tak memulai grace-clock)',
      () async {
        var t = DateTime(2026, 1, 1, 12, 0, 0);
        final c = build(clock: () => t);
        await c.init();
        await c.submitPin('123456'); // unlocked
        c.onLifecycle(AppLifecycleState.inactive);
        t = t.add(const Duration(seconds: 120));
        c.onLifecycle(AppLifecycleState.resumed);
        expect(c.state, const AppLockUnlocked(obscured: false));
      },
    );

    test(
      'urutan Android nyata inactive→hidden→paused→[>60s]→hidden→inactive→resumed → locked '
      '(Flutter mensintesis hidden di kedua arah; regresi jam tertimpa)',
      () async {
        var t = DateTime(2026, 1, 1, 12, 0, 0);
        final c = build(clock: () => t);
        await c.init();
        await c.submitPin('123456'); // unlocked
        // Turun:
        c.onLifecycle(AppLifecycleState.inactive);
        c.onLifecycle(AppLifecycleState.hidden);
        c.onLifecycle(AppLifecycleState.paused);
        t = t.add(const Duration(seconds: 61));
        // Pulang — framework selalu lewat hidden→inactive sebelum resumed:
        c.onLifecycle(AppLifecycleState.hidden);
        c.onLifecycle(AppLifecycleState.inactive);
        c.onLifecycle(AppLifecycleState.resumed);
        // _emitLocked async (baca attempts/lockedUntil dulu) — drain microtask
        // sebelum assert, kalau tidak state masih Unlocked saat expect jalan.
        await Future<void>.delayed(Duration.zero);
        expect(c.state, isA<AppLockLocked>());
      },
    );

    test(
      'paused→resumed persis 60000ms → tetap unlocked (ambang eksklusif, sisi bawah)',
      () async {
        var t = DateTime(2026, 1, 1, 12, 0, 0);
        final c = build(clock: () => t);
        await c.init();
        await c.submitPin('123456');
        c.onLifecycle(AppLifecycleState.paused);
        t = t.add(const Duration(milliseconds: 60000));
        c.onLifecycle(AppLifecycleState.resumed);
        expect(c.state, const AppLockUnlocked(obscured: false));
      },
    );

    test(
      'paused→resumed 60001ms → locked (tepat 1ms di atas ambang, sisi atas)',
      () async {
        var t = DateTime(2026, 1, 1, 12, 0, 0);
        final c = build(clock: () => t);
        await c.init();
        await c.submitPin('123456');
        c.onLifecycle(AppLifecycleState.paused);
        t = t.add(const Duration(milliseconds: 60001));
        c.onLifecycle(AppLifecycleState.resumed);
        await Future<void>.delayed(Duration.zero);
        expect(c.state, isA<AppLockLocked>());
      },
    );

    test('paused→resumed ≤60s → tetap unlocked', () async {
      var t = DateTime(2026, 1, 1, 12, 0, 0);
      final c = build(clock: () => t);
      await c.init();
      await c.submitPin('123456');
      c.onLifecycle(AppLifecycleState.paused);
      t = t.add(const Duration(seconds: 30));
      c.onLifecycle(AppLifecycleState.resumed);
      expect(c.state, const AppLockUnlocked(obscured: false));
    });

    test('paused→resumed >60s → locked', () async {
      var t = DateTime(2026, 1, 1, 12, 0, 0);
      final c = build(clock: () => t);
      await c.init();
      await c.submitPin('123456');
      c.onLifecycle(AppLifecycleState.paused);
      t = t.add(const Duration(seconds: 61));
      c.onLifecycle(AppLifecycleState.resumed);
      // _emitLocked async (baca attempts/lockedUntil dulu) — drain microtask
      // sebelum assert, kalau tidak state masih Unlocked saat expect jalan.
      await Future<void>.delayed(Duration.zero);
      expect(c.state, isA<AppLockLocked>());
    });

    test('resume saat locked tetap locked (cold-start aman)', () async {
      final c = build();
      await c.init(); // locked
      c.onLifecycle(AppLifecycleState.paused);
      c.onLifecycle(AppLifecycleState.resumed);
      expect(c.state, isA<AppLockLocked>());
    });

    test(
      'authInProgress: resume saat prompt biometrik tak me-relock',
      () async {
        var t = DateTime(2026, 1, 1, 12, 0, 0);
        when(
          () => repo.readConfig(),
        ).thenAnswer((_) async => _cfg(biometricEnabled: true));
        when(() => repo.isBiometricAvailable()).thenAnswer((_) async => true);
        final completer = Completer<bool>();
        when(
          () => repo.authenticateBiometric(any()),
        ).thenAnswer((_) => completer.future);
        final c = build(clock: () => t);
        await c.init(); // locked
        await c.submitPin('123456'); // unlocked untuk skenario ini
        final f = c.tryBiometric('buka'); // set _authInProgress
        // Prompt biometrik memicu paused→resumed:
        c.onLifecycle(AppLifecycleState.paused);
        t = t.add(const Duration(seconds: 120));
        c.onLifecycle(AppLifecycleState.resumed);
        completer.complete(true);
        await f;
        expect(c.state, const AppLockUnlocked(obscured: false));
      },
    );

    test(
      'authInProgress guard: assert SINKRON tepat setelah paused (sebelum await) — '
      'tanpa guard onLifecycle akan sempat mengubah state ke obscured:true',
      () async {
        when(
          () => repo.readConfig(),
        ).thenAnswer((_) async => _cfg(biometricEnabled: true));
        when(() => repo.isBiometricAvailable()).thenAnswer((_) async => true);
        final completer = Completer<bool>();
        when(
          () => repo.authenticateBiometric(any()),
        ).thenAnswer((_) => completer.future);
        final c = build();
        await c.init();
        await c.submitPin('123456'); // unlocked
        final f = c.tryBiometric(
          'buka',
        ); // set _authInProgress = true (sinkron sebelum await pertama)
        c.onLifecycle(AppLifecycleState.paused);
        // Guard aktif → onLifecycle no-op, state belum sempat berubah oleh
        // _emitLocked(authInProgress: true) yang masih pending di microtask.
        expect(c.state, const AppLockUnlocked(obscured: false));
        completer.complete(true);
        await f;
      },
    );

    test(
      'onSettingsChanged: biometrik baru ON → lock berikutnya bawa biometricAvailable',
      () async {
        var t = DateTime(2026, 1, 1, 12, 0, 0);
        final c = build(clock: () => t);
        await c.init();
        await c.submitPin('123456'); // unlocked
        // Settings menyalakan sub-toggle biometrik:
        when(
          () => repo.readConfig(),
        ).thenAnswer((_) async => _cfg(biometricEnabled: true));
        when(() => repo.isBiometricAvailable()).thenAnswer((_) async => true);
        await c.onSettingsChanged();
        // Background >60s → locked HARUS menawarkan biometrik (config segar).
        c.onLifecycle(AppLifecycleState.paused);
        t = t.add(const Duration(seconds: 61));
        c.onLifecycle(AppLifecycleState.resumed);
        await Future<void>.delayed(Duration.zero);
        final s = c.state;
        expect(s, isA<AppLockLocked>());
        expect((s as AppLockLocked).biometricAvailable, isTrue);
      },
    );
  });
}
