import 'package:intl/intl.dart';
import 'package:meta/meta.dart';

@immutable
class SubLocation {
  final String id;
  final String areaId;
  final String nameAr;
  final String nameEn;
  final bool isActive;
  final DateTime createdAt;

  const SubLocation({
    required this.id,
    required this.areaId,
    required this.nameAr,
    required this.nameEn,
    required this.isActive,
    required this.createdAt,
  });

  String localizedName({String? localeCode}) {
    final code = (localeCode ?? Intl.getCurrentLocale()).toLowerCase();
    final lang = code.split('_').first;
    if (lang == 'ar') {
      return nameAr.isNotEmpty ? nameAr : (nameEn.isNotEmpty ? nameEn : '');
    }
    return nameEn.isNotEmpty ? nameEn : (nameAr.isNotEmpty ? nameAr : '');
  }

  String get name => localizedName();

  @override
  String toString() => 'SubLocation(id: $id, areaId: $areaId, ar: $nameAr, en: $nameEn)';
}
