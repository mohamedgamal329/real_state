import 'package:real_state/core/constants/user_role.dart';
import 'package:real_state/core/errors/localized_exception.dart';
import 'package:real_state/features/models/entities/property.dart';
import 'package:real_state/features/properties/domain/models/property_share_progress.dart';
import 'package:real_state/features/properties/domain/property_permissions.dart';
import 'package:real_state/features/properties/domain/services/property_share_service.dart';

class SharePropertyPdfUseCase {
  final PropertyShareService _shareService;

  SharePropertyPdfUseCase(this._shareService);

  Future<void> call({
    required Property property,
    required UserRole? role,
    required String? userId,
    required bool imagesVisible,
    required bool locationVisible,
    required String localeCode,
    bool includeImages = true,
    PropertyShareProgressCallback? onProgress,
  }) async {
    if (!canShareProperty(role)) {
      throw const LocalizedException('collector_action_not_allowed');
    }
    final shouldIncludeImages = includeImages && imagesVisible;
    await _shareService.sharePdf(
      property: property,
      localeCode: localeCode,
      locationVisible: locationVisible,
      includeImages: shouldIncludeImages,
      onProgress: onProgress,
    );
  }
}
