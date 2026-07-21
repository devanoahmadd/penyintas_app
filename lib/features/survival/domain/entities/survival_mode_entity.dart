import 'package:equatable/equatable.dart';
import 'package:penyintas_app/features/survival/domain/entities/survival_tip_entity.dart';

// Sentinel — dipakai copyWith() agar activatedAt bisa di-null-kan
const _kSentinel = Object();

class SurvivalModeEntity extends Equatable {
  const SurvivalModeEntity({
    required this.isActive,
    required this.remainingAmount,
    required this.remainingDays,
    required this.suggestedDailyBudget,
    required this.tips,
    this.activatedAt,
  });

  final bool isActive;
  final int remainingAmount;
  final int remainingDays;
  final int suggestedDailyBudget;
  final List<SurvivalTip> tips;
  final DateTime? activatedAt;

  SurvivalModeEntity copyWith({
    bool? isActive,
    int? remainingAmount,
    int? remainingDays,
    int? suggestedDailyBudget,
    List<SurvivalTip>? tips,
    Object? activatedAt = _kSentinel,
  }) => SurvivalModeEntity(
    isActive: isActive ?? this.isActive,
    remainingAmount: remainingAmount ?? this.remainingAmount,
    remainingDays: remainingDays ?? this.remainingDays,
    suggestedDailyBudget: suggestedDailyBudget ?? this.suggestedDailyBudget,
    tips: tips ?? this.tips,
    activatedAt: identical(activatedAt, _kSentinel)
        ? this.activatedAt
        : activatedAt as DateTime?,
  );

  @override
  List<Object?> get props => [
    isActive,
    remainingAmount,
    remainingDays,
    suggestedDailyBudget,
    tips,
    activatedAt,
  ];
}
