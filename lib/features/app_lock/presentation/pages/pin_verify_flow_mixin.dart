import 'dart:async';
import 'package:flutter/material.dart';
import 'package:penyintas_app/core/di/injection_container.dart';
import 'package:penyintas_app/features/app_lock/domain/repositories/app_lock_repository.dart';
import 'package:penyintas_app/features/app_lock/presentation/pages/pin_verify_helper.dart';

/// State machine bersama untuk halaman yang memverifikasi PIN yang SUDAH ADA
/// dengan lockout progresif — [ChangePinPage] & [VerifyPinPage] identik
/// persis pada bagian ini: kumpulkan 6 digit → [verifyPinWithLockout] →
/// `wrong` (tampilkan pesan, reset input) / `lockedOut` (tampilkan countdown
/// DI TEMPAT lewat [lockedSeconds] + keypad nonaktif — halaman TIDAK menutup
/// diri, meniru pola [LockScreen]). Lockout juga dicek saat halaman DIBUKA
/// (`initState`), bukan hanya saat submit — jadi user yang masuk ulang saat
/// jeda masih aktif langsung melihat countdown & keypad terkunci, tanpa perlu
/// memasukkan PIN dulu. Satu-satunya perbedaan antar kedua halaman adalah
/// perilaku saat outcome `ok`, didelegasikan lewat [onVerified] — itulah
/// sebabnya ini di-mixin, bukan diduplikasi.
mixin PinVerifyFlowMixin<T extends StatefulWidget> on State<T> {
  String pin = '';
  bool wrong = false;
  bool busy = false;

  /// Sisa detik lockout yang sedang berlangsung (0 = tak ada lockout aktif).
  /// Dihitung mundur secara LOKAL oleh [_ticker] tiap detik — enforcement asli
  /// tetap di [verifyPinWithLockout] saat submit, ini murni untuk tampilan.
  int lockedSeconds = 0;
  Timer? _ticker;

  /// Dipanggil saat PIN benar (outcome == ok). Isi dengan aksi spesifik
  /// halaman (mis. push [SetPinPage] untuk ganti PIN, atau `pop(true)`
  /// langsung untuk verifikasi biasa).
  Future<void> onVerified();

  @override
  void initState() {
    super.initState();
    _syncLockout();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  /// Baca sisa lockout SEKALI dari repository lalu, bila masih aktif, mulai
  /// hitung mundur lokal per detik sampai 0. Dipanggil saat halaman dibuka
  /// (`initState`) dan setiap kali submit PIN mengembalikan `lockedOut`.
  Future<void> _syncLockout() async {
    final seconds = await remainingLockoutSeconds(sl<AppLockRepository>());
    if (!mounted) return;
    setState(() => lockedSeconds = seconds);
    _ticker?.cancel();
    _ticker = null;
    if (seconds > 0) {
      _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        setState(() {
          lockedSeconds = lockedSeconds > 1 ? lockedSeconds - 1 : 0;
        });
        if (lockedSeconds == 0) {
          _ticker?.cancel();
          _ticker = null;
        }
      });
    }
  }

  Future<void> onDigit(String d) async {
    if (busy || lockedSeconds > 0 || pin.length >= 6) return;
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
        // LockScreen, jadi jeda yang sama berlaku di sana juga. Countdown
        // ditampilkan DI TEMPAT (bukan snackbar+pop) — halaman tetap terbuka
        // sampai jeda habis, konsisten dengan LockScreen.
        setState(() {
          busy = false;
          pin = '';
        });
        await _syncLockout();
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
