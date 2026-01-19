import 'dart:ui' as ui;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:real_state/core/components/app_snackbar.dart';
import 'package:real_state/core/validation/validators.dart';
import 'package:real_state/features/models/entities/property.dart';
import 'package:real_state/core/constants/app_images.dart';
import 'package:url_launcher/url_launcher.dart';

import '../pages/property_image_viewer/property_image_viewer_page.dart';
import 'property_detail/property_detail_description.dart';
import 'property_detail/property_detail_header.dart';
import 'property_detail/property_detail_images.dart';
import 'property_detail/property_detail_location.dart';
import 'property_detail/property_detail_meta.dart';
import 'property_detail/property_detail_phone_section.dart';

class PropertyDetailView extends StatefulWidget {
  final Property property;
  final ScrollController imagesController;
  final int imagesToShow;
  final bool imagesAccessible;
  final bool phoneAccessible;
  final bool securityNumberAccessible;
  final bool locationAccessible;
  final VoidCallback? onRequestImages;
  final VoidCallback? onRequestPhone;
  final VoidCallback? onRequestLocation;
  final String? creatorName;
  final bool isSkeleton;

  const PropertyDetailView({
    super.key,
    required this.property,
    required this.imagesController,
    required this.imagesToShow,
    required this.imagesAccessible,
    required this.phoneAccessible,
    required this.securityNumberAccessible,
    required this.locationAccessible,
    this.onRequestImages,
    this.onRequestPhone,
    this.onRequestLocation,
    this.creatorName,
    this.isSkeleton = false,
  });

  @override
  State<PropertyDetailView> createState() => _PropertyDetailViewState();
}

class _PropertyDetailViewState extends State<PropertyDetailView> {
  bool _showFullDescription = false;

  @override
  Widget build(BuildContext context) {
    final p = widget.property;
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final surface = theme.colorScheme.surfaceContainerHighest;
    final description = p.description ?? '';
    final hasDescription = description.isNotEmpty;
    final hasPhone = (p.ownerPhoneEncryptedOrHiddenStored ?? '')
        .trim()
        .isNotEmpty;
    final hasLocation = Validators.isValidUrl(p.locationUrl);
    final hasSecurityNumber = (p.securityNumberEncryptedOrHiddenStored ?? '')
        .trim()
        .isNotEmpty;
    final availableWidth =
        MediaQuery.sizeOf(context).width - 32; // padding from page
    final canExpandDescription =
        hasDescription &&
        _descriptionExceedsThreeLines(
          description,
          textTheme.bodyMedium,
          availableWidth > 0
              ? availableWidth
              : MediaQuery.sizeOf(context).width,
          Directionality.of(context),
        );
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PropertyDetailHeader(
            title: p.title ?? 'untitled'.tr(),
            price: p.price,
            purpose: p.purpose,
            createdAt: p.createdAt,
            addedBy: (widget.creatorName ?? '').isNotEmpty
                ? widget.creatorName!
                : 'unknown'.tr(),
          ),
          const SizedBox(height: 16),
          if (hasDescription)
            PropertyDetailDescription(
              description: description,
              isExpanded: _showFullDescription,
              canExpand: canExpandDescription,
              onToggle: () =>
                  setState(() => _showFullDescription = !_showFullDescription),
              textStyle: textTheme.bodyMedium,
            ),
          const SizedBox(height: 20),
          PropertyDetailImagesSection(
            property: p,
            imagesVisible: widget.imagesAccessible,
            scrollController: widget.imagesController,
            imagesToShow: widget.imagesToShow,
            showSkeleton: widget.isSkeleton,
            onRequestAccess: widget.onRequestImages,
            onImageTap: (index) => _openImageViewer(context, index),
          ),
          const SizedBox(height: 20),
          PropertyDetailLocationSection(
            locationUrl: p.locationUrl ?? '',
            hasLocation: hasLocation,
            locationAccessible: widget.locationAccessible,
            onTap: () => _openLocation(context, p.locationUrl ?? ''),
            onRequestLocation: widget.onRequestLocation,
          ),
          if (hasLocation) const SizedBox(height: 20),
          if (hasPhone) ...[
            PropertyDetailPhoneSection(
              phoneVisible: widget.phoneAccessible,
              phoneText: p.ownerPhoneEncryptedOrHiddenStored,
              onRequestAccess: widget.onRequestPhone,
            ),
            const SizedBox(height: 20),
          ],

          if (hasSecurityNumber) ...[
            PropertyDetailPhoneSection(
              labelKey: 'security_number',
              phoneVisible: widget.securityNumberAccessible,
              phoneText: p.securityNumberEncryptedOrHiddenStored,
              onRequestAccess: widget.onRequestPhone,
              keyPrefix: 'security_number',
              icon: AppSVG.lock,
              showCallButton: false,
              hiddenLabelKey: 'security_number_hidden',
            ),
            const SizedBox(height: 20),
          ],
          const SizedBox(height: 20),
          PropertyDetailMetaSection(property: p, surfaceColor: surface),
        ],
      ),
    );
  }

  Future<void> _openLocation(BuildContext context, String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && context.mounted) {
      AppSnackbar.show(
        context,
        'location_unavailable'.tr(),
        type: AppSnackbarType.error,
      );
    }
  }

  void _openImageViewer(BuildContext context, int index) {
    if (!widget.imagesAccessible || widget.property.imageUrls.isEmpty) return;
    GoRouter.of(context).push(
      '/property/${widget.property.id}/images',
      extra: PropertyImageViewerArgs(
        images: widget.property.imageUrls,
        initialIndex: index,
      ),
    );
  }

  bool _descriptionExceedsThreeLines(
    String text,
    TextStyle? style,
    double maxWidth,
    ui.TextDirection direction,
  ) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      maxLines: 3,
      textDirection: direction,
    )..layout(maxWidth: maxWidth);
    return painter.didExceedMaxLines;
  }
}
