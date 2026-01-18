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

  // Get temp directory and create a unique sub-directory per share operation
  // This avoids filename collisions and Gmail caching issues (FIX F)
  final tempDir = await getTemporaryDirectory();
  final timestamp = DateTime.now().millisecondsSinceEpoch;
  // Use a completely unique directory for this specific share intent
  final shareDir = Directory('${tempDir.path}/share_pdfs_$timestamp');
  await shareDir.create(recursive: true);

  final tempFiles = <File>[];
  try {
    final xFiles = <XFile>[];
    final usedNames = <String>{};

    debugPrint('share_pdfs_selected=${properties.length}');

    // Batch process properties to build PDFs
    for (var i = 0; i < properties.length; i++) {
      final property = properties[i];
      final itemStopwatch = Stopwatch()..start();

      final fileName = buildSharePdfFileName(
        title: property.title,
        fallbackTitle: fallbackTitle,
        usedNames: usedNames,
        propertyId: property.id,
      );

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

      // Write to real temp file with clean filename (Gmail truth)
      final tempFile = File('${shareDir.path}/$fileName');
      await tempFile.writeAsBytes(bytes);
      // Flush to ensure OS sees it.
      await tempFile.parent.create(recursive: true);
      tempFiles.add(tempFile);

      // EXTREMELY CRITICAL: Use XFile with the explicit name if possible,
      // but share_plus takes name from path.
      final xFile = XFile(tempFile.path, name: fileName);
      xFiles.add(xFile);

      debugPrint('share_dir=${shareDir.path}');
      debugPrint(
        'share_pdf_${i + 1}_path=${tempFile.path} size=${bytes.length}',
      );
      if (kDebugMode) {
        debugPrint(
          'share_pdf: ${property.id} built in ${itemStopwatch.elapsedMilliseconds}ms -> $fileName',
        );
      }
    }

    if (xFiles.isEmpty) {
      throw const LocalizedException('share_pdf_not_allowed');
    }

    debugPrint('share_pdfs_created=${xFiles.length}');
    debugPrint('share_pdfs_count=${xFiles.length}');

    overlayController.update(
      _batchProgress(
        PropertyShareProgress(
          stage: PropertyShareStage.uploadingSharing,
          fraction: PropertyShareStage.uploadingSharing.defaultFraction(),
        ),
        properties.length - 1,
        properties.length,
      ),
    );

    // FIX F: Share all XFiles gathered in the loop.
    // Passing full list ensures multi-attach in Gmail.
    // ignore: deprecated_member_use
    await Share.shareXFiles(
      xFiles,
      subject: 'properties_share_subject'.tr(
        args: [properties.length.toString()],
      ),
      text: properties.length == 1 ? 'share_details_pdf'.tr() : null,
    );

    overlayController.update(
      _batchProgress(
        PropertyShareProgress(
          stage: PropertyShareStage.finalizing,
          fraction: PropertyShareStage.finalizing.defaultFraction(),
        ),
        properties.length - 1,
        properties.length,
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
  final sanitizedBase = sanitizeFileName(baseTitle);
  var fileName = '$sanitizedBase.pdf';
  if (!usedNames.contains(fileName)) {
    usedNames.add(fileName);
    return fileName;
  }
  // Use numeric suffixes for duplicate titles - never expose property IDs
  var suffix = 2;
  fileName = '$sanitizedBase ($suffix).pdf';
  while (usedNames.contains(fileName)) {
    suffix++;
    fileName = '$sanitizedBase ($suffix).pdf';
  }
  usedNames.add(fileName);
  return fileName;
}

String sanitizeFileName(String input) {
  // Allow alphanumeric, spaces, dashes, underscore. Replace others with underscore.
  // This is the "Hard Truth" for Android/Gmail file reliability.
  final sanitized = input.replaceAll(RegExp(r'[^\w\s\-]'), '_');
  // Collapse multiple underscores/spaces for beauty
  return sanitized.replaceAll(RegExp(r'[\s_]+'), ' ').trim();
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
