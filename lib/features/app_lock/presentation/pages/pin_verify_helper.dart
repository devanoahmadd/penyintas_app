import 'package:penyintas_app/features/app_lock/domain/repositories/app_lock_repository.dart';

/// Hasil verifikasi PIN via [verifyPinWithLockout].
enum PinVerifyOutcome { ok, wrong, lockedOut }

/// Verifikasi PIN dengan lockout progresif — dipakai oleh jalur Settings
/// (Change/Verify PIN) agar tunduk pada rate-limit yang SAMA dengan
/// [LockScreen]. Counter percobaan gagal & `lockedUntil` shared (persist di
/// secure storage lewat [AppLockRepository]), sehingga brute-force PIN lewat
/// toggle-off Settings tak bisa membypass jeda yang sudah aktif dari LockScreen.
Future<PinVerifyOutcome> verifyPinWithLockout(
    AppLockRepository repo, String pin) async {
  // `getLockedUntilMs()` PASIF — repository tak pernah membersihkannya
  // sendiri setelah jeda kedaluwarsa, jadi WAJIB dibandingkan terhadap waktu
  // sekarang (bukan `!= 0`) di sini juga.
  final now = DateTime.now().millisecondsSinceEpoch;
  if (await repo.getLockedUntilMs() > now) {
    return PinVerifyOutcome.lockedOut;
  }
  if (await repo.verifyPin(pin)) {
    await repo.resetFailedAttempts();
    return PinVerifyOutcome.ok;
  }
  await repo.recordFailedAttempt();
  final attempts = await repo.getFailedAttempts();
  return attempts % 5 == 0 ? PinVerifyOutcome.lockedOut : PinVerifyOutcome.wrong;
}

/// Sisa detik lockout aktif — 0 bila tak aktif (baik karena belum pernah ada
/// jeda, maupun karena jeda sebelumnya sudah kedaluwarsa). Di-clamp ke
/// minimum 0 — TIDAK BOLEH negatif, karena nilai ini langsung dipakai di
/// pesan `applockLockedWait(seconds)`.
Future<int> remainingLockoutSeconds(AppLockRepository repo) async {
  final delta =
      (await repo.getLockedUntilMs()) - DateTime.now().millisecondsSinceEpoch;
  return delta > 0 ? (delta / 1000).ceil() : 0;
}
