import 'package:flutter_test/flutter_test.dart';
import 'package:penyintas_app/features/app_lock/domain/entities/app_lock_config.dart';

void main() {
  test('AppLockConfig equality by value', () {
    const a = AppLockConfig(
      enabled: true,
      hasPin: true,
      biometricEnabled: false,
      ownerUid: 'u1',
    );
    const b = AppLockConfig(
      enabled: true,
      hasPin: true,
      biometricEnabled: false,
      ownerUid: 'u1',
    );
    const c = AppLockConfig(
      enabled: false,
      hasPin: false,
      biometricEnabled: false,
      ownerUid: null,
    );
    expect(a, b);
    expect(a == c, isFalse);
  });

  test('AppLockConfig tidak sama bila hanya ownerUid berbeda', () {
    // Menjaga agar `ownerUid` benar-benar ikut dibandingkan lewat props —
    // bila field ini terlupa di props, dua config ini akan keliru dianggap sama.
    const withOwner = AppLockConfig(
      enabled: true,
      hasPin: true,
      biometricEnabled: true,
      ownerUid: 'u1',
    );
    const withOtherOwner = AppLockConfig(
      enabled: true,
      hasPin: true,
      biometricEnabled: true,
      ownerUid: 'u2',
    );
    expect(withOwner == withOtherOwner, isFalse);
  });

  test('AppLockConfig tidak sama bila hanya hasPin berbeda', () {
    const withPin = AppLockConfig(
      enabled: true,
      hasPin: true,
      biometricEnabled: false,
      ownerUid: 'u1',
    );
    const withoutPin = AppLockConfig(
      enabled: true,
      hasPin: false,
      biometricEnabled: false,
      ownerUid: 'u1',
    );
    expect(withPin == withoutPin, isFalse);
  });

  test('AppLockConfig tidak sama bila hanya biometricEnabled berbeda', () {
    const biometricOn = AppLockConfig(
      enabled: true,
      hasPin: true,
      biometricEnabled: true,
      ownerUid: 'u1',
    );
    const biometricOff = AppLockConfig(
      enabled: true,
      hasPin: true,
      biometricEnabled: false,
      ownerUid: 'u1',
    );
    expect(biometricOn == biometricOff, isFalse);
  });

  test('AppLockConfig tidak sama bila hanya enabled berbeda', () {
    const on = AppLockConfig(
      enabled: true,
      hasPin: false,
      biometricEnabled: false,
      ownerUid: null,
    );
    const off = AppLockConfig(
      enabled: false,
      hasPin: false,
      biometricEnabled: false,
      ownerUid: null,
    );
    expect(on == off, isFalse);
  });

  test('ownerUid boleh null', () {
    const config = AppLockConfig(
      enabled: false,
      hasPin: false,
      biometricEnabled: false,
    );
    expect(config.ownerUid, isNull);
  });
}
