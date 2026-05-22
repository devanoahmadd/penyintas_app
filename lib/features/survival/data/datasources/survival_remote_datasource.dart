import 'package:cloud_functions/cloud_functions.dart';
import 'package:penyintas_app/features/survival/domain/entities/survival_tip_entity.dart';

abstract class SurvivalRemoteDatasource {
  Future<List<SurvivalTip>> getSurvivalTips({
    required int remainingAmount,
    required int remainingDays,
    required String language,
  });
}

class SurvivalRemoteDatasourceImpl implements SurvivalRemoteDatasource {
  const SurvivalRemoteDatasourceImpl({required FirebaseFunctions functions})
      : _functions = functions;

  final FirebaseFunctions _functions;

  @override
  Future<List<SurvivalTip>> getSurvivalTips({
    required int remainingAmount,
    required int remainingDays,
    required String language,
  }) async {
    final callable = _functions.httpsCallable('getSurvivalTips');
    final result = await callable.call<Map<String, dynamic>>({
      'amountCents': remainingAmount,
      'days': remainingDays,
      'language': language,
    });
    final rawTips = result.data['tips'];
    if (rawTips is! List) {
      throw const FormatException('CF response: tips bukan List');
    }
    final tipsData = rawTips.cast<Map<String, dynamic>>();
    return tipsData
        .map((t) => SurvivalTip(
              title: t['title'] as String,
              description: t['description'] as String,
              estimatedSaving: (t['estimatedSaving'] as num).toInt(),
            ))
        .toList();
  }
}
