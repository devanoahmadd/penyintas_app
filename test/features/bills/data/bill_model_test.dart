import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:penyintas_app/core/database/app_database.dart';
import 'package:penyintas_app/features/bills/data/models/bill_model.dart';
import 'package:penyintas_app/features/bills/domain/entities/bill_entity.dart';

void main() {
  final tModel = BillModel(
    cloudId: 'cloud-abc',
    name: 'Kos Bu Tini',
    estimatedAmount: 850000,
    category: 'housing',
    isFixedNeed: true,
    notes: 'Bayar tanggal 1 tiap bulan',
    dueDate: DateTime.fromMillisecondsSinceEpoch(1798675200000),
    recurrence: Recurrence.monthly,
    installmentTotal: 12,
    installmentsPaid: 3,
    recurrenceEndDate: DateTime.fromMillisecondsSinceEpoch(1830297600000),
    dueDayOfMonth: 1,
    reminderDaysBefore: 3,
    reminderEnabled: true,
    status: BillStatus.active,
    createdAt: DateTime.fromMillisecondsSinceEpoch(1751700000000),
    updatedAt: DateTime.fromMillisecondsSinceEpoch(1751700000000),
  );

  test(
    'toFirestore: semua field terisi, tanggal epoch millis, enum via .name',
    () {
      final map = tModel.toFirestore();
      expect(map, {
        'name': 'Kos Bu Tini',
        'estimatedAmount': 850000,
        'category': 'housing',
        'isFixedNeed': true,
        'notes': 'Bayar tanggal 1 tiap bulan',
        'dueDate': 1798675200000,
        'recurrence': 'monthly',
        'installmentTotal': 12,
        'installmentsPaid': 3,
        'recurrenceEndDate': 1830297600000,
        'dueDayOfMonth': 1,
        'reminderDaysBefore': 3,
        'reminderEnabled': true,
        'status': 'active',
        'createdAt': 1751700000000,
        'updatedAt': 1751700000000,
      });
      // cloudId = docId Firestore itu sendiri — tidak diulang di dalam map
      // (pola sama dengan GoalModel.firestoreId).
      expect(map.containsKey('cloudId'), isFalse);
    },
  );

  test(
    'fromFirestore ∘ toFirestore = identitas (roundtrip, field terisi penuh)',
    () {
      final back = BillModel.fromFirestore('cloud-abc', tModel.toFirestore());
      expect(back.cloudId, tModel.cloudId);
      expect(back.name, tModel.name);
      expect(back.estimatedAmount, tModel.estimatedAmount);
      expect(back.category, tModel.category);
      expect(back.isFixedNeed, tModel.isFixedNeed);
      expect(back.notes, tModel.notes);
      expect(back.dueDate, tModel.dueDate);
      expect(back.recurrence, tModel.recurrence);
      expect(back.installmentTotal, tModel.installmentTotal);
      expect(back.installmentsPaid, tModel.installmentsPaid);
      expect(back.recurrenceEndDate, tModel.recurrenceEndDate);
      expect(back.dueDayOfMonth, tModel.dueDayOfMonth);
      expect(back.reminderDaysBefore, tModel.reminderDaysBefore);
      expect(back.reminderEnabled, tModel.reminderEnabled);
      expect(back.status, tModel.status);
      expect(back.createdAt, tModel.createdAt);
      expect(back.updatedAt, tModel.updatedAt);
    },
  );

  test(
    'fromFirestore ∘ toFirestore: field nullable null persis (recurrence=none)',
    () {
      final tNullable = BillModel(
        cloudId: 'cloud-none',
        name: 'Belanja bulanan',
        estimatedAmount: 300000,
        category: 'other',
        isFixedNeed: false,
        notes: null,
        dueDate: DateTime.fromMillisecondsSinceEpoch(1751700000000),
        recurrence: Recurrence.none,
        installmentTotal: null,
        installmentsPaid: 0,
        recurrenceEndDate: null,
        dueDayOfMonth: null,
        reminderDaysBefore: null,
        reminderEnabled: false,
        status: BillStatus.active,
        createdAt: DateTime.fromMillisecondsSinceEpoch(1751700000000),
        updatedAt: DateTime.fromMillisecondsSinceEpoch(1751700000000),
      );

      final back = BillModel.fromFirestore(
        'cloud-none',
        tNullable.toFirestore(),
      );
      expect(back.notes, isNull);
      expect(back.installmentTotal, isNull);
      expect(back.recurrenceEndDate, isNull);
      expect(back.dueDayOfMonth, isNull);
      expect(back.reminderDaysBefore, isNull);
      expect(back.recurrence, Recurrence.none);
      expect(back.installmentsPaid, 0);
    },
  );

  test('fromRow memetakan seluruh kolom termasuk cloudId & enum', () {
    final row = Bill(
      id: 9,
      cloudId: 'cloud-xyz',
      name: 'Listrik',
      estimatedAmount: 250000,
      category: 'utilities',
      isFixedNeed: true,
      notes: null,
      dueDate: DateTime(2026, 8, 20),
      recurrence: 'monthly',
      installmentTotal: null,
      installmentsPaid: 0,
      recurrenceEndDate: null,
      dueDayOfMonth: 20,
      reminderDaysBefore: 2,
      reminderEnabled: true,
      status: 'active',
      createdAt: DateTime(2026, 7, 1),
      updatedAt: DateTime(2026, 7, 1),
    );
    final model = BillModel.fromRow(row);
    expect(model.cloudId, 'cloud-xyz');
    expect(model.name, 'Listrik');
    expect(model.recurrence, Recurrence.monthly);
    expect(model.status, BillStatus.active);
    expect(model.dueDayOfMonth, 20);
  });

  test(
    'toCompanion: seluruh field terisi Value, enum sebagai String, id absent',
    () {
      final c = tModel.toCompanion();
      expect(c.id, const Value<int>.absent());
      expect(c.cloudId, const Value('cloud-abc'));
      expect(c.name, const Value('Kos Bu Tini'));
      expect(c.recurrence, const Value('monthly'));
      expect(c.status, const Value('active'));
      expect(c.installmentTotal, const Value(12));
      expect(c.dueDayOfMonth, const Value(1));
    },
  );
}
