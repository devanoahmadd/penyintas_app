import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:penyintas_app/core/error/failures.dart';
import 'package:penyintas_app/core/usecases/usecase.dart';
import 'package:penyintas_app/features/onboarding/domain/entities/daily_budget_result.dart';

class CalculateDailyBudgetUseCase extends UseCase<DailyBudgetResult, CalcParams> {
  CalculateDailyBudgetUseCase();

  @override
  Future<Either<Failure, DailyBudgetResult>> call(CalcParams params) async {
    if (params.income <= 0) {
      return const Left(
        ValidationFailure('Income harus lebih dari 0.'),
      );
    }
    final available = params.income - params.fixedExpenses;
    final emergency = available > 0 ? (available * params.emergencyPct).round() : 0;
    final spendable = available - emergency;
    final daily = params.remainingDays > 0
        ? (spendable / params.remainingDays).floor()
        : 0;

    return Right(DailyBudgetResult(
      dailyBudget: daily < 0 ? 0 : daily,
      totalAvailable: available < 0 ? 0 : available,
      emergencyFund: emergency,
      remainingDays: params.remainingDays,
    ));
  }
}

class CalcParams extends Equatable {
  const CalcParams({
    required this.income,
    required this.fixedExpenses,
    required this.emergencyPct,
    required this.remainingDays,
  });

  final int income;
  final int fixedExpenses;
  final double emergencyPct;
  final int remainingDays;

  @override
  List<Object> get props => [income, fixedExpenses, emergencyPct, remainingDays];
}
