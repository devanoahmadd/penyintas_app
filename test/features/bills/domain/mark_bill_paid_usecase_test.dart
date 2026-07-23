import 'package:flutter_test/flutter_test.dart';
import 'package:penyintas_app/features/bills/domain/entities/bill_entity.dart';
import 'package:penyintas_app/features/bills/domain/usecases/mark_bill_paid_usecase.dart';

/// Fixture BillEntity — override field yang relevan per test.
BillEntity _makeBill({
  int id = 1,
  String category = 'housing',
  DateTime? dueDate,
  Recurrence recurrence = Recurrence.monthly,
  int? installmentTotal,
  int installmentsPaid = 0,
  DateTime? recurrenceEndDate,
  int? dueDayOfMonth = 25,
  BillStatus status = BillStatus.active,
}) => BillEntity(
  id: id,
  name: 'Kos Bu Tini',
  estimatedAmount: 750000,
  category: category,
  isFixedNeed: true,
  dueDate: dueDate ?? DateTime(2026, 7, 25),
  recurrence: recurrence,
  installmentTotal: installmentTotal,
  installmentsPaid: installmentsPaid,
  recurrenceEndDate: recurrenceEndDate,
  dueDayOfMonth: dueDayOfMonth,
  reminderEnabled: true,
  status: status,
  createdAt: DateTime(2026, 7, 1),
  updatedAt: DateTime(2026, 7, 1),
);

void main() {
  group('markBillPaid — bulanan biasa (tanpa tenor)', () {
    test(
      'installmentsPaid++ , dueDate maju 1 bulan, status tetap active',
      () {
        final bill = _makeBill(
          recurrence: Recurrence.monthly,
          dueDayOfMonth: 25,
          installmentsPaid: 0,
          dueDate: DateTime(2026, 7, 25),
        );

        final advance = markBillPaid(bill: bill);

        expect(advance.newInstallmentsPaid, 1);
        expect(advance.newDueDate, DateTime(2026, 8, 25));
        expect(advance.newStatus, BillStatus.active);
      },
    );
  });

  group('markBillPaid — tenor N habis (stop-check exact ==)', () {
    test(
      'installmentTotal=3, installmentsPaid=2 -> paid ke-3 => completed',
      () {
        final bill = _makeBill(
          recurrence: Recurrence.monthly,
          installmentTotal: 3,
          installmentsPaid: 2,
          dueDayOfMonth: 25,
          dueDate: DateTime(2026, 7, 25),
        );

        final advance = markBillPaid(bill: bill);

        expect(advance.newInstallmentsPaid, 3);
        expect(advance.newStatus, BillStatus.completed);
      },
    );

    test(
      'installmentTotal=3, installmentsPaid=0 -> masih di tengah tenor => active',
      () {
        final bill = _makeBill(
          recurrence: Recurrence.monthly,
          installmentTotal: 3,
          installmentsPaid: 0,
        );

        final advance = markBillPaid(bill: bill);

        expect(advance.newInstallmentsPaid, 1);
        expect(advance.newStatus, BillStatus.active);
      },
    );
  });

  group('markBillPaid — sekali (Recurrence.none)', () {
    test('status completed & dueDate TIDAK berubah', () {
      final bill = _makeBill(
        recurrence: Recurrence.none,
        installmentsPaid: 0,
        dueDate: DateTime(2026, 7, 25),
        dueDayOfMonth: null,
      );

      final advance = markBillPaid(bill: bill);

      expect(advance.newInstallmentsPaid, 1);
      expect(advance.newDueDate, DateTime(2026, 7, 25));
      expect(advance.newStatus, BillStatus.completed);
    });
  });

  group('markBillPaid — lewat recurrenceEndDate', () {
    test('newDueDate melewati recurrenceEndDate => completed', () {
      final bill = _makeBill(
        recurrence: Recurrence.monthly,
        dueDayOfMonth: 25,
        dueDate: DateTime(2026, 7, 25),
        recurrenceEndDate: DateTime(2026, 8, 1),
      );

      final advance = markBillPaid(bill: bill);

      // roll-forward -> 25 Aug 2026, > 1 Aug 2026 => stop.
      expect(advance.newDueDate, DateTime(2026, 8, 25));
      expect(advance.newStatus, BillStatus.completed);
    });

    test(
      'newDueDate masih di dalam recurrenceEndDate => tetap active',
      () {
        final bill = _makeBill(
          recurrence: Recurrence.monthly,
          dueDayOfMonth: 25,
          dueDate: DateTime(2026, 7, 25),
          recurrenceEndDate: DateTime(2026, 12, 31),
        );

        final advance = markBillPaid(bill: bill);

        expect(advance.newDueDate, DateTime(2026, 8, 25));
        expect(advance.newStatus, BillStatus.active);
      },
    );
  });
}
