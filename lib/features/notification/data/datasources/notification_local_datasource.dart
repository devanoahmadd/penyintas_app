import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

abstract class NotificationLocalDatasource {
  Future<void> initialize({required void Function(String? payload) onTap});
  Future<bool> requestPermission();
  Future<void> scheduleDailyReminder({required int hour, required int minute});
  Future<void> cancelDailyReminder();

  /// Tampilkan notifikasi seketika (dipakai untuk pesan FCM saat app
  /// foreground — FCM tak meng-auto-display di state ini). [payload] dikirim
  /// balik saat notif diketuk untuk navigasi.
  Future<void> show({
    required String title,
    required String body,
    String? payload,
  });
}

class NotificationLocalDatasourceImpl implements NotificationLocalDatasource {
  final _plugin = FlutterLocalNotificationsPlugin();

  static const _dailyReminderId = 1;
  static const _channelId = 'penyintas_daily';
  static const _channelName = 'Pengingat Harian';

  // Channel khusus peringatan anggaran (heads-up). Channel terpisah karena
  // importance Android 8+ immutable setelah dibuat — reminder harian pakai
  // defaultImportance, alert butuh high.
  static const _alertChannelId = 'penyintas_alerts';
  static const _alertChannelName = 'Peringatan Anggaran';

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
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();

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

  @override
  Future<void> scheduleDailyReminder({
    required int hour,
    required int minute,
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
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      id: _dailyReminderId,
      title: 'Jangan lupa catat pengeluaran hari ini!',
      body: 'Satu catatan kecil sekarang, lebih aman sampai akhir bulan.',
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
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  @override
  Future<void> cancelDailyReminder() =>
      _plugin.cancel(id: _dailyReminderId);

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
}
