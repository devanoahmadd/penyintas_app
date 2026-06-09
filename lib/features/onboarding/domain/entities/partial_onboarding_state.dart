class PartialOnboardingState {
  const PartialOnboardingState({
    required this.step,
    required this.income,
    required this.expenses,
    required this.pct,
    required this.payday,
    required this.savedAt,
  });

  final int step;                    // 0 / 1 / 2
  final int income;
  final Map<String, int> expenses;   // kos, listrik, internet, pulsa, lain
  final int pct;                     // 0–50, integer percent
  final int payday;
  final DateTime savedAt;
}
