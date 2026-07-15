import 'dart:async';
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
}) =>
    AppLockConfig(
        enabled: enabled,
        hasPin: hasPin,
        biometricEnabled: biometricEnabled,
        ownerUid: ownerUid);

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
    when(() => repo.readConfig())
        .thenAnswer((_) async => _cfg(enabled: false, hasPin: false, ownerUid: null));
    final c = build();
    await c.init();
    expect(c.state, isA<AppLockDisabled>());
  });

  test('init: uid ≠ ownerUid → disabled (uid-scope)', () async {
    when(() => repo.readConfig()).thenAnswer((_) async => _cfg(ownerUid: 'uid-OTHER'));
    final c = build(uid: 'uid-1');
    await c.init();
    expect(c.state, isA<AppLockDisabled>());
  });

  test('init: enabled tapi uid belum resolve → tahan Unknown (fail-closed), lalu ikut emisi uid', () async {
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
  });

  test('init: enabled, emisi uid pertama = null (benar-benar logout) → disabled', () async {
    when(() => repo.readConfig()).thenAnswer((_) async => _cfg());
    final c = build(uid: null);
    await c.init();
    expect(c.state, isA<AppLockUnknown>());
    uidCtrl.add(null);
    await Future<void>.delayed(Duration.zero);
    expect(c.state, isA<AppLockDisabled>());
    await c.close();
  });

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

  test('tryBiometric sukses → unlocked', () async {
    when(() => repo.readConfig())
        .thenAnswer((_) async => _cfg(biometricEnabled: true));
    when(() => repo.isBiometricAvailable()).thenAnswer((_) async => true);
    when(() => repo.authenticateBiometric(any())).thenAnswer((_) async => true);
    final c = build();
    await c.init();
    await c.tryBiometric('buka');
    expect(c.state, const AppLockUnlocked(obscured: false));
  });

  test('uidChanges ke null (sign-out) → disabled', () async {
    when(() => repo.readConfig()).thenAnswer((_) async => _cfg());
    String? uid = 'uid-1'; // WAJIB String? — `var` menginfer String non-nullable
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

  test('submitPin saat lockout aktif → ditolak tanpa verifyPin (defense-in-depth)', () async {
    when(() => repo.readConfig()).thenAnswer((_) async => _cfg());
    final now = DateTime(2026, 1, 1, 12);
    when(() => repo.getLockedUntilMs())
        .thenAnswer((_) async => now.millisecondsSinceEpoch + 30000);
    final c = build(clock: () => now);
    await c.init();
    await c.submitPin('123456');
    expect(c.state, isA<AppLockLocked>());
    verifyNever(() => repo.verifyPin(any()));
  });

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
    when(() => repo.getLockedUntilMs())
        .thenAnswer((_) async => now.millisecondsSinceEpoch - 1000);
    when(() => repo.verifyPin('123456')).thenAnswer((_) async => true);
    final c = build(clock: () => now);
    await c.init();
    await c.submitPin('123456');
    expect(c.state, const AppLockUnlocked(obscured: false));
    verify(() => repo.verifyPin(any())).called(1);
  });

  group('onSettingsChanged (sinkronisasi Settings → cubit)', () {
    test('lock baru dinyalakan dari Settings → unlocked (bukan langsung terkunci)', () async {
      when(() => repo.readConfig()).thenAnswer(
          (_) async => _cfg(enabled: false, hasPin: false, ownerUid: null));
      final c = build();
      await c.init();
      expect(c.state, isA<AppLockDisabled>());
      // Settings memanggil setPin → config berubah:
      when(() => repo.readConfig()).thenAnswer((_) async => _cfg());
      await c.onSettingsChanged();
      expect(c.state, const AppLockUnlocked(obscured: false));
    });

    test('lock dimatikan dari Settings → disabled (cegah terkunci dgn PIN terhapus)', () async {
      when(() => repo.readConfig()).thenAnswer((_) async => _cfg());
      when(() => repo.verifyPin('123456')).thenAnswer((_) async => true);
      final c = build();
      await c.init();
      await c.submitPin('123456');
      expect(c.state, const AppLockUnlocked(obscured: false));
      // Settings memanggil disableLock → config berubah:
      when(() => repo.readConfig()).thenAnswer(
          (_) async => _cfg(enabled: false, hasPin: false, ownerUid: null));
      await c.onSettingsChanged();
      expect(c.state, isA<AppLockDisabled>());
    });
  });
}
