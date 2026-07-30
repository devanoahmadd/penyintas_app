// Kunci equality DashboardEntity untuk P1 "Uang Terikat" (spec §8.6).
//
// `billCommitments` WAJIB masuk `props` — kalau tidak, dua entity yang hanya
// berbeda uang-terikat dianggap sama dan BlocBuilder/distinct() menelan emisi
// baru: angka "sisa aman" di UI membeku setelah tagihan berubah.
import 'package:flutter_test/flutter_test.dart';
import 'package:penyintas_app/features/bills/domain/usecases/calculate_bill_commitments.dart';
import 'package:penyintas_app/features/dashboard/domain/entities/dashboard_entity.dart';

void main() {
  // Helper: entity minimal dengan semua field wajib terisi konstanta.
  DashboardEntity makeEntity({
    BillCommitments commitments = BillCommitments.empty,
  }) => DashboardEntity(
    dailyBudget: 1,
    spentToday: 0,
    remainingToday: 1,
    totalMonthlyBudget: 1,
    totalSpentThisMonth: 0,
    totalRemaining: 1,
    daysToLive: 1,
    remainingDays: 1,
    avgDailySpend: 0,
    status: BudgetStatus.safe,
    lastUpdated: DateTime(2026),
    todayTransactions: const [],
    emergencyFundMonthly: 0,
    billCommitments: commitments,
  );

  test('billCommitments beda → entity TIDAK sama (masuk props — §8.6)', () {
    expect(
      makeEntity(),
      isNot(
        equals(
          makeEntity(
            commitments: const BillCommitments(
              tiedTotal: 1,
              tiedFlexible: 1,
              safeRemaining: 0,
            ),
          ),
        ),
      ),
    );
  });

  test(
    'billCommitments sama → entity sama (lastUpdated tetap di luar props)',
    () {
      expect(makeEntity(), equals(makeEntity()));
    },
  );
}
