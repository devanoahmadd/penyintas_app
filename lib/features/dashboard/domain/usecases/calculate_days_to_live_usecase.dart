import 'package:equatable/equatable.dart';

class CalcDtlParams extends Equatable {
  const CalcDtlParams({
    required this.totalRemaining,
    required this.avgDailySpend,
    required this.remainingDays,
  });

  final int totalRemaining;
  final double avgDailySpend;
  final int remainingDays;

  @override
  List<Object> get props => [totalRemaining, avgDailySpend, remainingDays];
}

class CalculateDaysToLiveUseCase {
  const CalculateDaysToLiveUseCase();

  int call(CalcDtlParams params) {
    if (params.avgDailySpend <= 0) return params.remainingDays;
    final dtl = (params.totalRemaining / params.avgDailySpend).floor();
    return dtl < 0 ? 0 : dtl;
  }
}
