import 'package:flutter_test/flutter_test.dart';
import 'package:penyintas_app/features/bills/domain/entities/bill_entity.dart';
import 'package:penyintas_app/features/bills/domain/usecases/roll_forward_due_date.dart';

void main() {
  group('rollForwardDueDate — monthly', () {
    test('anchor 31: 31 Jan 2027 -> 28 Feb 2027 (non-kabisat, di-clamp)', () {
      expect(
        rollForwardDueDate(
          current: DateTime(2027, 1, 31),
          dueDayOfMonth: 31,
          recurrence: Recurrence.monthly,
        ),
        DateTime(2027, 2, 28),
      );
    });

    test('anchor 31: 28 Feb 2027 -> 31 Mar 2027 (anchor kembali ke 31)', () {
      // KUNCI anti-sabotase: anchor pakai dueDayOfMonth (31), BUKAN current.day (28).
      expect(
        rollForwardDueDate(
          current: DateTime(2027, 2, 28),
          dueDayOfMonth: 31,
          recurrence: Recurrence.monthly,
        ),
        DateTime(2027, 3, 31),
      );
    });

    test('anchor 31: 31 Jan 2028 -> 29 Feb 2028 (tahun kabisat)', () {
      expect(
        rollForwardDueDate(
          current: DateTime(2028, 1, 31),
          dueDayOfMonth: 31,
          recurrence: Recurrence.monthly,
        ),
        DateTime(2028, 2, 29),
      );
    });

    test('anchor 15: 15 Jan 2027 -> 15 Feb 2027 (normal, tanpa clamp)', () {
      expect(
        rollForwardDueDate(
          current: DateTime(2027, 1, 15),
          dueDayOfMonth: 15,
          recurrence: Recurrence.monthly,
        ),
        DateTime(2027, 2, 15),
      );
    });

    test('anchor 15: Des -> Jan tahun berikutnya (rollover tahun)', () {
      expect(
        rollForwardDueDate(
          current: DateTime(2027, 12, 15),
          dueDayOfMonth: 15,
          recurrence: Recurrence.monthly,
        ),
        DateTime(2028, 1, 15),
      );
    });
  });

  group('rollForwardDueDate — yearly', () {
    test('29 Feb 2028 -> 28 Feb 2029 (clamp ke non-kabisat)', () {
      expect(
        rollForwardDueDate(
          current: DateTime(2028, 2, 29),
          dueDayOfMonth: 29,
          recurrence: Recurrence.yearly,
        ),
        DateTime(2029, 2, 28),
      );
    });

    test('10 Jun 2026 -> 10 Jun 2027 (bulan & hari tetap)', () {
      expect(
        rollForwardDueDate(
          current: DateTime(2026, 6, 10),
          dueDayOfMonth: 10,
          recurrence: Recurrence.yearly,
        ),
        DateTime(2027, 6, 10),
      );
    });
  });

  group('rollForwardDueDate — none (defensif)', () {
    test('Recurrence.none mengembalikan current apa adanya', () {
      final current = DateTime(2027, 3, 10);
      expect(
        rollForwardDueDate(
          current: current,
          dueDayOfMonth: 10,
          recurrence: Recurrence.none,
        ),
        current,
      );
    });
  });
}
