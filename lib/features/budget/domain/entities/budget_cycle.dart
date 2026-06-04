/// Tipe siklus penghitungan limit anggaran per kategori.
///
/// Nilai enum di-persist ke SQLite dan Firestore sebagai string `.name`
/// ('cycle' / 'monthly') agar backward-compatible dengan data lama.
enum BudgetCycle {
  /// Per siklus gajian — jendela dari tanggal gajian ke gajian berikutnya.
  cycle,

  /// Per bulan kalender — jendela 1–akhir bulan.
  monthly,
}

extension BudgetCycleExt on BudgetCycle {
  /// Label ringkas untuk footer kartu limit ("per siklus" / "per bulan").
  String get label => switch (this) {
        BudgetCycle.cycle => 'per siklus',
        BudgetCycle.monthly => 'per bulan',
      };

  /// Label picker (huruf besar): "Per Siklus" / "Per Bulan".
  String get pickerLabel => switch (this) {
        BudgetCycle.cycle => 'Per Siklus',
        BudgetCycle.monthly => 'Per Bulan',
      };

  /// Sublabel picker.
  String get pickerSublabel => switch (this) {
        BudgetCycle.cycle => 'Reset tiap gajian',
        BudgetCycle.monthly => 'Reset tiap 1 bulan',
      };
}
