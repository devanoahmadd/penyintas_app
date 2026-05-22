import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:penyintas_app/core/error/failures.dart';
import 'package:penyintas_app/features/survival/domain/entities/survival_tip_entity.dart';
import 'package:penyintas_app/features/survival/domain/repositories/survival_repository.dart';

class SurvivalTipsParams extends Equatable {
  const SurvivalTipsParams({
    required this.remainingAmount,
    required this.remainingDays,
    required this.language,
  });

  final int remainingAmount;
  final int remainingDays;
  final String language;

  @override
  List<Object> get props => [remainingAmount, remainingDays, language];
}

class GetSurvivalTipsUseCase {
  const GetSurvivalTipsUseCase(this._repo);
  final SurvivalRepository _repo;

  Future<Either<Failure, List<SurvivalTip>>> call(SurvivalTipsParams params) =>
      _repo.getSurvivalTips(
        remainingAmount: params.remainingAmount,
        remainingDays: params.remainingDays,
        language: params.language,
      );
}
