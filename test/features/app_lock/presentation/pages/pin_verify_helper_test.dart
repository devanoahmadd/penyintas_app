import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:penyintas_app/features/app_lock/domain/repositories/app_lock_repository.dart';
import 'package:penyintas_app/features/app_lock/presentation/pages/pin_verify_helper.dart';

class _MockRepo extends Mock implements AppLockRepository {}

void main() {
  late _MockRepo repo;

  setUp(() {
    repo = _MockRepo();
    when(() => repo.getLockedUntilMs()).thenAnswer((_) async => 0);
    when(() => repo.resetFailedAttempts()).thenAnswer((_) async {});
    when(() => repo.recordFailedAttempt()).thenAnswer((_) async {});
  });

  test('lockout aktif → lockedOut tanpa memanggil verifyPin', () async {
    when(
      () => repo.getLockedUntilMs(),
    ).thenAnswer((_) async => DateTime.now().millisecondsSinceEpoch + 30000);
    expect(
      await verifyPinWithLockout(repo, '123456'),
      PinVerifyOutcome.lockedOut,
    );
    verifyNever(() => repo.verifyPin(any()));
  });

  test(
    'lockout kedaluwarsa (timestamp lampau) → tidak lockedOut, verifyPin tetap dipanggil',
    () async {
      when(
        () => repo.getLockedUntilMs(),
      ).thenAnswer((_) async => DateTime.now().millisecondsSinceEpoch - 30000);
      when(() => repo.verifyPin('123456')).thenAnswer((_) async => true);
      expect(await verifyPinWithLockout(repo, '123456'), PinVerifyOutcome.ok);
      verify(() => repo.verifyPin('123456')).called(1);
    },
  );

  test('PIN benar → ok + resetFailedAttempts', () async {
    when(() => repo.verifyPin('123456')).thenAnswer((_) async => true);
    expect(await verifyPinWithLockout(repo, '123456'), PinVerifyOutcome.ok);
    verify(() => repo.resetFailedAttempts()).called(1);
  });

  test('PIN salah non-blok → wrong + recordFailedAttempt', () async {
    when(() => repo.verifyPin(any())).thenAnswer((_) async => false);
    when(() => repo.getFailedAttempts()).thenAnswer((_) async => 3);
    expect(await verifyPinWithLockout(repo, '000000'), PinVerifyOutcome.wrong);
    verify(() => repo.recordFailedAttempt()).called(1);
  });

  test('PIN salah tepat kelipatan 5 → lockedOut', () async {
    when(() => repo.verifyPin(any())).thenAnswer((_) async => false);
    when(() => repo.getFailedAttempts()).thenAnswer((_) async => 5);
    expect(
      await verifyPinWithLockout(repo, '000000'),
      PinVerifyOutcome.lockedOut,
    );
  });

  test(
    'remainingLockoutSeconds → 0 saat lockedUntilMs belum pernah ada',
    () async {
      when(() => repo.getLockedUntilMs()).thenAnswer((_) async => 0);
      expect(await remainingLockoutSeconds(repo), 0);
    },
  );

  test(
    'remainingLockoutSeconds → 0 saat jeda sudah kedaluwarsa (bukan negatif)',
    () async {
      when(
        () => repo.getLockedUntilMs(),
      ).thenAnswer((_) async => DateTime.now().millisecondsSinceEpoch - 5000);
      expect(await remainingLockoutSeconds(repo), 0);
    },
  );

  test('remainingLockoutSeconds → >0 saat jeda aktif', () async {
    when(
      () => repo.getLockedUntilMs(),
    ).thenAnswer((_) async => DateTime.now().millisecondsSinceEpoch + 30000);
    final seconds = await remainingLockoutSeconds(repo);
    expect(seconds, greaterThan(0));
    expect(seconds, lessThanOrEqualTo(30));
  });
}
