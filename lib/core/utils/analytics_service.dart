import 'package:firebase_analytics/firebase_analytics.dart';

class AnalyticsService {
  const AnalyticsService(this._analytics);
  final FirebaseAnalytics _analytics;

  Future<void> logTransactionAdded({
    required String category,
    required int amount,
  }) =>
      _analytics.logEvent(
        name: 'transaction_added',
        parameters: {'category': category, 'amount': amount},
      );

  Future<void> logSurviveModeTriggered({
    required double remainingPct,
    required int daysLeft,
  }) =>
      _analytics.logEvent(
        name: 'survive_mode_triggered',
        parameters: {
          'remaining_pct': remainingPct,
          'days_left': daysLeft,
        },
      );

  Future<void> logOnboardingCompleted() =>
      _analytics.logEvent(name: 'onboarding_completed');

  Future<void> logReportViewed({required String month}) =>
      _analytics.logEvent(
        name: 'report_viewed',
        parameters: {'month': month},
      );

  Future<void> logSettingsChanged({
    String? theme,
    String? language,
  }) {
    final params = <String, Object>{};
    if (theme != null) params['theme'] = theme;
    if (language != null) params['language'] = language;
    return _analytics.logEvent(name: 'settings_changed', parameters: params);
  }

  Future<void> logInsightViewed() =>
      _analytics.logEvent(name: 'insight_viewed');
}
