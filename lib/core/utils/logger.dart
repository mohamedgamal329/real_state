class Logger {
  Logger._();

  static void event(String name, {String? detail}) {
    // Lightweight analytics-friendly log hook; replace with real sink if needed.
    // Avoid spamming by keeping only key events.
    // ignore: avoid_print
    print('[event] $name${detail != null ? ' :: $detail' : ''}');
  }
}
