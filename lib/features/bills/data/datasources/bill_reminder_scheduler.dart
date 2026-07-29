import 'package:penyintas_app/core/utils/currency_formatter.dart';
import 'package:penyintas_app/features/bills/domain/entities/bill_entity.dart';
import 'package:penyintas_app/features/notification/data/datasources/notification_local_datasource.dart';

/// Penjadwal pengingat tagihan lokal (tz-aware lewat
/// [NotificationLocalDatasource.scheduleBillReminder]).
///
/// Scheduler ini TIDAK menyentuh plugin notifikasi langsung — semua akses
/// notifikasi lewat datasource supaya tetap bisa di-mock di test.
abstract class BillReminderScheduler {
  /// Basis ID notifikasi tagihan.
  ///
  /// Band ID dipisah dari pemakaian lain agar tak pernah bentrok:
  /// pengingat harian = `1`, peringatan anggaran = `1000–1999`,
  /// pengingat tagihan = `2000000 + bill.id`.
  static const kBillNotifIdBase = 2000000;

  /// ID notifikasi deterministik untuk sebuah tagihan.
  ///
  /// Deterministik agar jadwal lama selalu bisa ditimpa/dibatalkan tanpa
  /// menyimpan state tambahan. ID lokal (per-device) — aman karena notifikasi
  /// memang per-device dan `bill.id` stabil di dalam satu device.
  static int notifIdOf(int billId) => kBillNotifIdBase + billId;

  /// Bangun ulang seluruh jadwal pengingat dari daftar bill AKTIF.
  ///
  /// Idempoten: tiap bill di-cancel dulu, lalu dijadwalkan ulang bila layak.
  Future<void> rescheduleAll(
    List<BillEntity> activeBills, {
    required int globalDaysBefore,
    required int globalHour,
  });

  /// Batalkan pengingat satu bill.
  ///
  /// Dipakai saat bill dihapus atau berubah jadi `completed` — bill itu TIDAK
  /// ada lagi di `activeBills` sehingga [rescheduleAll] tak bisa
  /// membatalkannya.
  Future<void> cancelFor(int billId);
}

class BillReminderSchedulerImpl implements BillReminderScheduler {
  BillReminderSchedulerImpl(this._notifications, {DateTime Function()? now})
    : _now = now ?? DateTime.now;

  final NotificationLocalDatasource _notifications;

  /// Sumber waktu "sekarang" — bisa disuntik agar test deterministik.
  final DateTime Function() _now;

  @override
  Future<void> rescheduleAll(
    List<BillEntity> activeBills, {
    required int globalDaysBefore,
    required int globalHour,
  }) async {
    // Izin ditolak → berhenti tenang, jangan lempar. Tanpa izin, penjadwalan
    // tak akan pernah tampil; menunda lebih baik daripada crash.
    final granted = await _notifications.requestPermission();
    if (!granted) return;

    final now = _now();

    for (final bill in activeBills) {
      final notifId = BillReminderScheduler.notifIdOf(bill.id);

      // Selalu cancel dulu — membuat rescheduleAll idempoten dan membersihkan
      // jadwal lama meski bill ini akhirnya di-skip.
      await _notifications.cancelBillReminder(notifId);

      if (!bill.reminderEnabled) continue;

      // Override per-bill MENANG atas global. null = "warisi global".
      final leadDays = bill.reminderDaysBefore ?? globalDaysBefore;

      // Kurangi hari lewat konstruktor DateTime (bukan subtract Duration) agar
      // komponen jam bersih dan tak tergeser perubahan offset/DST.
      final due = bill.dueDate;
      final scheduledDate = DateTime(
        due.year,
        due.month,
        due.day - leadDays,
        globalHour,
      );

      // Waktu lampau → tak ada gunanya dijadwalkan (jadwal lama sudah dibatalkan).
      if (!scheduledDate.isAfter(now)) continue;

      await _notifications.scheduleBillReminder(
        id: notifId,
        scheduledDate: scheduledDate,
        title: bill.name,
        body: _bodyFor(bill, leadDays),
        payload: 'bill:${bill.id}',
      );
    }
  }

  @override
  Future<void> cancelFor(int billId) => _notifications.cancelBillReminder(
    BillReminderScheduler.notifIdOf(billId),
  );

  String _bodyFor(BillEntity bill, int leadDays) {
    final nominal = formatRupiah(bill.estimatedAmount);
    if (leadDays <= 0) {
      return 'Jatuh tempo hari ini — $nominal. Yuk, selesaikan sekarang.';
    }
    return 'Jatuh tempo $leadDays hari lagi — $nominal. '
        'Siapkan dananya dari sekarang, ya.';
  }
}
