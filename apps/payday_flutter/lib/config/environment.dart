enum AppEnvironment {
  mock,      // Mock data for development
  staging,   // Staging server with test data
  production // Production server with real data
}

class EnvironmentConfig {
  static AppEnvironment _current = AppEnvironment.mock;

  static AppEnvironment get current => _current;

  static void setEnvironment(AppEnvironment env) {
    _current = env;
    print('Environment switched to: ${env.name}');
  }

  static bool get isMock => _current == AppEnvironment.mock;
  static bool get isProduction => _current == AppEnvironment.production;
  static bool get isStaging => _current == AppEnvironment.staging;

  // API Configuration
  static String get apiBaseUrl {
    switch (_current) {
      case AppEnvironment.mock:
        return 'https://payday-production-94a8.up.railway.app';
      case AppEnvironment.staging:
        return 'https://payday-staging.up.railway.app';
      case AppEnvironment.production:
        return 'https://payday-production-94a8.up.railway.app';
    }
  }

  // Feature Flags
  static bool get useRealAds => _current == AppEnvironment.production;
  static bool get useRealPayments => _current == AppEnvironment.production;
  static bool get useRealPassiveIncome => _current != AppEnvironment.mock;

  // Data Sources
  static bool get useMockData => _current == AppEnvironment.mock;

  // Logging Configuration
  static bool get enableDetailedLogging => _current != AppEnvironment.production;
  static bool get enableCrashlytics => _current == AppEnvironment.production;
}