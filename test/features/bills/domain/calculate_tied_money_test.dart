import 'package:flutter_test/flutter_test.dart';
import 'package:penyintas_app/features/bills/domain/entities/bill_entity.dart';
import 'package:penyintas_app/features/bills/domain/usecases/calculate_tied_money.dart';

BillEntity _makeBill({
  int id = 1,
  String? cloudId,
  String name = 'Kos Bu Tini',
  int estimatedAmount = 750000,
  String category = 'housing',
  bool isFixedNeed = true,
  String? notes,
  DateTime? dueDate,
  Recurrence recurrence = Recurrence.monthly,
  int? installmentTotal,
  int installmentsPaid = 0,
  DateTime? recurrenceEndDate,
  int? dueDayOfMonth = 5,
  int? reminderDaysBefore = 3,
  bool reminderEnabled = true,
  BillStatus status = BillStatus.active,
  DateTime? createdAt,
  DateTime? updatedAt,
}) => BillEntity(
  id: id,
  cloudId: cloudId,
  name: name,
  estimatedAmount: estimatedAmount,
  category: category,
  isFixedNeed: isFixedNeed,
  notes: notes,
  dueDate: dueDate ?? DateTime(2026, 8, 5),
  recurrence: recurrence,
  installmentTotal: installmentTotal,
  installmentsPaid: installmentsPaid,
  recurrenceEndDate: recurrenceEndDate,
  dueDayOfMonth: dueDayOfMonth,
  reminderDaysBefore: reminderDaysBefore,
  reminderEnabled: reminderEnabled,
  status: status,
  createdAt: createdAt ?? DateTime(2026, 1, 1),
  updatedAt: updatedAt ?? DateTime(2026, 1, 1),
);

void main() {
  group('calculateTiedMoney', () {
    test('3 bill, 2 sebelum gajian -> tied = jumlah keduanya saja', () {
      final billA = _makeBill(
        id: 1,
        name: 'Bill A',
        estimatedAmount: 500000,
        dueDate: DateTime(2026, 7, 12),
      );
      final billB = _makeBill(
        id: 2,
        name: 'Bill B',
        estimatedAmount: 300000,
        dueDate: DateTime(2026, 7, 20),
      );
      final billC = _makeBill(
        id: 3,
        name: 'Bill C',
        estimatedAmount: 900000,
        dueDate: DateTime(2026, 7, 28), // SESUDAH gajian (25 Jul)
      );

      final result = calculateTiedMoney(
        activeBills: [billA, billB, billC],
        today: DateTime(2026, 7, 10),
        paymentDate: 25,
        balance: 2000000,
      );

      expect(result.tied, 800000);
      expect(result.safe, 1200000);
    });

    test('bill dueDate PERSIS hari gajian TIDAK dihitung (kunci anti-sabotase, '
        'isBefore harus strict <)', () {
      final billTepatGajian = _makeBill(
        estimatedAmount: 400000,
        dueDate: DateTime(2026, 7, 25), // PERSIS horizon
      );

      final result = calculateTiedMoney(
        activeBills: [billTepatGajian],
        today: DateTime(2026, 7, 10),
        paymentDate: 25,
        balance: 1000000,
      );

      expect(result.tied, 0);
      expect(result.safe, 1000000);
    });

    test('daftar bill kosong -> tied 0, safe = balance', () {
      final result = calculateTiedMoney(
        activeBills: const [],
        today: DateTime(2026, 7, 10),
        paymentDate: 25,
        balance: 1000000,
      );

      expect(result.tied, 0);
      expect(result.safe, 1000000);
    });

    test('safe negatif ketika tagihan melebihi saldo -> JANGAN di-clamp', () {
      final billBesar = _makeBill(
        estimatedAmount: 1500000,
        dueDate: DateTime(2026, 7, 15),
      );

      final result = calculateTiedMoney(
        activeBills: [billBesar],
        today: DateTime(2026, 7, 10),
        paymentDate: 25,
        balance: 1000000,
      );

      expect(result.tied, 1500000);
      expect(result.safe, -500000);
    });

    test(
      'horizon menyeberang bulan (today = paymentDate, maju bulan depan)',
      () {
        final billAwalAgustus = _makeBill(
          estimatedAmount: 600000,
          dueDate: DateTime(2026, 8, 10),
        );

        final result = calculateTiedMoney(
          activeBills: [billAwalAgustus],
          today: DateTime(2026, 7, 26),
          paymentDate: 25,
          balance: 1000000,
        );

        // nextPayday(26 Jul, paymentDate=25) -> 25 Agu 2026 (candidate 25 Jul
        // sudah lewat -> maju bulan). Bill 10 Agu < 25 Agu -> ikut tied.
        expect(result.tied, 600000);
        expect(result.safe, 400000);
      },
    );
  });
}
