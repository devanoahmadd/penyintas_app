import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:penyintas_app/core/database/app_database.dart';
import 'package:penyintas_app/core/l10n/app_localizations.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

abstract class NotificationLocalDatasource {
  Future<void> initialize({required void Function(String? payload) onTap});
  Future<bool> requestPermission();

  /// Jadwalkan pengingat harian pada [hour]:[minute] waktu lokal.
  ///
  /// [skipToday] datang dari `DailyReminderScheduler` — SATU-SATUNYA tempat
  /// yang tahu soal streak. Datasource ini tetap primitif bodoh: ia hanya
  /// menggeser jadwal ke besok bila diminta.
  Future<void> scheduleDailyReminder({
    required int hour,
    required int minute,
    bool skipToday = false,
  });
  Future<void> cancelDailyReminder();

  /// Tampilkan notifikasi seketika (dipakai untuk pesan FCM saat app
  /// foreground — FCM tak meng-auto-display di state ini). [payload] dikirim
  /// balik saat notif diketuk untuk navigasi.
  Future<void> show({
    required String title,
    required String body,
    String? payload,
  });

  /// Jadwalkan satu pengingat tagihan pada [scheduledDate] (waktu lokal).
  ///
  /// Sekali-jalan (bukan berulang harian) — pemanggil bertanggung jawab
  /// menjadwalkan ulang setelah tagihan bergulir ke periode berikutnya.
  /// [id] harus deterministik per tagihan agar bisa dibatalkan/ditimpa.
  Future<void> scheduleBillReminder({
    required int id,
    required DateTime scheduledDate,
    required String title,
    required String body,
    String? payload,
  });

  /// Batalkan pengingat tagihan ber-[id].
  Future<void> cancelBillReminder(int id);

  /// Batalkan SEMUA notifikasi terjadwal — pengingat harian, peringatan
  /// anggaran, dan pengingat tagihan sekaligus.
  ///
  /// Dipakai saat sesi berakhir (logout / hapus akun). Sengaja menyapu semua
  /// alih-alih membatalkan satu per satu dari daftar tagihan: notifikasi yang
  /// tagihannya sudah hilang dari database tak akan pernah masuk daftar itu,
  /// jadi pembatalan per-id justru meninggalkan notifikasi yatim.
  Future<void> cancelAllScheduled();
}

class NotificationLocalDatasourceImpl implements NotificationLocalDatasource {
  NotificationLocalDatasourceImpl(this._db);

  /// Dibutuhkan HANYA untuk membaca `preferences.language`: penjadwalan
  /// terjadi di luar widget tree, jadi teks notifikasi tak bisa diambil lewat
  /// `AppLocalizations.of(context)`.
  final AppDatabase _db;

  final _plugin = FlutterLocalNotificationsPlugin();

  static const _dailyReminderId = 1;
  static const _channelId = 'penyintas_daily';
  static const _channelName = 'Pengingat Harian';

  // Channel khusus peringatan anggaran (heads-up). Channel terpisah karena
  // importance Android 8+ immutable setelah dibuat — reminder harian pakai
  // defaultImportance, alert butuh high.
  static const _alertChannelId = 'penyintas_alerts';
  static const _alertChannelName = 'Peringatan Anggaran';

  // Channel khusus pengingat tagihan. Terpisah dari dua channel di atas supaya
  // pengguna bisa membisukan pengingat tagihan saja tanpa kehilangan peringatan
  // anggaran (importance channel Android 8+ immutable setelah dibuat).
  static const _billsChannelId = 'penyintas_bills';
  static const _billsChannelName = 'Pengingat Tagihan';

  // ID band 1000–1999 agar tak pernah bentrok reminder (id=1) & multi-kategori
  // menumpuk seperti perilaku notif background.
  int _alertSeq = 0;

  // v21 API: semua parameter named
  @override
  Future<void> initialize({
    required void Function(String? payload) onTap,
  }) async {
    tz_data.initializeTimeZones();
    final tzInfo = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(tzInfo.identifier));

    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
      onDidReceiveNotificationResponse: (details) => onTap(details.payload),
    );
  }

  @override
  Future<bool> requestPermission() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    final ios = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();

    if (android != null) {
      return await android.requestNotificationsPermission() ?? false;
    }
    if (ios != null) {
      return await ios.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ??
          false;
    }
    return true;
  }

  /// Resolver l10n tanpa `BuildContext` — penjadwalan terjadi di luar widget
  /// tree. `delegateFor(...).load(...)` membaca `assets/translations/*.json`
  /// langsung lewat `rootBundle`.
  Future<AppLocalizations> _l10n() async {
    final row = await (_db.select(
      _db.preferences,
    )..where((t) => t.id.equals(1))).getSingleOrNull();
    final lang = row?.language ?? 'id';
    final locale = Locale(lang);
    return AppLocalizations.delegateFor(locale).load(locale);
  }

  @override
  Future<void> scheduleDailyReminder({
    required int hour,
    required int minute,
    bool skipToday = false,
  }) async {
    await cancelDailyReminder();

    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (skipToday || scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    final l10n = await _l10n();
    await _plugin.zonedSchedule(
      id: _dailyReminderId,
      title: l10n.notificationDailyTitle,
      body: l10n.notificationDailyBody,
      scheduledDate: scheduled,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      // DIPERTAHANKAN: pengulangan hariannya harus jalan terus supaya user
      // yang berminggu-minggu tak membuka app tetap diingatkan.
      matchDateTimeComponents: DateTimeComponents.time,
      // Ketukan mengarah ke halaman Konsistensi (spec §7.3);
      // `notification_bloc.dart` meneruskan payload jadi `NotificationTapped`.
      payload: '/consistency',
    );
  }

  @override
  Future<void> cancelDailyReminder() => _plugin.cancel(id: _dailyReminderId);

  @override
  Future<void> show({
    required String title,
    required String body,
    String? payload,
  }) async {
    await _plugin.show(
      id: 1000 + (_alertSeq++ % 1000),
      title: title,
      body: body,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _alertChannelId,
          _alertChannelName,
          channelDescription:
              'Peringatan saat pengeluaran mendekati atau melewati batas.',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: payload,
    );
  }

  @override
  Future<void> scheduleBillReminder({
    required int id,
    required DateTime scheduledDate,
    required String title,
    required String body,
    String? payload,
  }) async {
    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: tz.TZDateTime.from(scheduledDate, tz.local),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _billsChannelId,
          _billsChannelName,
          channelDescription: 'Pengingat menjelang jatuh tempo tagihan.',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      // TANPA matchDateTimeComponents — pengingat tagihan sekali-jalan,
      // bukan pengulangan harian seperti scheduleDailyReminder.
      payload: payload,
    );
  }

  @override
  Future<void> cancelBillReminder(int id) => _plugin.cancel(id: id);

  @override
  Future<void> cancelAllScheduled() => _plugin.cancelAll();
}
