import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:share_plus/share_plus.dart';
import 'package:real_state/core/components/app_snackbar.dart';
import 'package:real_state/core/constants/user_role.dart';
import 'package:real_state/core/errors/localized_exception.dart';
import 'package:real_state/core/handle_errors/error_mapper.dart';
import 'package:real_state/features/auth/domain/repositories/auth_repository_domain.dart';
import 'package:real_state/features/models/entities/property.dart';
import 'package:real_state/features/properties/domain/models/property_share_progress.dart';
import 'package:real_state/features/properties/domain/property_permissions.dart';
import 'package:real_state/features/properties/domain/services/property_share_service.dart';
import 'package:real_state/features/properties/presentation/utils/image_visibility.dart';
import 'package:real_state/features/properties/presentation/widgets/property_share_progress_overlay.dart';

Future<void> shareMultiplePropertyPdfs({
  required BuildContext context,
  required List<Property> properties,
}) async {
  if (properties.isEmpty) return;
  UserRole? role;
  try {
    final user = await context.read<AuthRepositoryDomain>().userChanges.first;
    role = user?.role;
  } catch (_) {
    role = null;
  }
  if (!canShareProperty(role)) {
    AppSnackbar.show(context, 'collector_action_not_allowed'.tr(), isError: true);
    return;
  }
  final service = context.read<PropertyShareService>();
  final localeCode = context.locale.toString();
  final overlayController = PropertyShareProgressOverlayController(
    const PropertyShareProgress(
      stage: PropertyShareStage.preparingData,
      fraction: 0,
    ),
  );
  overlayController.show(context);
  try {
    final files = <XFile>[];
    for (var i = 0; i < properties.length; i++) {
      final property = properties[i];
      final includeImages = canViewPropertyImages(
            context: context,
            property: property,
          ) &&
          !property.isImagesHidden &&
          property.imageUrls.isNotEmpty;
      final bytes = await service.buildPdfBytes(
        property: property,
        localeCode: localeCode,
        includeImages: includeImages,
        onProgress: (progress) {
          overlayController.update(_batchProgress(progress, i, properties.length));
        },
      );
      files.add(
        XFile.fromData(
          bytes,
          name: '${property.title ?? 'property'.tr()}.pdf',
          mimeType: 'application/pdf',
        ),
      );
    }
    if (files.isEmpty) {
      throw const LocalizedException('share_pdf_not_allowed');
    }
    overlayController.update(_batchProgress(
      PropertyShareProgress(
        stage: PropertyShareStage.uploadingSharing,
        fraction: PropertyShareStage.uploadingSharing.defaultFraction(),
      ),
      properties.length - 1,
      properties.length,
    ));
    // ignore: deprecated_member_use
    await Share.shareXFiles(files, text: 'share_details_pdf'.tr());
    overlayController.update(_batchProgress(
      PropertyShareProgress(
        stage: PropertyShareStage.finalizing,
        fraction: PropertyShareStage.finalizing.defaultFraction(),
      ),
      properties.length - 1,
      properties.length,
    ));
  } on Object catch (e, st) {
    AppSnackbar.show(
      context,
      mapErrorMessage(e, stackTrace: st),
      isError: true,
    );
  } finally {
    overlayController.hide();
  }
}

PropertyShareProgress _batchProgress(
  PropertyShareProgress progress,
  int propertyIndex,
  int totalProperties,
) {
  if (totalProperties <= 0) return progress;
  final clampedIndex = propertyIndex.clamp(0, totalProperties - 1);
  final propertyBase = clampedIndex / totalProperties;
  final fraction = (propertyBase + progress.fraction / totalProperties).clamp(0.0, 1.0);
  return PropertyShareProgress(
    stage: progress.stage,
    fraction: fraction,
    isBulk: true,
    currentIndex: clampedIndex + 1,
    totalProperties: totalProperties,
  );
}
