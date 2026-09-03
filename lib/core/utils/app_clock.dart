/// Sumber tunggal "sekarang" untuk fitur Konsistensi.
///
/// LINGKUPNYA SEMPIT DAN DISENGAJA: `lib/` punya 95 pemanggilan
/// `DateTime.now()`; Fase 1 A4 memigrasikan HANYA empat yang dimilikinya
/// sendiri (StreakLocalDatasource, StreakRepositoryImpl, StreakBloc,
/// DailyReminderScheduler). Ini perbaikan terarah pada kode yang memang
/// sedang ditulis, bukan izin menyapu seluruh codebase.
abstract class AppClock {
  /// Wall-clock LOKAL device — bukan UTC, bukan TZ preferensi. Seluruh app
  /// merender tanggal transaksi dengan wall-clock device; streak yang memakai
  /// sumber lain akan berselisih satu hari dengan daftar transaksi.
  DateTime now();
}

class SystemClock implements AppClock {
  const SystemClock();

  @override
  DateTime now() => DateTime.now();
}

/// Hanya untuk test. TIDAK diregistrasikan di `injection_container.dart`.
class FixedClock implements AppClock {
  FixedClock(this._at);

  DateTime _at;

  set at(DateTime value) => _at = value;

  @override
  DateTime now() => _at;
}
