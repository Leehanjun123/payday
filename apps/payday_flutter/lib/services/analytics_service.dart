import 'package:firebase_analytics/firebase_analytics.dart';

class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  static FirebaseAnalytics get analytics => FirebaseAnalytics.instance;

  // App lifecycle events
  static Future<void> logAppOpen() async {
    await analytics.logAppOpen();
  }

  // User authentication events
  static Future<void> logLogin(String method) async {
    await analytics.logLogin(loginMethod: method);
  }

  static Future<void> logSignUp(String method) async {
    await analytics.logSignUp(signUpMethod: method);
  }

  // Earning events
  static Future<void> logEarningEvent({
    required String earningType,
    required double amount,
    required String source,
  }) async {
    await analytics.logEvent(
      name: 'earning_completed',
      parameters: {
        'earning_type': earningType,
        'amount': amount,
        'source': source,
        'currency': 'KRW',
      },
    );
  }

  // Ad viewing events
  static Future<void> logAdViewed({
    required String adType,
    required String adUnitId,
    double? reward,
  }) async {
    await analytics.logEvent(
      name: 'ad_viewed',
      parameters: {
        'ad_type': adType,
        'ad_unit_id': adUnitId,
        if (reward != null) 'reward_amount': reward,
      },
    );
  }

  // Survey completion events
  static Future<void> logSurveyCompleted({
    required String surveyId,
    required String provider,
    required double reward,
    required int duration,
  }) async {
    await analytics.logEvent(
      name: 'survey_completed',
      parameters: {
        'survey_id': surveyId,
        'provider': provider,
        'reward_amount': reward,
        'duration_seconds': duration,
      },
    );
  }

  // Withdrawal events
  static Future<void> logWithdrawalRequest({
    required double amount,
    required String method,
  }) async {
    await analytics.logEvent(
      name: 'withdrawal_requested',
      parameters: {
        'amount': amount,
        'method': method,
        'currency': 'KRW',
      },
    );
  }

  static Future<void> logWithdrawalCompleted({
    required double amount,
    required String method,
  }) async {
    await analytics.logEvent(
      name: 'withdrawal_completed',
      parameters: {
        'amount': amount,
        'method': method,
        'currency': 'KRW',
      },
    );
  }

  // Screen view events
  static Future<void> logScreenView({
    required String screenName,
    String? screenClass,
  }) async {
    await analytics.logScreenView(
      screenName: screenName,
      screenClass: screenClass,
    );
  }

  // Daily bonus events
  static Future<void> logDailyBonusClaimed({
    required int streakDays,
    required double bonusAmount,
  }) async {
    await analytics.logEvent(
      name: 'daily_bonus_claimed',
      parameters: {
        'streak_days': streakDays,
        'bonus_amount': bonusAmount,
      },
    );
  }

  // Portfolio events
  static Future<void> logPortfolioCreated({
    required String portfolioType,
    required double initialAmount,
  }) async {
    await analytics.logEvent(
      name: 'portfolio_created',
      parameters: {
        'portfolio_type': portfolioType,
        'initial_amount': initialAmount,
      },
    );
  }

  static Future<void> logInvestmentMade({
    required String assetType,
    required double amount,
    required String portfolioId,
  }) async {
    await analytics.logEvent(
      name: 'investment_made',
      parameters: {
        'asset_type': assetType,
        'amount': amount,
        'portfolio_id': portfolioId,
      },
    );
  }

  // User engagement events
  static Future<void> logFeatureUsed({
    required String featureName,
    Map<String, dynamic>? customParameters,
  }) async {
    await analytics.logEvent(
      name: 'feature_used',
      parameters: {
        'feature_name': featureName,
        ...?customParameters,
      },
    );
  }

  // Error tracking
  static Future<void> logError({
    required String errorType,
    required String errorMessage,
    String? screenName,
  }) async {
    await analytics.logEvent(
      name: 'app_error',
      parameters: {
        'error_type': errorType,
        'error_message': errorMessage,
        if (screenName != null) 'screen_name': screenName,
      },
    );
  }

  // Performance events
  static Future<void> logPerformanceEvent({
    required String eventName,
    required int durationMs,
    Map<String, dynamic>? customParameters,
  }) async {
    await analytics.logEvent(
      name: 'performance_$eventName',
      parameters: {
        'duration_ms': durationMs,
        ...?customParameters,
      },
    );
  }

  // User properties
  static Future<void> setUserProperty({
    required String name,
    required String value,
  }) async {
    await analytics.setUserProperty(name: name, value: value);
  }

  static Future<void> setUserId(String userId) async {
    await analytics.setUserId(id: userId);
  }

  // Custom events for PayDay specific features
  static Future<void> logEarningsGoalSet({
    required double goalAmount,
    required String timeframe,
  }) async {
    await analytics.logEvent(
      name: 'earnings_goal_set',
      parameters: {
        'goal_amount': goalAmount,
        'timeframe': timeframe,
      },
    );
  }

  static Future<void> logReferralCompleted({
    required String referralCode,
    required double bonusAmount,
  }) async {
    await analytics.logEvent(
      name: 'referral_completed',
      parameters: {
        'referral_code': referralCode,
        'bonus_amount': bonusAmount,
      },
    );
  }
}