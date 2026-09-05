import 'package:penyintas_app/core/database/app_database.dart';
import 'package:penyintas_app/core/utils/app_clock.dart';
import 'package:penyintas_app/features/notification/data/datasources/notification_local_datasource.dart';
import 'package:penyintas_app/features/streak/domain/repositories/streak_repository.dart';

/// SATU PINTU penjadwalan pengingat harian.
///
/// Kenapa satu pintu, bukan parameter yang dititipkan pemanggil: `app.dart`
/// men-dispatch `InitNotification` di root provider SETIAP cold start, dan
/// dulu `_onInit` menjadwalkan ulang polos. Skenario nyata: user menandai
/// nihil pukul 10:00 → penjadwalan bergeser ke besok. User membuka app lagi
/// pukul 15:00 → penjadwalan polos → pengingat TETAP datang pukul 20:00 di
/// hari yang sudah aman. Keputusan "lewati hari ini" harus dihitung di satu
/// tempat yang semua pemanggil lewati.
///
/// Idempoten (cancel → reschedule) dan konvergen: karena `_onInit`
/// menjalankan ini di tiap cold start, keadaan apa pun yang menyimpang
/// diperbaiki pada pembukaan berikutnya.
class DailyReminderScheduler {
  DailyReminderScheduler({
    required NotificationLocalDatasource local,
    required StreakRepository streak,
    required AppDatabase db,
    required AppClock clock,
  }) : _local = local,
       _streak = streak,
       _db = db,
       _clock = clock;

  final NotificationLocalDatasource _local;
  final StreakRepository _streak;
  final AppDatabase _db;
  final AppClock _clock;

  Future<void> reschedule() async {
    final s = await (_db.select(
      _db.appSettings,
    )..where((t) => t.id.equals(1))).getSingleOrNull();

    // BARIS TIDAK ADA ≠ PENGINGAT DIMATIKAN (D-7). `clearAllLocalData()`
    // menyapu `app_settings` saat logout dan hanya `preferences` yang dibuat
    // ulang; barisnya baru pulih lewat bootstrap, sementara `app.dart`
    // men-dispatch `InitNotification` di SETIAP cold start — bisa lebih dulu.
    // Membatalkan di sini akan mematikan pengingat harian diam-diam pada
    // pembukaan pertama sesudah login. Kode existing memilih melewati; kita
    // pertahankan pilihan itu.
    if (s == null) return;

    if (!s.reminderEnabled) return _local.cancelDailyReminder();

    // Kontraknya sengaja bukan `Either`: gagal → `false` → pengingat TETAP
    // dikirim. Gagal ke arah "pengingat muncul" jauh lebih murah daripada
    // gagal ke arah "user kehilangan satu hari".
    final aman = await _streak.isTodaySafe();
    final now = _clock.now();
    final sebelumJamPengingat =
        now.hour < s.reminderHour ||
        (now.hour == s.reminderHour && now.minute < s.reminderMinute);

    await _local.scheduleDailyReminder(
      hour: s.reminderHour,
      minute: s.reminderMinute,
      // Hanya bermakna bila jam pengingat hari ini BELUM lewat; kalau sudah
      // lewat, jadwal berikutnya memang sudah besok dan tak ada yang perlu
      // didiamkan.
      skipToday: aman && sebelumJamPengingat,
    );
  }
}
