import 'package:flutter_test/flutter_test.dart';
import 'package:penyintas_app/core/utils/date_helper.dart';
import 'package:penyintas_app/features/bills/domain/entities/bill_entity.dart';
import 'package:penyintas_app/features/bills/domain/usecases/calculate_bill_commitments.dart';
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
  //
  // NAMA test ini sengaja menyebut MAGNITUDO, bukan durasi. Nama lama
  // ("glitch 1 hari") tercetak tiap kali suite jalan dan mengkalibrasi
  // pembaca ke arah yang salah: durasinya memang satu hari, tapi selisih
  // jendelanya SATU BULAN TAGIHAN penuh.
  test('hari-gajian-ter-clamp DIVERGEN — durasi 1 hari, magnitudo 1 BULAN '
      'tagihan (diterima sadar, spec §3)', () {
    final day = DateTime(2026, 4, 30); // pd=31, April cuma 30 hari

    // Horizon tagihan maju sebulan penuh: kandidat 30 Apr == today,
    // dianggap sudah cair, jadi lompat ke 31 Mei (EKSKLUSIF — bill yang
    // jatuh tempo <= 30 Mei ikut terhitung).
    expect(nextPayday(today: day, paymentDate: 31), DateTime(2026, 5, 31));

    // Window anggaran justru BERAKHIR hari ini.
    final end = cycleEnd(31, now: day);
    expect(
      DateTime(end.year, end.month, end.day).add(const Duration(days: 1)),
      DateTime(2026, 5, 1),
    );

    // Selisih dua jendela = 30 hari, bukan 1.
    expect(
      nextPayday(
        today: day,
        paymentDate: 31,
      ).difference(DateTime(2026, 5, 1)).inDays,
      30,
      reason:
          'inilah magnitudo yang nama lama sembunyikan: bukan glitch 1 '
          'hari, melainkan seluruh tagihan bulan Mei ikut dikurangkan dari '
          'sisa anggaran siklus yang berakhir HARI INI',
    );
  });

  // §8.7c — akibat yang terlihat pengguna, dihitung apa adanya.
  test('akibat divergensi di kartu saldo: safeRemaining negatif tepat di hari '
      'gajian karena tagihan bulan DEPAN dikurangkan dari sisa siklus INI', () {
    final day = DateTime(2026, 4, 30);

    // Tagihan bulan Mei — semuanya jatuh sebelum horizon 31 Mei.
    final r = calculateBillCommitments(
      activeBills: [
        BillEntity(
          id: 1,
          name: 'Kos Mei',
          estimatedAmount: 800000,
          category: 'fixed',
          isFixedNeed: false, // bebas → benar-benar dikurangkan
          dueDate: DateTime(2026, 5, 5),
          recurrence: Recurrence.monthly,
          installmentsPaid: 0,
          reminderEnabled: false,
          status: BillStatus.active,
          createdAt: DateTime(2026, 1, 1),
          updatedAt: DateTime(2026, 1, 1),
        ),
      ],
      today: day,
      paymentDate: 31,
      totalRemaining: 200000, // sisa tipis di ujung siklus — wajar
      fixedExpenses: 0,
    );

    expect(r.tiedTotal, 800000);
    expect(r.tiedFlexible, 800000);
    expect(
      r.safeRemaining,
      -600000,
      reason:
          'varian C (peringatan merah) muncul tepat di hari gajian. '
          'Terkena paymentDate 29/30/31; untuk pd=31 sekitar 5 hari/tahun '
          '(Feb/Apr/Jun/Sep/Nov). Penyatuan horizon = roadmap §5',
    );
  });
}
