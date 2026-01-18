import 'dart:async';
import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path_provider/path_provider.dart';
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
import 'package:real_state/core/utils/image_visibility.dart';
import 'package:real_state/core/widgets/property_share_progress_overlay.dart';

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
    AppSnackbar.show(
      context,
      'collector_action_not_allowed'.tr(),
      type: AppSnackbarType.error,
    );
    return;
  }
  final service = context.read<PropertyShareService>();
  final localeCode = context.locale.toString();
  final fallbackTitle = 'property'.tr();
  final overlayController = PropertyShareProgressOverlayController(
    const PropertyShareProgress(
      stage: PropertyShareStage.preparingData,
      fraction: 0,
    ),
  );
  overlayController.show(context);

  // Get temp directory for real file creation
  final tempDir = await getTemporaryDirectory();
  final shareDir = Directory('${tempDir.path}/share_pdfs');
  if (await shareDir.exists()) {
    await shareDir.delete(recursive: true);
  }
  await shareDir.create(recursive: true);

  final tempFiles = <File>[];
  try {
    final files = <XFile>[];
    final usedNames = <String>{};
    final items = List<_ShareItem>.unmodifiable(
      properties.map(
        (property) => _ShareItem(
          property,
          buildSharePdfFileName(
            title: property.title,
            fallbackTitle: fallbackTitle,
            usedNames: usedNames,
            propertyId: property.id,
          ),
        ),
      ),
    );
    final batchStopwatch = Stopwatch()..start();
    for (var i = 0; i < items.length; i++) {
      final item = items[i];
      final property = item.property;
      final itemStopwatch = Stopwatch()..start();
      final includeImages =
          canViewPropertyImages(context: context, property: property) &&
          !property.isImagesHidden &&
          property.imageUrls.isNotEmpty;
      final bytes = await service.buildPdfBytes(
        property: property,
        localeCode: localeCode,
        includeImages: includeImages,
        onProgress: (progress) {
          overlayController.update(
            _batchProgress(progress, i, properties.length),
          );
        },
      );

      // Write to real temp file with correct filename (FIX 5: Gmail sees this name)
      final tempFile = File('${shareDir.path}/${item.fileName}');
      await tempFile.writeAsBytes(bytes);
      tempFiles.add(tempFile);
      files.add(XFile(tempFile.path));

      if (kDebugMode) {
        debugPrint(
          'share_pdf: ${property.id} built in ${itemStopwatch.elapsedMilliseconds}ms -> ${item.fileName}',
        );
      }
    }
    if (files.isEmpty) {
      throw const LocalizedException('share_pdf_not_allowed');
    }
    if (kDebugMode) {
      debugPrint(
        'share_pdf: batch ready in ${batchStopwatch.elapsedMilliseconds}ms',
      );
    }
    overlayController.update(
      _batchProgress(
        PropertyShareProgress(
          stage: PropertyShareStage.uploadingSharing,
          fraction: PropertyShareStage.uploadingSharing.defaultFraction(),
        ),
        items.length - 1,
        items.length,
      ),
    );
    await Share.shareXFiles(
      files,
      text: 'share_details_pdf'.tr(),
      subject: 'properties_share_subject'.tr(args: [items.length.toString()]),
    );
    overlayController.update(
      _batchProgress(
        PropertyShareProgress(
          stage: PropertyShareStage.finalizing,
          fraction: PropertyShareStage.finalizing.defaultFraction(),
        ),
        items.length - 1,
        items.length,
      ),
    );
  } on Object catch (e, st) {
    AppSnackbar.show(
      context,
      mapErrorMessage(e, stackTrace: st),
      type: AppSnackbarType.error,
    );
  } finally {
    overlayController.hide();
  }
}

@visibleForTesting
String buildSharePdfFileName({
  required String? title,
  required String fallbackTitle,
  required Set<String> usedNames,
  required String propertyId,
}) {
  final trimmedTitle = title?.trim();
  final baseTitle = trimmedTitle?.isNotEmpty == true
      ? trimmedTitle!
      : fallbackTitle;
  var fileName = '$baseTitle.pdf';
  if (!usedNames.contains(fileName)) {
    usedNames.add(fileName);
    return fileName;
  }
  // Use numeric suffixes for duplicate titles - never expose property IDs
  var suffix = 2;
  fileName = '$baseTitle ($suffix).pdf';
  while (usedNames.contains(fileName)) {
    suffix++;
    fileName = '$baseTitle ($suffix).pdf';
  }
  usedNames.add(fileName);
  return fileName;
}

PropertyShareProgress _batchProgress(
  PropertyShareProgress progress,
  int propertyIndex,
  int totalProperties,
) {
  if (totalProperties <= 0) return progress;
  final clampedIndex = propertyIndex.clamp(0, totalProperties - 1);
  final propertyBase = clampedIndex / totalProperties;
  final fraction = (propertyBase + progress.fraction / totalProperties).clamp(
    0.0,
    1.0,
  );
  return PropertyShareProgress(
    stage: progress.stage,
    fraction: fraction,
    isBulk: true,
    currentIndex: clampedIndex + 1,
    totalProperties: totalProperties,
  );
}

class _ShareItem {
  final Property property;
  final String fileName;

  const _ShareItem(this.property, this.fileName);
}
