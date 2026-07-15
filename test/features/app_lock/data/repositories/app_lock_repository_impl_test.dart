import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:penyintas_app/features/app_lock/data/datasources/app_lock_secure_store.dart';
import 'package:penyintas_app/features/app_lock/data/datasources/biometric_datasource.dart';
import 'package:penyintas_app/features/app_lock/data/repositories/app_lock_repository_impl.dart';

class _MockStore extends Mock implements AppLockSecureStore {}

class _MockBiometric extends Mock implements BiometricDataSource {}

void main() {
  late _MockStore store;
  late _MockBiometric bio;
  late AppLockRepositoryImpl repo;
  final mem = <String, String>{};

  setUp(() {
    store = _MockStore();
    bio = _MockBiometric();
    mem.clear();
    // Simulasikan store sebagai map in-memory.
    when(
      () => store.read(any()),
    ).thenAnswer((i) async => mem[i.positionalArguments[0]]);
    when(() => store.write(any(), any())).thenAnswer((i) async {
      mem[i.positionalArguments[0] as String] =
          i.positionalArguments[1] as String;
    });
    when(() => store.delete(any())).thenAnswer((i) async {
      mem.remove(i.positionalArguments[0]);
    });
    repo = AppLockRepositoryImpl(store: store, biometric: bio);
  });

  test('setPin lalu verifyPin benar/salah', () async {
    await repo.setPin('123456', 'uid-1');
    expect(await repo.verifyPin('123456'), isTrue);
    expect(await repo.verifyPin('000000'), isFalse);
  });

  test('setPin menyalakan enabled + menyimpan ownerUid', () async {
    await repo.setPin('123456', 'uid-1');
    final cfg = await repo.readConfig();
    expect(cfg.enabled, isTrue);
    expect(cfg.hasPin, isTrue);
    expect(cfg.ownerUid, 'uid-1');
  });

  test('disableLock menghapus semua key', () async {
    await repo.setPin('123456', 'uid-1');
    await repo.setBiometricEnabled(true);
    await repo.recordFailedAttempt();
    await repo.disableLock();
    final cfg = await repo.readConfig();
    expect(cfg.enabled, isFalse);
    expect(cfg.hasPin, isFalse);
    expect(cfg.biometricEnabled, isFalse);
    expect(cfg.ownerUid, isNull);
    expect(await repo.getFailedAttempts(), 0);
    expect(await repo.getLockedUntilMs(), 0);
  });

  test('lockout: 5 gagal → lockedUntil ~30s', () async {
    await repo.setPin('123456', 'uid-1');
    for (var i = 0; i < 5; i++) {
      await repo.recordFailedAttempt();
    }
    expect(await repo.getFailedAttempts(), 5);
    final until = await repo.getLockedUntilMs();
    final delta = until - DateTime.now().millisecondsSinceEpoch;
    expect(delta, greaterThan(25000));
    expect(delta, lessThanOrEqualTo(30000));
  });

  test('lockout progresif: 10 gagal → ~60s, 15 gagal → ~300s', () async {
    await repo.setPin('123456', 'uid-1');
    for (var i = 0; i < 10; i++) {
      await repo.recordFailedAttempt();
    }
    var delta =
        (await repo.getLockedUntilMs()) - DateTime.now().millisecondsSinceEpoch;
    expect(delta, greaterThan(55000));
    expect(delta, lessThanOrEqualTo(60000));
    for (var i = 0; i < 5; i++) {
      await repo.recordFailedAttempt();
    }
    delta =
        (await repo.getLockedUntilMs()) - DateTime.now().millisecondsSinceEpoch;
    expect(delta, greaterThan(295000));
    expect(delta, lessThanOrEqualTo(300000));
  });

  test('lockedUntil TIDAK berubah di antara kelipatan 5 (attempts 6-9)', () async {
    await repo.setPin('123456', 'uid-1');
    for (var i = 0; i < 5; i++) {
      await repo.recordFailedAttempt();
    }
    final untilAt5 = await repo.getLockedUntilMs();
    // Percobaan gagal ke-6, ke-7, ke-8, ke-9: BUKAN kelipatan 5.
    // lockedUntil tidak boleh berubah — kalau di-refresh di sini, pemilik sah
    // yang salah pencet berulang akan terkunci makin lama tanpa alasan.
    for (var i = 0; i < 4; i++) {
      await repo.recordFailedAttempt();
    }
    expect(await repo.getFailedAttempts(), 9);
    expect(await repo.getLockedUntilMs(), untilAt5);
  });

  test('resetFailedAttempts mengosongkan attempts + lockedUntil', () async {
    await repo.setPin('123456', 'uid-1');
    for (var i = 0; i < 5; i++) {
      await repo.recordFailedAttempt();
    }
    await repo.resetFailedAttempts();
    expect(await repo.getFailedAttempts(), 0);
    expect(await repo.getLockedUntilMs(), 0);
  });

  test('isBiometricAvailable mendelegasikan ke BiometricDataSource', () async {
    when(() => bio.isAvailable()).thenAnswer((_) async => true);
    expect(await repo.isBiometricAvailable(), isTrue);
  });

  test('setBiometricEnabled tersimpan dan terbaca lewat readConfig', () async {
    await repo.setPin('123456', 'uid-1');
    await repo.setBiometricEnabled(true);
    expect((await repo.readConfig()).biometricEnabled, isTrue);
    await repo.setBiometricEnabled(false);
    expect((await repo.readConfig()).biometricEnabled, isFalse);
  });

  test(
    'authenticateBiometric mendelegasikan reason & hasil ke BiometricDataSource',
    () async {
      when(
        () => bio.authenticate('Buka kunci Penyintas'),
      ).thenAnswer((_) async => true);
      expect(
        await repo.authenticateBiometric('Buka kunci Penyintas'),
        isTrue,
      );
      when(
        () => bio.authenticate('Buka kunci Penyintas'),
      ).thenAnswer((_) async => false);
      expect(
        await repo.authenticateBiometric('Buka kunci Penyintas'),
        isFalse,
      );
    },
  );

  test('getFailedAttempts default 0 saat belum ada percobaan gagal', () async {
    await repo.setPin('123456', 'uid-1');
    expect(await repo.getFailedAttempts(), 0);
  });

  test('readConfig hasPin false saat belum pernah setPin', () async {
    final cfg = await repo.readConfig();
    expect(cfg.enabled, isFalse);
    expect(cfg.hasPin, isFalse);
    expect(cfg.ownerUid, isNull);
  });
}
