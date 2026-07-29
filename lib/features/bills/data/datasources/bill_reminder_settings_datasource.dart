import 'package:drift/drift.dart';
import 'package:penyintas_app/core/database/app_database.dart';
import 'package:penyintas_app/features/bills/data/datasources/bill_reminder_scheduler.dart';
import 'package:penyintas_app/features/bills/domain/repositories/bill_repository.dart';

/// Setting pengingat tagihan GLOBAL — dipakai bill ber-`reminderDaysBefore ==
/// null` (mayoritas; override per-bill MENANG bila diisi, lihat
/// [BillReminderScheduler.rescheduleAll]).
typedef BillReminderSettings = ({int daysBefore, int hour});

/// Baca & tulis setting pengingat tagihan global
/// (`AppSettings.billReminderDaysBefore` / `billReminderHour`), sekaligus
/// titik picu [BillReminderScheduler.rescheduleAll] saat setting itu berubah
/// (Task 6.2).
///
/// Anti-bug kelas-C2: saat setting GLOBAL berubah, bill ber-override
/// `reminderDaysBefore == null` (mayoritas) WAJIB ikut dijadwal ulang — kalau
/// tidak, jam/hari pengingatnya jadi basi (tetap pakai nilai global LAMA).
/// [updateBillReminderSettings] menutup celah itu dengan menulis setting lalu
/// langsung memicu `rescheduleAll` dengan nilai BARU.
///
/// CATATAN: [updateBillReminderSettings] BELUM punya pemanggil UI — halaman
/// pengaturan pengingat tagihan menyusul (di luar scope Task 6.2). Method ini
/// sengaja disediakan lebih dulu (jalur tulis + hook reschedule) supaya sudah
/// teruji sebelum UI-nya dibangun. JANGAN dianggap dead code / dihapus.
abstract class BillReminderSettingsDatasource {
  /// Baca setting terkini. Fallback `(daysBefore: 1, hour: 9)` bila baris
  /// `AppSettings` (id=1) belum ada.
  Future<BillReminderSettings> read();

  /// Simpan setting BARU lalu jadwal-ulang seluruh bill aktif dengan nilai
  /// tersebut.
  Future<void> updateBillReminderSettings({
    required int daysBefore,
    required int hour,
  });
}

class BillReminderSettingsDatasourceImpl
    implements BillReminderSettingsDatasource {
  BillReminderSettingsDatasourceImpl(
    this._db,
    this._billRepository,
    this._scheduler,
  );

  final AppDatabase _db;
  final BillRepository _billRepository;
  final BillReminderScheduler _scheduler;

  static const BillReminderSettings _fallback = (daysBefore: 1, hour: 9);

  @override
  Future<BillReminderSettings> read() async {
    final row = await (_db.select(
      _db.appSettings,
    )..where((t) => t.id.equals(1))).getSingleOrNull();
    if (row == null) return _fallback;
    return (daysBefore: row.billReminderDaysBefore, hour: row.billReminderHour);
  }

  @override
  Future<void> updateBillReminderSettings({
    required int daysBefore,
    required int hour,
  }) async {
    await _db
        .into(_db.appSettings)
        .insertOnConflictUpdate(
          AppSettingsCompanion(
            id: const Value(1),
            billReminderDaysBefore: Value(daysBefore),
            billReminderHour: Value(hour),
          ),
        );

    // Ambil snapshot bill aktif TERKINI lalu jadwal ulang dgn nilai BARU.
    // Left (gagal baca) → skip diam-diam — setting sudah tersimpan, reschedule
    // penuh berikutnya (launch/edit bill) akan menyusul memakai nilai ini.
    final result = await _billRepository.watchActiveBills().first;
    final bills = result.fold((_) => null, (list) => list);
    if (bills == null) return;

    await _scheduler.rescheduleAll(
      bills,
      globalDaysBefore: daysBefore,
      globalHour: hour,
    );
  }
}
