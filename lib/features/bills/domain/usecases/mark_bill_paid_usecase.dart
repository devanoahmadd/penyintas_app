import 'package:penyintas_app/features/bills/domain/entities/bill_entity.dart';
import 'package:penyintas_app/features/bills/domain/usecases/roll_forward_due_date.dart';

/// Hasil perhitungan state bill setelah SATU pembayaran (spec §5 langkah 3-5).
///
/// Objek nilai murni — dikonsumsi `BillsBloc._onMarkedPaid` untuk memanggil
/// `applyBillPayment`. Tidak menyimpan efek samping apa pun.
class BillPaymentAdvance {
  const BillPaymentAdvance({
    required this.newInstallmentsPaid,
    required this.newDueDate,
    required this.newStatus,
  });

  final int newInstallmentsPaid;
  final DateTime newDueDate;
  final BillStatus newStatus;
}

/// MURNI (tanpa efek samping, deterministik — pola `rollForwardDueDate`/
/// `nextPayday`): advance progres cicilan + roll-forward `dueDate` +
/// stop-check (spec §5 langkah 3-5).
///
/// Stop-check (bill menjadi [BillStatus.completed]) bila SALAH SATU:
/// - **tenor habis**: `installmentTotal != null` DAN
///   `newInstallmentsPaid == installmentTotal` (EXACT `==` — pembayaran
///   ke-N tepat menutup tenor N);
/// - **lewat batas perulangan**: `recurrenceEndDate != null` DAN
///   `newDueDate` melewati `recurrenceEndDate`;
/// - **sekali saja**: `recurrence == Recurrence.none`.
///
/// Untuk [Recurrence.none], `dueDate` tidak berubah (tak ada perulangan).
BillPaymentAdvance markBillPaid({required BillEntity bill}) {
  final newInstallmentsPaid = bill.installmentsPaid + 1;

  final newDueDate = bill.recurrence == Recurrence.none
      ? bill.dueDate
      : rollForwardDueDate(
          current: bill.dueDate,
          dueDayOfMonth: bill.dueDayOfMonth ?? bill.dueDate.day,
          recurrence: bill.recurrence,
        );

  final tenorHabis =
      bill.installmentTotal != null &&
      newInstallmentsPaid == bill.installmentTotal!;
  final lewatBatas =
      bill.recurrenceEndDate != null &&
      newDueDate.isAfter(bill.recurrenceEndDate!);
  final sekali = bill.recurrence == Recurrence.none;

  final newStatus = (tenorHabis || lewatBatas || sekali)
      ? BillStatus.completed
      : BillStatus.active;

  return BillPaymentAdvance(
    newInstallmentsPaid: newInstallmentsPaid,
    newDueDate: newDueDate,
    newStatus: newStatus,
  );
}
