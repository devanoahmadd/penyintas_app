import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:penyintas_app/features/bills/data/datasources/bill_reminder_scheduler.dart';
import 'package:penyintas_app/features/bills/domain/entities/bill_entity.dart';
import 'package:penyintas_app/features/notification/data/datasources/notification_local_datasource.dart';

class MockNotificationLocalDatasource extends Mock
    implements NotificationLocalDatasource {}

BillEntity _makeBill({
  required int id,
  String name = 'Kos Bu Tini',
  int estimatedAmount = 750000,
  DateTime? dueDate,
  int? reminderDaysBefore,
  bool reminderEnabled = true,
  BillStatus status = BillStatus.active,
}) => BillEntity(
  id: id,
  name: name,
  estimatedAmount: estimatedAmount,
  category: 'housing',
  isFixedNeed: true,
  dueDate: dueDate ?? DateTime(2026, 8, 10),
  recurrence: Recurrence.monthly,
  installmentsPaid: 0,
  dueDayOfMonth: 10,
  reminderDaysBefore: reminderDaysBefore,
  reminderEnabled: reminderEnabled,
  status: status,
  createdAt: DateTime(2026, 7, 1),
  updatedAt: DateTime(2026, 7, 1),
);

void main() {
  late MockNotificationLocalDatasource mockNotif;
  late BillReminderSchedulerImpl scheduler;

  // "Sekarang" tetap agar uji waktu-lampau deterministik.
  final fixedNow = DateTime(2026, 7, 29, 12);

  setUpAll(() {
    registerFallbackValue(DateTime(2026));
  });

  setUp(() {
    mockNotif = MockNotificationLocalDatasource();
    scheduler = BillReminderSchedulerImpl(mockNotif, now: () => fixedNow);

    when(() => mockNotif.requestPermission()).thenAnswer((_) async => true);
    when(() => mockNotif.cancelBillReminder(any())).thenAnswer((_) async {});
    when(
      () => mockNotif.scheduleBillReminder(
        id: any(named: 'id'),
        scheduledDate: any(named: 'scheduledDate'),
        title: any(named: 'title'),
        body: any(named: 'body'),
        payload: any(named: 'payload'),
      ),
    ).thenAnswer((_) async {});
  });

  test(
    'notifIdOf: ID deterministik di band 2.000.000 (tak bentrok daily/alert)',
    () {
      expect(BillReminderScheduler.kBillNotifIdBase, 2000000);
      expect(BillReminderScheduler.notifIdOf(7), 2000007);
      // Band terpisah dari daily (1) dan alert (1000–1999).
      expect(BillReminderScheduler.notifIdOf(0), greaterThan(1999));
    },
  );

  test(
    '(a) 2 bill aktif → 2 jadwal dengan id berbeda & waktu = dueDate − leadDays @ jam global',
    () async {
      final bills = [
        _makeBill(id: 7, dueDate: DateTime(2026, 8, 10)),
        _makeBill(id: 9, dueDate: DateTime(2026, 8, 20)),
      ];

      await scheduler.rescheduleAll(bills, globalDaysBefore: 2, globalHour: 9);

      final captured = verify(
        () => mockNotif.scheduleBillReminder(
          id: captureAny(named: 'id'),
          scheduledDate: captureAny(named: 'scheduledDate'),
          title: any(named: 'title'),
          body: any(named: 'body'),
          payload: any(named: 'payload'),
        ),
      ).captured;

      // 2 panggilan × 2 argumen yang di-capture
      expect(captured.length, 4);
      expect(captured[0], 2000007);
      expect(captured[1], DateTime(2026, 8, 8, 9));
      expect(captured[2], 2000009);
      expect(captured[3], DateTime(2026, 8, 18, 9));

      // Idempoten: tiap bill di-cancel dulu sebelum dijadwalkan ulang.
      verify(() => mockNotif.cancelBillReminder(2000007)).called(1);
      verify(() => mockNotif.cancelBillReminder(2000009)).called(1);
    },
  );

  test(
    '(b) reminderEnabled=false → tidak dijadwalkan, tapi cancel TETAP dipanggil',
    () async {
      final bills = [
        _makeBill(id: 5, reminderEnabled: false),
        _makeBill(id: 6, dueDate: DateTime(2026, 8, 10)),
      ];

      await scheduler.rescheduleAll(bills, globalDaysBefore: 2, globalHour: 9);

      verifyNever(
        () => mockNotif.scheduleBillReminder(
          id: 2000005,
          scheduledDate: any(named: 'scheduledDate'),
          title: any(named: 'title'),
          body: any(named: 'body'),
          payload: any(named: 'payload'),
        ),
      );
      // Jadwal lama harus tetap dibersihkan.
      verify(() => mockNotif.cancelBillReminder(2000005)).called(1);

      // Bill lain tetap terjadwal — guard tidak boleh menghentikan loop.
      verify(
        () => mockNotif.scheduleBillReminder(
          id: 2000006,
          scheduledDate: any(named: 'scheduledDate'),
          title: any(named: 'title'),
          body: any(named: 'body'),
          payload: any(named: 'payload'),
        ),
      ).called(1);
    },
  );

  test(
    '(c) reminderDaysBefore per-bill (3) menang atas globalDaysBefore (1)',
    () async {
      final bills = [
        _makeBill(id: 4, dueDate: DateTime(2026, 8, 10), reminderDaysBefore: 3),
      ];

      await scheduler.rescheduleAll(bills, globalDaysBefore: 1, globalHour: 8);

      final captured = verify(
        () => mockNotif.scheduleBillReminder(
          id: any(named: 'id'),
          scheduledDate: captureAny(named: 'scheduledDate'),
          title: any(named: 'title'),
          body: any(named: 'body'),
          payload: any(named: 'payload'),
        ),
      ).captured;

      expect(captured.length, 1);
      // dueDate − 3 hari (override), BUKAN − 1 hari (global).
      expect(captured.single, DateTime(2026, 8, 7, 8));
    },
  );

  test('(d) waktu jadwal sudah lampau → skip, cancel tetap dipanggil', () async {
    final bills = [
      // dueDate kemarin relatif fixedNow (2026-07-29) → jadwal jauh di masa lalu.
      _makeBill(id: 11, dueDate: DateTime(2026, 7, 28), reminderDaysBefore: 2),
    ];

    await scheduler.rescheduleAll(bills, globalDaysBefore: 2, globalHour: 9);

    verifyNever(
      () => mockNotif.scheduleBillReminder(
        id: any(named: 'id'),
        scheduledDate: any(named: 'scheduledDate'),
        title: any(named: 'title'),
        body: any(named: 'body'),
        payload: any(named: 'payload'),
      ),
    );
    verify(() => mockNotif.cancelBillReminder(2000011)).called(1);
  });

  test(
    '(e) izin ditolak → tidak menjadwalkan apa pun & tidak melempar',
    () async {
      when(() => mockNotif.requestPermission()).thenAnswer((_) async => false);

      final bills = [_makeBill(id: 1), _makeBill(id: 2)];

      await expectLater(
        scheduler.rescheduleAll(bills, globalDaysBefore: 2, globalHour: 9),
        completes,
      );

      verifyNever(
        () => mockNotif.scheduleBillReminder(
          id: any(named: 'id'),
          scheduledDate: any(named: 'scheduledDate'),
          title: any(named: 'title'),
          body: any(named: 'body'),
          payload: any(named: 'payload'),
        ),
      );
    },
  );

  test(
    '(f) cancelFor(billId) → cancelBillReminder(2000000 + billId)',
    () async {
      await scheduler.cancelFor(42);

      verify(() => mockNotif.cancelBillReminder(2000042)).called(1);
    },
  );
}
