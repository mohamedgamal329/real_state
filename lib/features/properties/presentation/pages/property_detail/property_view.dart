import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:real_state/core/components/app_error_view.dart';
import 'package:real_state/core/components/app_svg_icon.dart';
import 'package:real_state/core/components/app_skeletonizer.dart';
import 'package:real_state/core/components/base_gradient_page.dart';
import 'package:real_state/core/components/custom_app_bar.dart';
import 'package:real_state/core/constants/app_images.dart';
import 'package:real_state/features/models/entities/property.dart';
import 'package:real_state/features/properties/presentation/widgets/property_detail_view.dart';

class PropertyPageView extends StatelessWidget {
  const PropertyPageView({
    super.key,
    required this.property,
    required this.imagesController,
    required this.imagesToShow,
    required this.imagesAccessible,
    required this.phoneAccessible,
    required this.securityGuardPhoneAccessible,
    required this.locationAccessible,
    required this.creatorName,
    required this.isSkeleton,
    required this.canShare,
    required this.canModify,
    required this.canArchiveOrDelete,
    required this.mutationGuard,
    required this.showError,
    required this.onRetry,
    this.errorMessage,
    this.notFound = false,
    this.onShare,
    this.onEdit,
    this.onArchive,
    this.onDelete,
    this.onRequestImages,
    this.onRequestPhone,
    this.onRequestLocation,
  });

  final Property property;
  final ScrollController imagesController;
  final int imagesToShow;
  final bool imagesAccessible;
  final bool phoneAccessible;
  final bool securityGuardPhoneAccessible;
  final bool locationAccessible;
  final String? creatorName;
  final bool isSkeleton;
  final bool canShare;
  final bool canModify;
  final bool canArchiveOrDelete;
  final ValueListenable<bool> mutationGuard;
  final bool showError;
  final String? errorMessage;
  final bool notFound;
  final VoidCallback onRetry;
  final VoidCallback? onShare;
  final VoidCallback? onEdit;
  final VoidCallback? onArchive;
  final VoidCallback? onDelete;
  final VoidCallback? onRequestImages;
  final VoidCallback? onRequestPhone;
  final VoidCallback? onRequestLocation;

  @override
  Widget build(BuildContext context) {
    final showErrorView = showError || notFound;
    final appBarActions = <Widget>[
      if (canShare && onShare != null)
        IconButton(icon: const AppSvgIcon(AppSVG.share), onPressed: onShare),
      if (canModify && onEdit != null)
        IconButton(icon: const AppSvgIcon(AppSVG.edit), onPressed: onEdit),
      if (canArchiveOrDelete && (onArchive != null || onDelete != null))
        ValueListenableBuilder<bool>(
          valueListenable: mutationGuard,
          builder: (context, isBusy, _) => PopupMenuButton<String>(
            enabled: !isBusy,
            onSelected: (value) {
              if (value == 'archive') {
                onArchive?.call();
              }
              if (value == 'delete') {
                onDelete?.call();
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(value: 'archive', child: Text('archive'.tr())),
              PopupMenuItem(value: 'delete', child: Text('delete'.tr())),
            ],
          ),
        ),
    ];

    return Scaffold(
      appBar: CustomAppBar(title: 'property', actions: appBarActions),
      body: BaseGradientPage(
        child: showErrorView
            ? AppErrorView(
                message: errorMessage ?? 'property_not_found'.tr(),
                onRetry: onRetry,
              )
            : AppSkeletonizer(
                enabled: isSkeleton,
                child: PropertyDetailView(
                  property: property,
                  imagesController: imagesController,
                  imagesToShow: imagesToShow,
                  imagesAccessible: imagesAccessible,
                  phoneAccessible: phoneAccessible,
                  securityGuardPhoneAccessible: securityGuardPhoneAccessible,
                  locationAccessible: locationAccessible,
                  creatorName: creatorName,
                  isSkeleton: isSkeleton,
                  onRequestImages: onRequestImages,
                  onRequestPhone: onRequestPhone,
                  onRequestLocation: onRequestLocation,
                ),
              ),
      ),
    );
  }
}
