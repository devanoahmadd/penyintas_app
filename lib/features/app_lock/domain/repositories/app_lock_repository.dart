import 'package:penyintas_app/features/app_lock/domain/entities/app_lock_config.dart';

/// Kontrak App Lock — device-local (bukan Firestore/PreferencesEntity).
///
/// Sengaja mengembalikan `Future<T>` polos (tanpa `Either<Failure, T>`):
/// kegagalan di state device-local ini ditangani *fail-closed* di lapisan
/// Cubit (Task 7), bukan dipropagasi sebagai `Failure`.
abstract class AppLockRepository {
  /// Baca konfigurasi App Lock saat ini.
  Future<AppLockConfig> readConfig();

  /// Set PIN baru (hash disimpan di repository, tak pernah keluar sebagai plaintext).
  Future<void> setPin(String pin, String uid);

  /// Verifikasi PIN terhadap hash tersimpan.
  Future<bool> verifyPin(String pin);

  /// Nonaktifkan App Lock (hapus PIN & reset status).
  Future<void> disableLock();

  /// Aktif/nonaktifkan penggunaan biometrik sebagai alternatif PIN.
  Future<void> setBiometricEnabled(bool value);

  /// Cek apakah biometrik tersedia di device ini.
  Future<bool> isBiometricAvailable();

  /// Jalankan prompt autentikasi biometrik dengan alasan yang ditampilkan ke user.
  Future<bool> authenticateBiometric(String reason);

  /// Jumlah percobaan PIN gagal berturut-turut sejak reset terakhir.
  Future<int> getFailedAttempts();

  /// Catat satu percobaan gagal — increment counter, dan set `lockedUntil`
  /// bila ambang batas 5 percobaan tercapai.
  Future<void> recordFailedAttempt();

  /// Reset counter percobaan gagal ke 0.
  Future<void> resetFailedAttempts();

  /// Timestamp (epoch ms) berakhirnya jeda kunci. 0 bila tak ada jeda aktif.
  Future<int> getLockedUntilMs();
}
