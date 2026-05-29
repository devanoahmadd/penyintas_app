import 'package:equatable/equatable.dart';
import 'package:penyintas_app/features/transaction/domain/entities/transaction_entity.dart';

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
  final TransactionCategory category;
  final int limitAmount;
  final String cycleType; // 'monthly' | 'cycle'
  final bool isEnabled;
  final DateTime updatedAt;

  bool get isMonthly => cycleType == 'monthly';

  BudgetLimitEntity copyWith({
    int? id,
    TransactionCategory? category,
    int? limitAmount,
    String? cycleType,
    bool? isEnabled,
    DateTime? updatedAt,
  }) =>
      BudgetLimitEntity(
        id: id ?? this.id,
        category: category ?? this.category,
        limitAmount: limitAmount ?? this.limitAmount,
        cycleType: cycleType ?? this.cycleType,
        isEnabled: isEnabled ?? this.isEnabled,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  @override
  List<Object> get props => [id, category, limitAmount, cycleType, isEnabled, updatedAt];
}
