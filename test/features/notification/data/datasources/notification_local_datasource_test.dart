import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:penyintas_app/core/database/app_database.dart';
import 'package:penyintas_app/features/notification/data/datasources/notification_local_datasource.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

const _channel = MethodChannel('dexterous.com/flutter/local_notifications');

/// Pasang `tz.local` ke zona ber-offset tetap sehingga jam LOKAL "sekarang"
/// selalu jatuh pada pukul 12 siang.
///
/// Tanpa ini, asersi "jam pengingat hari ini BELUM lewat" bergantung pada jam
/// nyata saat suite dijalankan — dan berubah jadi hijau palsu setiap kali
/// suite kebetulan jalan sesudah pukul 20 malam.
void _pasangZonaSiangHari() {
  final utc = DateTime.now().toUtc();
  var offset = (12 - utc.hour) % 24;
  if (offset > 12) offset -= 24;
  final nama = offset == 0
      ? 'Etc/GMT'
      : (offset > 0 ? 'Etc/GMT-$offset' : 'Etc/GMT+${-offset}');
  tz.setLocalLocation(tz.getLocation(nama));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late NotificationLocalDatasource local;
  late List<MethodCall> panggilan;

  setUpAll(() {
    tz_data.initializeTimeZones();
    // `initialize()` datasource memakai FlutterTimezone (butuh platform
    // channel plugin lain); zona dipasang langsung di sini supaya test ini
    // hanya menguji penjadwalan.
    AndroidFlutterLocalNotificationsPlugin.registerWith();
  });

  setUp(() {
    _pasangZonaSiangHari();
    db = AppDatabase(NativeDatabase.memory());
    local = NotificationLocalDatasourceImpl(db);
    panggilan = [];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, (call) async {
          panggilan.add(call);
          return null;
        });
  });

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, null);
    await db.close();
  });

  Future<void> pasangBahasa(String kode) => db
      .into(db.preferences)
      .insertOnConflictUpdate(
        PreferencesCompanion(id: const Value(1), language: Value(kode)),
      );

  Map<Object?, Object?> argsJadwal() =>
      panggilan.lastWhere((c) => c.method == 'zonedSchedule').arguments
          as Map<Object?, Object?>;

  DateTime tanggalTerjadwal() =>
      DateTime.parse(argsJadwal()['scheduledDateTime']! as String);

  /// Hari ini pukul [hour]:[minute] menurut `tz.local` — yang dihitung
  /// datasource sebelum menerapkan aturan "geser ke besok".
  tz.TZDateTime naif(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    return tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
  }

  test('skipToday true → dijadwalkan BESOK walau jam pengingat hari ini '
      'belum lewat', () async {
    await pasangBahasa('id');

    await local.scheduleDailyReminder(hour: 20, minute: 0, skipToday: true);

    final harapan = naif(20, 0).add(const Duration(days: 1));
    final hasil = tanggalTerjadwal();
    expect(
      DateTime(hasil.year, hasil.month, hasil.day, hasil.hour, hasil.minute),
      DateTime(
        harapan.year,
        harapan.month,
        harapan.day,
        harapan.hour,
        harapan.minute,
      ),
      reason:
          'tanpa `skipToday`, penjadwalan jatuh hari ini pukul 20:00 dan '
          'pengingat tetap datang di hari yang sudah aman',
    );
  });

  test(
    'skipToday false (baku) dan jam belum lewat → dijadwalkan HARI INI',
    () async {
      await pasangBahasa('id');

      await local.scheduleDailyReminder(hour: 20, minute: 0);

      final harapan = naif(20, 0);
      final hasil = tanggalTerjadwal();
      expect(
        DateTime(hasil.year, hasil.month, hasil.day, hasil.hour, hasil.minute),
        DateTime(
          harapan.year,
          harapan.month,
          harapan.day,
          harapan.hour,
          harapan.minute,
        ),
      );
    },
  );

  test('payload yang dikirim adalah /consistency', () async {
    await pasangBahasa('id');

    await local.scheduleDailyReminder(hour: 20, minute: 0);

    expect(argsJadwal()['payload'], '/consistency');
  });

  test('teks pengingat mengikuti preferences.language — id', () async {
    await pasangBahasa('id');

    await local.scheduleDailyReminder(hour: 20, minute: 0);

    expect(argsJadwal()['title'], 'Jangan lupa catat pengeluaran hari ini!');
    expect(
      argsJadwal()['body'],
      'Satu catatan kecil sekarang, lebih aman sampai akhir bulan.',
    );
  });

  test('teks pengingat mengikuti preferences.language — en', () async {
    await pasangBahasa('en');

    await local.scheduleDailyReminder(hour: 20, minute: 0);

    expect(argsJadwal()['title'], "Don't forget to log today's spending!");
    expect(
      argsJadwal()['body'],
      "One small note now, safer until month's end.",
    );
  });

  test(
    'baris preferences belum ada → jatuh ke bahasa Indonesia, bukan crash',
    () async {
      await local.scheduleDailyReminder(hour: 20, minute: 0);

      expect(argsJadwal()['title'], 'Jangan lupa catat pengeluaran hari ini!');
    },
  );

  test(
    'pengulangan harian dipertahankan (matchDateTimeComponents.time)',
    () async {
      await pasangBahasa('id');

      await local.scheduleDailyReminder(hour: 20, minute: 0, skipToday: true);

      expect(
        argsJadwal()['matchDateTimeComponents'],
        DateTimeComponents.time.index,
        reason:
            'user yang berminggu-minggu tak membuka app tetap harus diingatkan',
      );
    },
  );
}
