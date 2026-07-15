import 'package:flutter/material.dart';
import 'package:penyintas_app/core/di/injection_container.dart';
import 'package:penyintas_app/core/l10n/app_localizations_ext.dart';
import 'package:penyintas_app/features/app_lock/domain/repositories/app_lock_repository.dart';
import 'package:penyintas_app/features/app_lock/presentation/pages/pin_verify_helper.dart';

/// State machine bersama untuk halaman yang memverifikasi PIN yang SUDAH ADA
/// dengan lockout progresif — [ChangePinPage] & [VerifyPinPage] identik
/// persis pada bagian ini: kumpulkan 6 digit → [verifyPinWithLockout] →
/// `wrong` (tampilkan pesan, reset input) / `lockedOut` (snackbar + tutup
/// halaman via `pop(false)`). Satu-satunya perbedaan antar kedua halaman
/// adalah perilaku saat outcome `ok`, didelegasikan lewat [onVerified] —
/// itulah sebabnya ini di-mixin, bukan diduplikasi.
mixin PinVerifyFlowMixin<T extends StatefulWidget> on State<T> {
  String pin = '';
  bool wrong = false;
  bool busy = false;

  /// Dipanggil saat PIN benar (outcome == ok). Isi dengan aksi spesifik
  /// halaman (mis. push [SetPinPage] untuk ganti PIN, atau `pop(true)`
  /// langsung untuk verifikasi biasa).
  Future<void> onVerified();

  Future<void> onDigit(String d) async {
    if (busy || pin.length >= 6) return;
    setState(() {
      wrong = false;
      pin += d;
    });
    if (pin.length != 6) return;
    busy = true;
    final repo = sl<AppLockRepository>();
    final outcome = await verifyPinWithLockout(repo, pin);
    if (!mounted) return;
    switch (outcome) {
      case PinVerifyOutcome.ok:
        await onVerified();
      case PinVerifyOutcome.wrong:
        setState(() {
          busy = false;
          wrong = true;
          pin = '';
        });
      case PinVerifyOutcome.lockedOut:
        // Kena jeda lockout progresif — counter/lockedUntil SHARED dengan
        // LockScreen, jadi jeda yang sama berlaku di sana juga.
        final seconds = await remainingLockoutSeconds(repo);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.applockLockedWait(seconds))),
        );
        Navigator.of(context).pop(false);
    }
  }

  void onBackspace() {
    if (pin.isEmpty) return;
    setState(() => pin = pin.substring(0, pin.length - 1));
  }

  /// Reset input & flag busy — dipakai [ChangePinPage] saat user membatalkan
  /// halaman set-PIN-baru (kembali tanpa selesai) agar bisa mencoba lagi.
  void resetAfterCancel() {
    setState(() {
      busy = false;
      pin = '';
    });
  }
}
