part of 'budget_limits_bloc.dart';

abstract class BudgetLimitsEvent extends Equatable {
  const BudgetLimitsEvent();
  @override
  List<Object?> get props => [];
}

class LoadBudgetLimits extends BudgetLimitsEvent {
  const LoadBudgetLimits({this.force = false});

  /// `false` (default) = load-untuk-mount: jika state sudah Loaded, di-skip
  /// (dedup mount ganda dashboard↔budget pada singleton).
  /// `true` = refresh eksplisit: selalu recompute overview, tanpa skeleton
  /// flash. Dipakai saat balik dari edit-settings / kelola kategori.
  final bool force;

  @override
  List<Object> get props => [force];
}

/// Event internal: dipicu oleh stream perubahan transaksi. Membuat overview
/// reaktif terhadap tambah/edit/hapus catatan dari entry-point mana pun.
class _TransactionsChanged extends BudgetLimitsEvent {
  const _TransactionsChanged();
}

class SaveBudgetLimit extends BudgetLimitsEvent {
  const SaveBudgetLimit(this.limit);
  final BudgetLimitEntity limit;
  @override
  List<Object> get props => [limit];
}

class DeleteBudgetLimit extends BudgetLimitsEvent {
  const DeleteBudgetLimit({required this.id, required this.categoryName});
  final int id;
  final String categoryName;
  @override
  List<Object> get props => [id, categoryName];
}

class ToggleBudgetLimit extends BudgetLimitsEvent {
  const ToggleBudgetLimit({required this.id, required this.isEnabled});
  final int id;
  final bool isEnabled;
  @override
  List<Object> get props => [id, isEnabled];
}
