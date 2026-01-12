/// Utility that enforces single-flight execution for asynchronous requests.
class SingleFlightGuard {
  bool _busy = false;

  /// Runs [action] only if no other guarded work is active.
  /// Returns true if [action] was executed; false otherwise.
  Future<bool> run(Future<void> Function() action) async {
    if (_busy) return false;
    _busy = true;
    try {
      await action();
    } finally {
      _busy = false;
    }
    return true;
  }

  bool get isBusy => _busy;
}
