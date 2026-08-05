import 'package:flutter_test/flutter_test.dart';
import 'package:penyintas_app/features/bills/domain/entities/bill_entity.dart';
import 'package:penyintas_app/features/bills/domain/usecases/calculate_bill_commitments.dart';

/// Helper fixture — gaya `billBerjalan` di `mark_bill_paid_sheet_test.dart`.
/// `dueDate` parametris (wajib diisi eksplisit per test) supaya posisi bill
/// terhadap horizon selalu jelas dari pemanggilan test, bukan tersembunyi
/// di default.
BillEntity makeBill({
  int id = 1,
  required int estimatedAmount,
  required bool isFixedNeed,
  required DateTime dueDate,
  Recurrence recurrence = Recurrence.monthly,
}) => BillEntity(
  id: id,
  name: 'Tagihan $id',
  estimatedAmount: estimatedAmount,
  category: 'lainnya',
  isFixedNeed: isFixedNeed,
  dueDate: dueDate,
  recurrence: recurrence,
  installmentsPaid: 0,
  reminderEnabled: true,
  status: BillStatus.active,
  createdAt: DateTime(2026, 1, 1),
  updatedAt: DateTime(2026, 1, 1),
);

void main() {
  // Fixture dasar: today = 2026-08-01, paymentDate = 25 → horizon = 2026-08-25.
  final today = DateTime(2026, 8, 1);

  test('#1: bill isFixedNeed=true TIDAK dikurangkan (tiedTotal terisi)', () {
    final r = calculateBillCommitments(
      activeBills: [
        makeBill(
          estimatedAmount: 500000,
          isFixedNeed: true,
          dueDate: DateTime(2026, 8, 5),
        ),
      ],
      today: today,
      paymentDate: 25,
      totalRemaining: 2200000,
      fixedExpenses: 500000,
    );
    expect(r.tiedTotal, 500000);
    expect(r.tiedFlexible, 0);
    expect(r.safeRemaining, 2200000); // TIDAK double-count
    expect(r.tiedFixed, 500000);
  });

  test('#7: bill isFixedNeed=false DIKURANGKAN', () {
    final r = calculateBillCommitments(
      activeBills: [
        makeBill(
          estimatedAmount: 200000,
          isFixedNeed: false,
          dueDate: DateTime(2026, 8, 10),
        ),
      ],
      today: today,
      paymentDate: 25,
      totalRemaining: 2200000,
      fixedExpenses: 500000,
    );
    expect(r.tiedFlexible, 200000);
    expect(r.safeRemaining, 2000000);
  });

  test('#2 M1: fixedExpenses==0 → SEMUA bill dianggap bebas', () {
    final r = calculateBillCommitments(
      activeBills: [
        makeBill(
          estimatedAmount: 500000,
          isFixedNeed: true,
          dueDate: DateTime(2026, 8, 5),
        ),
      ],
      today: today,
      paymentDate: 25,
      totalRemaining: 2700000,
      fixedExpenses: 0,
    );
    expect(r.tiedFlexible, 500000);
    expect(r.safeRemaining, 2200000);
  });

  test('#6 kontinuitas: bayar bill bebas → safeRemaining TETAP', () {
    // Sebelum bayar: bill 200rb aktif, totalRemaining 2.2jt.
    final sebelum = calculateBillCommitments(
      activeBills: [
        makeBill(
          estimatedAmount: 200000,
          isFixedNeed: false,
          dueDate: DateTime(2026, 8, 10),
        ),
      ],
      today: today,
      paymentDate: 25,
      totalRemaining: 2200000,
      fixedExpenses: 500000,
    );
    // Sesudah bayar: bill keluar horizon, spent naik 200rb (§4.1 memastikan ini).
    final sesudah = calculateBillCommitments(
      activeBills: const [],
      today: today,
      paymentDate: 25,
      totalRemaining: 2000000,
      fixedExpenses: 500000,
    );
    expect(sebelum.safeRemaining, sesudah.safeRemaining); // tanpa lonjakan
  });

  test('#9: bill tahunan di dalam horizon ikut terhitung', () {
    final r = calculateBillCommitments(
      activeBills: [
        makeBill(
          estimatedAmount: 1200000,
          isFixedNeed: false,
          recurrence: Recurrence.yearly,
          dueDate: DateTime(2026, 8, 20),
        ),
      ],
      today: today,
      paymentDate: 25,
      totalRemaining: 2200000,
      fixedExpenses: 500000,
    );
    expect(r.tiedFlexible, 1200000);
  });

  test('#15: tanpa bill → empty', () {
    final r = calculateBillCommitments(
      activeBills: const [],
      today: today,
      paymentDate: 25,
      totalRemaining: 2200000,
      fixedExpenses: 500000,
    );
    expect(r.tiedTotal, 0);
    expect(r.safeRemaining, 2200000);
  });

  test('negatif TIDAK di-clamp', () {
    final r = calculateBillCommitments(
      activeBills: [
        makeBill(
          estimatedAmount: 900000,
          isFixedNeed: false,
          dueDate: DateTime(2026, 8, 3),
        ),
      ],
      today: today,
      paymentDate: 25,
      totalRemaining: 500000,
      fixedExpenses: 500000,
    );
    expect(r.safeRemaining, -400000);
  });

  group('nudge §6.2 (Σ HANYA recurrence bulanan; toleransi 0)', () {
    test('Σ bulanan isFixedNeed > fixedExpenses → nudge', () {
      final r = calculateBillCommitments(
        activeBills: [
          makeBill(
            estimatedAmount: 500000,
            isFixedNeed: true,
            recurrence: Recurrence.monthly,
            dueDate: DateTime(2026, 8, 5),
          ),
          makeBill(
            id: 2,
            estimatedAmount: 200000,
            isFixedNeed: true,
            recurrence: Recurrence.monthly,
            dueDate: DateTime(2026, 8, 28),
          ),
        ],
        today: today,
        paymentDate: 25,
        totalRemaining: 2200000,
        fixedExpenses: 500000,
      );
      expect(
        r.nudgeBudgetMismatch,
        isTrue,
      ); // 700rb > 500rb; due 28/8 di luar horizon pun ikut Σ
    });

    test('sama persis → TIDAK nudge (toleransi 0 = strictly greater)', () {
      final r = calculateBillCommitments(
        activeBills: [
          makeBill(
            estimatedAmount: 500000,
            isFixedNeed: true,
            recurrence: Recurrence.monthly,
            dueDate: DateTime(2026, 8, 5),
          ),
        ],
        today: today,
        paymentDate: 25,
        totalRemaining: 2200000,
        fixedExpenses: 500000,
      );
      expect(r.nudgeBudgetMismatch, isFalse);
    });

    test('bill TAHUNAN dikecualikan dari Σ (salah satuan)', () {
      final r = calculateBillCommitments(
        activeBills: [
          makeBill(
            estimatedAmount: 1200000,
            isFixedNeed: true,
            recurrence: Recurrence.yearly,
            dueDate: DateTime(2026, 12, 1),
          ),
        ],
        today: today,
        paymentDate: 25,
        totalRemaining: 2200000,
        fixedExpenses: 500000,
      );
      expect(r.nudgeBudgetMismatch, isFalse);
    });

    test('fixedExpenses==0 → TIDAK nudge (itu wilayah M1)', () {
      final r = calculateBillCommitments(
        activeBills: [
          makeBill(
            estimatedAmount: 500000,
            isFixedNeed: true,
            recurrence: Recurrence.monthly,
            dueDate: DateTime(2026, 8, 5),
          ),
        ],
        today: today,
        paymentDate: 25,
        totalRemaining: 2700000,
        fixedExpenses: 0,
      );
      expect(r.nudgeBudgetMismatch, isFalse);
    });
  });

  test('value equality: dua hasil identik == (cegah rebuild storm)', () {
    // Dibangun via konstruktor runtime (BUKAN const) — dua ekspresi const
    // dengan argumen sama akan dikanonikalisasi jadi objek yang SAMA secara
    // referensi oleh compiler, sehingga EquatableMixin.== short-circuit lewat
    // `identical(this, other)` tanpa pernah membandingkan `props`. Itu bikin
    // test lolos walau `props` dikosongkan — tidak mengunci apa pun.
    BillCommitments build() =>
        BillCommitments(tiedTotal: 1, tiedFlexible: 1, safeRemaining: 1);
    final a = build();
    final b = build();
    expect(identical(a, b), isFalse); // pastikan bukan objek yang sama
    expect(a, equals(b)); // kesetaraan HARUS lewat props, bukan referensi
  });

  // Test equality di atas HANYA bisa lolos vacuous (props dikosongkan/salah
  // satu field dihapus dari daftar) selama dua instance yang dibandingkan
  // punya nilai field yang sama persis — props yang rusak tetap menghasilkan
  // "sama" karena kedua sisi kehilangan field yang sama. Grup ini menutup
  // celah itu untuk SETIAP field di `props`, bukan hanya `tiedTotal`.
  group('value INEQUALITY per-field (mengunci props lengkap)', () {
    BillCommitments base() => BillCommitments(
      tiedTotal: 1,
      tiedFlexible: 1,
      safeRemaining: 1,
      nudgeBudgetMismatch: false,
    );

    test('tiedTotal beda → TIDAK sama', () {
      final b = BillCommitments(
        tiedTotal: 2, // satu-satunya field yang beda
        tiedFlexible: 1,
        safeRemaining: 1,
        nudgeBudgetMismatch: false,
      );
      expect(base(), isNot(equals(b)));
    });

    test('tiedFlexible beda → TIDAK sama', () {
      final b = BillCommitments(
        tiedTotal: 1,
        tiedFlexible: 2, // satu-satunya field yang beda
        safeRemaining: 1,
        nudgeBudgetMismatch: false,
      );
      expect(base(), isNot(equals(b)));
    });

    test('safeRemaining beda → TIDAK sama '
        '(kalau lepas dari props: angka "Aman dipakai" MEMBEKU di layar '
        'karena BLoC men-dedup emisi — tidak crash, tidak ada log)', () {
      final b = BillCommitments(
        tiedTotal: 1,
        tiedFlexible: 1,
        safeRemaining: 2, // satu-satunya field yang beda
        nudgeBudgetMismatch: false,
      );
      expect(base(), isNot(equals(b)));
    });

    test('nudgeBudgetMismatch beda → TIDAK sama', () {
      final b = BillCommitments(
        tiedTotal: 1,
        tiedFlexible: 1,
        safeRemaining: 1,
        nudgeBudgetMismatch: true, // satu-satunya field yang beda
      );
      expect(base(), isNot(equals(b)));
    });
  });
}
