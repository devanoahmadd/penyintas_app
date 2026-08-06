import 'package:equatable/equatable.dart';
import 'package:penyintas_app/features/bills/domain/entities/bill_entity.dart';
import 'package:penyintas_app/features/bills/domain/usecases/calculate_tied_money.dart';
import 'package:penyintas_app/features/bills/domain/usecases/represented_by_fixed_expenses.dart';

/// Hasil P1 "Pivot Flag" (spec §3): tiga angka + flag nudge §6.2.
///
/// INVARIANT: `bebas()` adalah PARTISI dari activeBills pada horizon yang sama
/// → `tiedFixed = tiedTotal − tiedFlexible ≥ 0`. Aturan bukan-partisi
/// (mis. plafon agregat — spec §10.1 DITOLAK) merusak turunan ini diam-diam.
class BillCommitments extends Equatable {
  const BillCommitments({
    required this.tiedTotal,
    required this.tiedFlexible,
    required this.safeRemaining,
    this.nudgeBudgetMismatch = false,
  });

  static const empty = BillCommitments(
    tiedTotal: 0,
    tiedFlexible: 0,
    safeRemaining: 0,
  );

  /// Σ SEMUA tagihan aktif due < gajian — baris kesadaran.
  final int tiedTotal;

  /// Σ subset "bebas" (M1) — satu-satunya yang dikurangkan dari saldo.
  final int tiedFlexible;

  /// totalRemaining (PRA-clamp) − tiedFlexible. BOLEH NEGATIF — jangan clamp.
  final int safeRemaining;

  /// §6.2: Σ bill BULANAN ber-isFixedNeed > fixedExpenses (> 0).
  final bool nudgeBudgetMismatch;

  int get tiedFixed => tiedTotal - tiedFlexible;

  @override
  List<Object> get props => [
    tiedTotal,
    tiedFlexible,
    safeRemaining,
    nudgeBudgetMismatch,
  ];
}

/// MURNI. Membungkus [calculateTiedMoney] TANPA mengubahnya (kontrak §6.4
/// dokumen masalah). Kontrak caller sama: hanya bill berstatus `active`.
BillCommitments calculateBillCommitments({
  required List<BillEntity> activeBills,
  required DateTime today,
  required int paymentDate,
  required int totalRemaining,
  required int fixedExpenses,
}) {
  // Aturan "diwakili fixedExpenses" beserta seluruh alasan historisnya kini
  // tinggal di `represented_by_fixed_expenses.dart`. Baca doc-comment di sana
  // sebelum menyentuh baris mana pun di bawah ini.
  //
  // Pivot M1 (spec §3): tanpa potongan di muka, semua bill "bebas".
  bool bebas(BillEntity b) => !coveredUpfront(b, fixedExpenses);

  final semua = calculateTiedMoney(
    activeBills: activeBills,
    today: today,
    paymentDate: paymentDate,
    balance: totalRemaining,
  );
  final bebasSaja = calculateTiedMoney(
    activeBills: activeBills.where(bebas).toList(),
    today: today,
    paymentDate: paymentDate,
    balance: totalRemaining,
  );

  // §6.2: toleransi 0 (strictly greater).
  final fixedMonthly = activeBills
      .where(representedByFixedExpenses)
      .fold(0, (sum, b) => sum + b.estimatedAmount);

  return BillCommitments(
    tiedTotal: semua.tied,
    tiedFlexible: bebasSaja.tied,
    safeRemaining: bebasSaja.safe,
    nudgeBudgetMismatch: fixedExpenses > 0 && fixedMonthly > fixedExpenses,
  );
}
