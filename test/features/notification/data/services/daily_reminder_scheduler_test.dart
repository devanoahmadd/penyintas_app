import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:penyintas_app/core/database/app_database.dart';
import 'package:penyintas_app/core/utils/app_clock.dart';
import 'package:penyintas_app/features/notification/data/datasources/notification_local_datasource.dart';
import 'package:penyintas_app/features/notification/data/services/daily_reminder_scheduler.dart';
import 'package:penyintas_app/features/streak/domain/repositories/streak_repository.dart';

class _MockLocal extends Mock implements NotificationLocalDatasource {}

class _MockStreakRepo extends Mock implements StreakRepository {}

/// Gerbang SATU PINTU penjadwalan pengingat harian.
///
/// Yang dikunci di sini adalah keputusan "lewati hari ini atau tidak" — satu
/// tempat yang dilewati SEMUA pemanggil (`_onInit` tiap cold start,
/// `_onSchedule`, `_onCancel`, dan `StreakBloc` sesudah penandaan/undo).
void main() {
  late _MockLocal local;
  late _MockStreakRepo streak;
  late AppDatabase db;
  late FixedClock clock;

  /// Pukul 10:00 — sebelum jam pengingat baku (20:00).
  DateTime pagi() => DateTime(2026, 9, 5, 10);

  DailyReminderScheduler buat() => DailyReminderScheduler(
    local: local,
    streak: streak,
    db: db,
    clock: clock,
  );

  Future<void> pasangSettings({
    bool enabled = true,
    int hour = 20,
    int minute = 0,
  }) => db
      .into(db.appSettings)
      .insertOnConflictUpdate(
        AppSettingsCompanion(
          id: const Value(1),
          reminderEnabled: Value(enabled),
          reminderHour: Value(hour),
          reminderMinute: Value(minute),
        ),
      );

  setUp(() {
    local = _MockLocal();
    streak = _MockStreakRepo();
    db = AppDatabase(NativeDatabase.memory());
    clock = FixedClock(pagi());
    when(() => local.cancelDailyReminder()).thenAnswer((_) async {});
    when(
      () => local.scheduleDailyReminder(
        hour: any(named: 'hour'),
        minute: any(named: 'minute'),
        skipToday: any(named: 'skipToday'),
      ),
    ).thenAnswer((_) async {});
    when(() => streak.isTodaySafe()).thenAnswer((_) async => false);
  });

  tearDown(() async => db.close());

  test('pengingat mati → cancel, tidak menjadwalkan apa pun', () async {
    await pasangSettings(enabled: false);

    await buat().reschedule();

    verify(() => local.cancelDailyReminder()).called(1);
    verifyNever(
      () => local.scheduleDailyReminder(
        hour: any(named: 'hour'),
        minute: any(named: 'minute'),
        skipToday: any(named: 'skipToday'),
      ),
    );
    verifyNever(() => streak.isTodaySafe());
  });

  test('hari sudah aman DAN sekarang masih sebelum jam pengingat '
      '→ skipToday true', () async {
    await pasangSettings(hour: 20, minute: 0);
    when(() => streak.isTodaySafe()).thenAnswer((_) async => true);
    clock.at = DateTime(2026, 9, 5, 10);

    await buat().reschedule();

    verify(
      () => local.scheduleDailyReminder(hour: 20, minute: 0, skipToday: true),
    ).called(1);
  });

  test('hari sudah aman TAPI sekarang sudah lewat jam pengingat '
      '→ skipToday false (jadwal berikutnya memang sudah besok)', () async {
    await pasangSettings(hour: 20, minute: 0);
    when(() => streak.isTodaySafe()).thenAnswer((_) async => true);
    clock.at = DateTime(2026, 9, 5, 21);

    await buat().reschedule();

    verify(
      () => local.scheduleDailyReminder(hour: 20, minute: 0, skipToday: false),
    ).called(1);
  });

  test('batas menit — jam sama, menit belum lewat → skipToday true; '
      'menit persis sama → false', () async {
    await pasangSettings(hour: 20, minute: 30);
    when(() => streak.isTodaySafe()).thenAnswer((_) async => true);

    clock.at = DateTime(2026, 9, 5, 20, 29);
    await buat().reschedule();
    verify(
      () => local.scheduleDailyReminder(hour: 20, minute: 30, skipToday: true),
    ).called(1);

    clock.at = DateTime(2026, 9, 5, 20, 30);
    await buat().reschedule();
    verify(
      () => local.scheduleDailyReminder(hour: 20, minute: 30, skipToday: false),
    ).called(1);
  });

  test('hari belum aman → skipToday false', () async {
    await pasangSettings(hour: 20, minute: 0);
    when(() => streak.isTodaySafe()).thenAnswer((_) async => false);

    await buat().reschedule();

    verify(
      () => local.scheduleDailyReminder(hour: 20, minute: 0, skipToday: false),
    ).called(1);
  });

  test(
    'isTodaySafe gagal → dianggap belum aman, pengingat TETAP dikirim',
    () async {
      await pasangSettings(hour: 20, minute: 0);
      // Kontrak `isTodaySafe()` sengaja BUKAN Either dan tidak melempar: saat
      // gagal ia mengembalikan `false`. Gagal ke arah "pengingat muncul" jauh
      // lebih murah daripada gagal ke arah "user kehilangan satu hari".
      when(() => streak.isTodaySafe()).thenAnswer((_) async => false);

      await buat().reschedule();

      verifyNever(() => local.cancelDailyReminder());
      verify(
        () =>
            local.scheduleDailyReminder(hour: 20, minute: 0, skipToday: false),
      ).called(1);
    },
  );

  test(
    'idempoten: dua reschedule beruntun menghasilkan keadaan yang sama',
    () async {
      await pasangSettings(hour: 20, minute: 0);
      when(() => streak.isTodaySafe()).thenAnswer((_) async => true);

      final scheduler = buat();
      await scheduler.reschedule();
      await scheduler.reschedule();

      verify(
        () => local.scheduleDailyReminder(hour: 20, minute: 0, skipToday: true),
      ).called(2);
      verifyNever(() => local.cancelDailyReminder());
    },
  );

  test('T35 — baris app_settings TIDAK ADA → no-op, BUKAN cancel', () async {
    // Persis keadaan sesudah logout: `clearAllLocalData()` menyapu
    // `app_settings` dan hanya `preferences` yang dibuat ulang; barisnya baru
    // pulih lewat bootstrap, sementara `InitNotification` jalan di TIAP cold
    // start dan bisa lebih dulu. Membatalkan di sini akan mematikan pengingat
    // harian diam-diam pada pembukaan pertama sesudah login.
    await db.delete(db.appSettings).go();

    await buat().reschedule();

    verifyNever(() => local.cancelDailyReminder());
    verifyNever(
      () => local.scheduleDailyReminder(
        hour: any(named: 'hour'),
        minute: any(named: 'minute'),
        skipToday: any(named: 'skipToday'),
      ),
    );
  });
}
