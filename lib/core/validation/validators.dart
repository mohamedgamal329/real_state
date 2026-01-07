class Validators {
  static bool isNotEmpty(String? s) => s != null && s.trim().isNotEmpty;

  static bool isEmail(String? s) {
    if (s == null) return false;
    final re = RegExp(r"^[\w-.]+@[\w-]+\.[a-zA-Z]{2,}");
    return re.hasMatch(s);
  }

  static bool isSelected<T>(T? value) => value != null;

  static bool isMinLength(String? s, int min) => (s ?? '').trim().length >= min;

  static bool isValidName(String? s, {int min = 2}) {
    final value = s?.trim() ?? '';
    if (value.length < min) return false;
    final re = RegExp(r'^[\p{L}\s]+$', unicode: true);
    return re.hasMatch(value);
  }

  static bool isStrongPassword(String? s) {
    if (s == null) return false;
    if (s.trim().length < 8) return false;
    final hasLetter = RegExp(r'[A-Za-z]').hasMatch(s);
    final hasNumber = RegExp(r'[0-9]').hasMatch(s);
    return hasLetter && hasNumber;
  }

  static bool passwordsMatch(String? a, String? b) => (a ?? '') == (b ?? '');

  static bool isValidUrl(String? s) {
    if (s == null || s.trim().isEmpty) return false;
    final uri = Uri.tryParse(s.trim());
    if (uri == null) return false;
    return uri.hasScheme && (uri.isAbsolute);
  }

  static bool isValidPhone(String? s) {
    final value = s?.replaceAll(RegExp(r'[^\d+]'), '') ?? '';
    return value.length >= 6;
  }

  static bool isValidPrice(String? s) {
    final price = parsePrice(s);
    return price != null && price > 0;
  }

  static double? parsePrice(String? s) {
    if (s == null) return null;
    final cleaned = s.replaceAll(RegExp(r'[^\d.]'), '');
    if (cleaned.isEmpty) return null;
    return double.tryParse(cleaned);
  }
}
