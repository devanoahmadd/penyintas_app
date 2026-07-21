import 'package:equatable/equatable.dart';
import 'package:penyintas_app/features/budget/domain/entities/budget_cycle.dart';

class BudgetLimitEntity extends Equatable {
  const BudgetLimitEntity({
    required this.id,
    required this.category,
    required this.limitAmount,
    required this.cycleType,
    required this.isEnabled,
    required this.updatedAt,
  });

  final int id;
  final String category;
  final int limitAmount;
  final BudgetCycle cycleType;
  final bool isEnabled;
  final DateTime updatedAt;

  // isMonthly dihapus — dead code (#F2-5). Gunakan cycleType == BudgetCycle.monthly langsung.

  BudgetLimitEntity copyWith({
    int? id,
    String? category,
    int? limitAmount,
    BudgetCycle? cycleType,
    bool? isEnabled,
    DateTime? updatedAt,
  }) => BudgetLimitEntity(
    id: id ?? this.id,
    category: category ?? this.category,
    limitAmount: limitAmount ?? this.limitAmount,
    cycleType: cycleType ?? this.cycleType,
    isEnabled: isEnabled ?? this.isEnabled,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  @override
  List<Object> get props => [
    id,
    category,
    limitAmount,
    cycleType,
    isEnabled,
    updatedAt,
  ];
}
