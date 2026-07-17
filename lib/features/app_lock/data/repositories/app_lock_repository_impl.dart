import 'package:penyintas_app/core/utils/pin_hasher.dart';
import 'package:penyintas_app/features/app_lock/data/datasources/app_lock_secure_store.dart';
import 'package:penyintas_app/features/app_lock/data/datasources/biometric_datasource.dart';
import 'package:penyintas_app/features/app_lock/domain/entities/app_lock_config.dart';
import 'package:penyintas_app/features/app_lock/domain/repositories/app_lock_repository.dart';

/// Implementasi App Lock — device-local, menyatukan `AppLockSecureStore`
/// (penyimpanan terenkripsi), `BiometricDataSource` (local_auth), dan
/// `PinHasher` (salted SHA-256, lihat `pin_hasher.dart`).
///
/// Hash PIN tak pernah keluar dari kelas ini — `readConfig()` hanya
/// mengekspos `hasPin: bool`.
class AppLockRepositoryImpl implements AppLockRepository {
  AppLockRepositoryImpl({
    required AppLockSecureStore store,
    required BiometricDataSource biometric,
  }) : _store = store,
       _bio = biometric;

  final AppLockSecureStore _store;
  final BiometricDataSource _bio;

  static const _kEnabled = 'app_lock_enabled';
  static const _kOwnerUid = 'app_lock_owner_uid';
  static const _kHash = 'app_lock_pin_hash';
  static const _kSalt = 'app_lock_pin_salt';
  static const _kBiometric = 'app_lock_biometric_enabled';
  static const _kAttempts = 'app_lock_failed_attempts';
  static const _kLockedUntil = 'app_lock_locked_until';

  @override
  Future<AppLockConfig> readConfig() async {
    final enabled = (await _store.read(_kEnabled)) == 'true';
    final hash = await _store.read(_kHash);
    final biometric = (await _store.read(_kBiometric)) == 'true';
    final ownerUid = await _store.read(_kOwnerUid);
    return AppLockConfig(
      enabled: enabled,
      hasPin: hash != null && hash.isNotEmpty,
      biometricEnabled: biometric,
      ownerUid: ownerUid,
    );
  }

  @override
  Future<void> setPin(String pin, String uid) async {
    final salt = PinHasher.generateSalt();
    final hash = PinHasher.hash(pin, salt);
    await _store.write(_kSalt, salt);
    await _store.write(_kHash, hash);
    await _store.write(_kOwnerUid, uid);
    await _store.write(_kEnabled, 'true');
    // Reset WAJIB: tanpa ini flag biometrik warisan pemilik LAMA bertahan
    // (setPin menimpa hash/salt/ownerUid tapi tak menyentuh kunci ini).
    // Skenario: A menyalakan biometrik → sign-out → B sign-in & menyalakan
    // lock → lock B langsung biometrik-aktif tanpa B pernah memilihnya, dan
    // sidik jari A yang terdaftar di device ikut membukanya. Pemilik baru
    // harus memilih sendiri.
    await _store.write(_kBiometric, 'false');
    await resetFailedAttempts();
  }

  @override
  Future<bool> verifyPin(String pin) async {
    final salt = await _store.read(_kSalt);
    final hash = await _store.read(_kHash);
    if (salt == null || hash == null) return false;
    return PinHasher.verify(pin, salt, hash);
  }

  @override
  Future<void> disableLock() async {
    await _store.delete(_kEnabled);
    await _store.delete(_kOwnerUid);
    await _store.delete(_kHash);
    await _store.delete(_kSalt);
    await _store.delete(_kBiometric);
    await _store.delete(_kAttempts);
    await _store.delete(_kLockedUntil);
  }

  @override
  Future<void> setBiometricEnabled(bool value) =>
      _store.write(_kBiometric, value ? 'true' : 'false');

  @override
  Future<bool> isBiometricAvailable() => _bio.isAvailable();

  @override
  Future<bool> authenticateBiometric(String reason) =>
      _bio.authenticate(reason);

  @override
  Future<int> getFailedAttempts() async {
    final v = await _store.read(_kAttempts);
    return int.tryParse(v ?? '0') ?? 0;
  }

  @override
  Future<void> recordFailedAttempt() async {
    final attempts = (await getFailedAttempts()) + 1;
    await _store.write(_kAttempts, '$attempts');
    // Jeda HANYA di-set pada kelipatan 5 — disengaja. Kalau di-refresh di
    // setiap kegagalan setelah ke-5, pemilik sah yang salah pencet berulang
    // ikut terkunci makin lama tanpa alasan. Modulo-5 membuat jeda datang
    // berjenjang di batas blok saja (lihat requirement lockout tiers).
    if (attempts % 5 == 0) {
      final delayMs = _delayMsForAttempts(attempts);
      final until = DateTime.now().millisecondsSinceEpoch + delayMs;
      await _store.write(_kLockedUntil, '$until');
    }
  }

  @override
  Future<void> resetFailedAttempts() async {
    await _store.write(_kAttempts, '0');
    await _store.write(_kLockedUntil, '0');
  }

  @override
  Future<int> getLockedUntilMs() async {
    final v = await _store.read(_kLockedUntil);
    return int.tryParse(v ?? '0') ?? 0;
  }

  /// Tier lockout progresif: blok 1 (attempts=5) → 30s; blok 2 (attempts=10)
  /// → 60s; blok ≥3 (attempts≥15) → 300s.
  int _delayMsForAttempts(int attempts) {
    final block = attempts ~/ 5; // 5→1, 10→2, 15→3
    switch (block) {
      case 1:
        return 30 * 1000;
      case 2:
        return 60 * 1000;
      default:
        return 5 * 60 * 1000;
    }
  }
}
