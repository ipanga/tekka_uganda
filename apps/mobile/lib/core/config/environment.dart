/// Application environment
enum Environment { dev, staging, prod }

/// Holds the current environment, set once at app startup.
/// Defaults to prod for safety.
class EnvironmentConfig {
  static Environment _current = Environment.prod;

  static Environment get current => _current;

  /// Called once from the main entry point.
  static void init(Environment env) {
    _current = env;
  }

  static bool get isDev => _current == Environment.dev;
  static bool get isStaging => _current == Environment.staging;
  static bool get isProd => _current == Environment.prod;
}
