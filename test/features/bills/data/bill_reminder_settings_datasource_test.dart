import 'package:dartz/dartz.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:penyintas_app/core/database/app_database.dart';
import 'package:penyintas_app/core/error/failures.dart';
import 'package:penyintas_app/features/bills/data/datasources/bill_reminder_scheduler.dart';
import 'package:penyintas_app/features/bills/data/datasources/bill_reminder_settings_datasource.dart';
import 'package:penyintas_app/features/bills/domain/entities/bill_entity.dart';
import 'package:penyintas_app/features/bills/domain/repositories/bill_repository.dart';

class MockBillRepository extends Mock implements BillRepository {}

class MockBillReminderScheduler extends Mock implements BillReminderScheduler {}

BillEntity _makeBill({
  required int id,
  int? reminderDaysBefore,
  DateTime? dueDate,
}) => BillEntity(
  id: id,
  name: 'Kos Bu Tini',
  estimatedAmount: 750000,
  category: 'housing',
  isFixedNeed: true,
  dueDate: dueDate ?? DateTime(2026, 8, 10),
  recurrence: Recurrence.monthly,
  installmentsPaid: 0,
  dueDayOfMonth: 10,
  reminderDaysBefore: reminderDaysBefore,
  reminderEnabled: true,
  status: BillStatus.active,
  createdAt: DateTime(2026, 7, 1),
  updatedAt: DateTime(2026, 7, 1),
);

void main() {
  late AppDatabase db;
  late MockBillRepository mockRepo;
  late MockBillReminderScheduler mockScheduler;
  late BillReminderSettingsDatasourceImpl ds;

  setUpAll(() {
    registerFallbackValue(<BillEntity>[]);
  });

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    mockRepo = MockBillRepository();
    mockScheduler = MockBillReminderScheduler();
    ds = BillReminderSettingsDatasourceImpl(db, mockRepo, mockScheduler);

    when(
      () => mockScheduler.rescheduleAll(
        any(),
        globalDaysBefore: any(named: 'globalDaysBefore'),
        globalHour: any(named: 'globalHour'),
      ),
    ).thenAnswer((_) async {});
  });

  tearDown(() => db.close());

  group('read()', () {
    test(
      'baris AppSettings belum ada → fallback (daysBefore: 1, hour: 9)',
      () async {
        final result = await ds.read();
        expect(result, (daysBefore: 1, hour: 9));
      },
    );

    test('baris AppSettings sudah ada → kembalikan nilai tersimpan', () async {
      await db
          .into(db.appSettings)
          .insertOnConflictUpdate(
            const AppSettingsCompanion(
              id: Value(1),
              billReminderDaysBefore: Value(3),
              billReminderHour: Value(20),
            ),
          );

      final result = await ds.read();
      expect(result, (daysBefore: 3, hour: 20));
    });
  });

  group('updateBillReminderSettings()', () {
    test(
      'menulis kolom billReminderDaysBefore/billReminderHour ke DB',
      () async {
        when(
          () => mockRepo.watchActiveBills(),
        ).thenAnswer((_) => Stream.value(const Right(<BillEntity>[])));

        await ds.updateBillReminderSettings(daysBefore: 2, hour: 20);

        final row = await (db.select(
          db.appSettings,
        )..where((t) => t.id.equals(1))).getSingleOrNull();
        expect(row?.billReminderDaysBefore, 2);
        expect(row?.billReminderHour, 20);
      },
    );

    test('(b) KRITIS anti-bug C2: hour 9→20 → rescheduleAll dipanggil ulang '
        'dgn globalHour BARU, bill ber-reminderDaysBefore==null tetap ikut '
        'dalam snapshot yang dijadwalkan ulang', () async {
      final nullOverrideBill = _makeBill(id: 1, reminderDaysBefore: null);
      final overrideBill = _makeBill(id: 2, reminderDaysBefore: 5);
      when(() => mockRepo.watchActiveBills()).thenAnswer(
        (_) => Stream.value(Right([nullOverrideBill, overrideBill])),
      );

      await ds.updateBillReminderSettings(daysBefore: 1, hour: 20);

      final captured = verify(
        () => mockScheduler.rescheduleAll(
          captureAny(),
          globalDaysBefore: 1,
          globalHour: 20,
        ),
      ).captured;
      expect(captured, hasLength(1));
      final billsPassed = captured.single as List<BillEntity>;
      expect(billsPassed, contains(nullOverrideBill));
      expect(billsPassed, contains(overrideBill));
    });

    test(
      'repository gagal baca (Left) → skip diam-diam, rescheduleAll TIDAK dipanggil',
      () async {
        when(() => mockRepo.watchActiveBills()).thenAnswer(
          (_) =>
              Stream.value(const Left(CacheFailure('Gagal memuat tagihan.'))),
        );

        await expectLater(
          ds.updateBillReminderSettings(daysBefore: 1, hour: 9),
          completes,
        );

        verifyNever(
          () => mockScheduler.rescheduleAll(
            any(),
            globalDaysBefore: any(named: 'globalDaysBefore'),
            globalHour: any(named: 'globalHour'),
          ),
        );
      },
    );
  });
}
