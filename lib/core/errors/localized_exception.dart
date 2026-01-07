/// Simple exception carrying a translation key and optional args for UI display.
class LocalizedException implements Exception {
  final String key;
  final List<String> args;

  const LocalizedException(this.key, {this.args = const []});

  @override
  String toString() => 'LocalizedException($key, args: $args)';
}
