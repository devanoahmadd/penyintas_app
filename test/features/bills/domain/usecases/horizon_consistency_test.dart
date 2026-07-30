import 'package:flutter_test/flutter_test.dart';
import 'package:penyintas_app/core/utils/date_helper.dart';
import 'package:penyintas_app/features/bills/domain/usecases/clamp_day_of_month.dart';
import 'package:penyintas_app/features/bills/domain/usecases/next_payday.dart';

void main() {
  // §8.7a — properti hari NON-guard: nextPayday == cycleEnd + 1 hari (midnight).
  test('ekuivalensi dua implementasi horizon di hari non-guard', () {
    final sampleDays = <DateTime>[
      for (var m = 1; m <= 12; m++) ...[
        DateTime(2026, m, 10),
        DateTime(2026, m, 25),
      ],
      DateTime(2026, 2, 28),
      DateTime(2028, 2, 29),
      DateTime(2026, 4, 30),
    ];
    for (var pd = 1; pd <= 31; pd++) {
      for (final day in sampleDays) {
        final candidate = clampDayOfMonth(day.year, day.month, pd);
        final isGuardDay = candidate.day < pd && candidate == day;
        if (isGuardDay) continue; // divergen SENGAJA — lihat test §8.7b

        final end = cycleEnd(pd, now: day);
        final endMidnightPlus1 = DateTime(
          end.year,
          end.month,
          end.day,
        ).add(const Duration(days: 1));
        expect(
          nextPayday(today: day, paymentDate: pd),
          endMidnightPlus1,
          reason: 'pd=$pd day=$day',
        );
      }
    }
  });

  // §8.7b — dokumentasi divergensi hari guard (keputusan spec §3: DITERIMA).
  // Bila test ini pecah: seseorang mengubah salah satu implementasi horizon —
  // tinjau ulang keputusan §3 sebelum "memperbaiki" test.
  test('hari-gajian-ter-clamp DIVERGEN — glitch 1 hari diterima sadar', () {
    final day = DateTime(2026, 4, 30); // pd=31, April cuma 30 hari
    expect(nextPayday(today: day, paymentDate: 31), DateTime(2026, 5, 31));
    final end = cycleEnd(31, now: day);
    expect(
      DateTime(end.year, end.month, end.day).add(const Duration(days: 1)),
      DateTime(2026, 5, 1),
    ); // ≠ nextPayday — dua jendela beda di hari ini
  });
}
