import 'package:intl/intl.dart';
import 'package:meta/meta.dart';

@immutable
class LocationArea {
  final String id;
  final String nameAr;
  final String nameEn;
  final String imageUrl;
  final bool isActive;
  final DateTime createdAt;

  const LocationArea({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.imageUrl,
    required this.isActive,
    required this.createdAt,
  });

  /// Localized display name based on the provided [localeCode] or current locale.
  String localizedName({String? localeCode}) {
    final code = (localeCode ?? Intl.getCurrentLocale()).toLowerCase();
    final lang = code.split('_').first;
    if (lang == 'ar') {
      return nameAr.isNotEmpty ? nameAr : (nameEn.isNotEmpty ? nameEn : '');
    }
    return nameEn.isNotEmpty ? nameEn : (nameAr.isNotEmpty ? nameAr : '');
  }

  /// Backwards-compatible name getter (localized).
  String get name => localizedName();

  bool get hasImage => imageUrl.isNotEmpty;

  @override
  String toString() => 'LocationArea(id: $id, ar: $nameAr, en: $nameEn)';
}
