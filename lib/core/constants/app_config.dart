enum Environment { dev, prod }

class AppConfig {
  final Environment env;
  final bool isProduction;

  AppConfig._(this.env) : isProduction = env == Environment.prod;

  /// Reads compile-time environment variable `FLAVOR`.
  /// Use `--dart-define=FLAVOR=prod` to set production behavior.
  factory AppConfig.fromEnvironment() {
    const flavor = String.fromEnvironment('FLAVOR', defaultValue: 'dev');
    final env = flavor.toLowerCase() == 'prod'
        ? Environment.prod
        : Environment.dev;
    return AppConfig._(env);
  }

  @override
  String toString() => 'AppConfig(env: $env)';
}
