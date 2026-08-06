import 'package:flutter_test/flutter_test.dart';
import 'package:penyintas_app/features/bills/domain/entities/bill_entity.dart';
import 'package:penyintas_app/features/bills/domain/usecases/represented_by_fixed_expenses.dart';

BillEntity makeBill({
  required bool isFixedNeed,
  required Recurrence recurrence,
}) => BillEntity(
  id: 1,
  name: 'Tagihan uji',
  estimatedAmount: 750000,
  category: 'lainnya',
  isFixedNeed: isFixedNeed,
  dueDate: DateTime(2026, 8, 20),
  recurrence: recurrence,
  installmentsPaid: 0,
  reminderEnabled: true,
  status: BillStatus.active,
  createdAt: DateTime(2026, 1, 1),
  updatedAt: DateTime(2026, 1, 1),
);

void main() {
  // Oracle ditulis LITERAL, bukan memanggil fungsi produksi. Kalau oracle
  // memakai fungsi yang sedang diuji, test ini membandingkan fungsi dengan
  // dirinya sendiri dan tetap hijau walau aturannya salah.
  //
  // `Recurrence.values` = [none, monthly, yearly] — tiga-tiganya disapu.

  group('representedByFixedExpenses — bentuk tagihan saja', () {
    for (final isFixedNeed in [true, false]) {
      for (final recurrence in Recurrence.values) {
        final expected = isFixedNeed && recurrence == Recurrence.monthly;
        test(
          'isFixedNeed=$isFixedNeed, recurrence=${recurrence.name} → $expected',
          () {
            final bill = makeBill(
              isFixedNeed: isFixedNeed,
              recurrence: recurrence,
            );
            expect(representedByFixedExpenses(bill), expected);
          },
        );
      }
    }
  });

  group('coveredUpfront — bentuk tagihan DAN isi anggaran', () {
    for (final isFixedNeed in [true, false]) {
      for (final recurrence in Recurrence.values) {
        for (final fixedExpenses in [0, 500000]) {
          final expected =
              isFixedNeed &&
              recurrence == Recurrence.monthly &&
              fixedExpenses > 0;
          test('isFixedNeed=$isFixedNeed, recurrence=${recurrence.name}, '
              'fixedExpenses=$fixedExpenses → $expected', () {
            final bill = makeBill(
              isFixedNeed: isFixedNeed,
              recurrence: recurrence,
            );
            expect(coveredUpfront(bill, fixedExpenses), expected);
          });
        }
      }
    }
  });
}
