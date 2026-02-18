/// Application environment
enum Environment { dev, staging, prod }

/// Holds the current environment, set once at app startup.
/// Defaults to prod for safety.
class EnvironmentConfig {
  static Environment _current = Environment.prod;
  static bool _initialized = false;

  static Environment get current => _current;

  /// Called once from the main entry point. First call wins.
  static void init(Environment env) {
    if (_initialized) return;
    _initialized = true;
    _current = env;
  }

  static bool get isDev => _current == Environment.dev;
  static bool get isStaging => _current == Environment.staging;
  static bool get isProd => _current == Environment.prod;
}
