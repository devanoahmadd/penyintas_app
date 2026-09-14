import 'package:equatable/equatable.dart';

/// Dua boolean yang fitur ini butuhkan dari luar dirinya (S2).
///
/// Sengaja sesempit ini: domain tidak boleh bergantung pada `DashboardEntity`
/// milik fitur lain, dan test tidak boleh perlu memalsukan seluruh dashboard
/// demi satu nilai.
class ChallengeEnvironment extends Equatable {
  const ChallengeEnvironment({
    required this.budgetConfigured,
    required this.survivalActive,
  });

  /// `safeMonthlyBudget > 0`. Kalau false, seluruh mesin dashboard melaporkan
  /// `danger` — dan tanpa gerbang ini user tanpa anggaran akan ter-`held`
  /// permanen tiap Senin, selamanya, tanpa penjelasan (D16).
  final bool budgetConfigured;

  /// `dashboard.status == BudgetStatus.danger`.
  final bool survivalActive;

  @override
  List<Object> get props => [budgetConfigured, survivalActive];
}
