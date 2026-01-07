import 'dart:ui' as ui;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:real_state/core/components/primary_button.dart';
import 'package:real_state/core/components/app_snackbar.dart';
import 'package:real_state/core/constants/aed_text.dart';
import 'package:real_state/core/utils/price_formatter.dart';
import 'package:real_state/core/validation/validators.dart';
import 'package:real_state/features/models/entities/property.dart';
import 'package:url_launcher/url_launcher.dart';

import '../pages/property_image_viewer_page.dart';
import 'property_images_section.dart';
import 'property_phone_section.dart';

class PropertyDetailView extends StatefulWidget {
  final Property property;
  final ScrollController imagesController;
  final int imagesToShow;
  final bool imagesAccessible;
  final bool phoneAccessible;
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
          _Header(
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
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    description,
                    style: textTheme.bodyMedium,
                    maxLines: _showFullDescription ? null : 3,
                    overflow: _showFullDescription
                        ? TextOverflow.visible
                        : TextOverflow.ellipsis,
                  ),
                  if (canExpandDescription)
                    TextButton(
                      onPressed: () => setState(
                        () => _showFullDescription = !_showFullDescription,
                      ),
                      child: Text(
                        _showFullDescription
                            ? 'show_less'.tr()
                            : 'read_more'.tr(),
                      ),
                    ),
                ],
              ),
            ),
          const SizedBox(height: 20),
          Text('images'.tr(), style: textTheme.titleMedium),
          const SizedBox(height: 8),
          PropertyImagesSection(
            property: p,
            imagesVisible: widget.imagesAccessible,
            scrollController: widget.imagesController,
            imagesToShow: widget.imagesToShow,
            showSkeleton: widget.isSkeleton,
            onRequestAccess: widget.onRequestImages,
            onImageTap: (index) => _openImageViewer(context, index),
          ),
          const SizedBox(height: 20),
          _buildLocationRow(
            context,
            p.locationUrl ?? '',
            hasLocation: hasLocation,
          ),
          if (hasLocation) const SizedBox(height: 20),
          if (hasPhone) ...[
            Text('owner_phone'.tr(), style: textTheme.titleMedium),
            const SizedBox(height: 8),
            PropertyPhoneSection(
              phoneVisible: widget.phoneAccessible,
              phoneText: p.ownerPhoneEncryptedOrHiddenStored,
              onRequestAccess: widget.onRequestPhone,
            ),
            const SizedBox(height: 20),
          ],
          const SizedBox(height: 20),
          _MetaSection(property: p, surface: surface),
        ],
      ),
    );
  }

  Widget _buildLocationRow(
    BuildContext context,
    String locationUrl, {
    required bool hasLocation,
  }) {
    final theme = Theme.of(context);
    if (!hasLocation) return const SizedBox.shrink();
    if (widget.locationAccessible) {
      return InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _openLocation(context, locationUrl),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                Icons.location_on_outlined,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'open_location'.tr(),
                      style: theme.textTheme.titleSmall,
                    ),
                    Text(
                      locationUrl,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.open_in_new, size: 16),
            ],
          ),
        ),
      );
    }
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            const Icon(Icons.lock_outline, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'location_hidden'.tr(),
                style: theme.textTheme.bodyMedium,
              ),
            ),
            if (widget.onRequestLocation != null)
              PrimaryButton(
                label: 'request_location_access'.tr(),
                expand: false,
                onPressed: widget.onRequestLocation,
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _openLocation(BuildContext context, String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && context.mounted) {
      AppSnackbar.show(context, 'location_unavailable'.tr(), isError: true);
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

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Chip(
      avatar: Icon(icon, size: 18, color: theme.colorScheme.primary),
      label: Text(label, style: theme.textTheme.bodyMedium),
      backgroundColor: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String title;
  final double? price;
  final PropertyPurpose purpose;
  final DateTime createdAt;
  final String addedBy;

  const _Header({
    required this.title,
    required this.price,
    required this.purpose,
    required this.createdAt,
    required this.addedBy,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'purpose.${purpose.name}'.tr().toUpperCase(),
                style: textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (price != null)
          Text(
            PriceFormatter.format(
              price!,
              locale: context.locale.toString(),
              currency: AED,
            ),
            style: textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w900,
              fontFamily: 'AED',
            ),
          ),
        const SizedBox(height: 8),
        Text(
          '${'added_by'.tr()}: $addedBy',
          style: textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _MetaSection extends StatelessWidget {
  final Property property;
  final Color surface;

  const _MetaSection({required this.property, required this.surface});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final p = property;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('details'.tr(), style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              if (p.rooms != null)
                _InfoChip(
                  icon: Icons.bed,
                  label: 'rooms_with_value'.tr(args: [p.rooms.toString()]),
                ),
              if (p.kitchens != null)
                _InfoChip(
                  icon: Icons.restaurant_outlined,
                  label: 'kitchens_with_value'.tr(
                    args: [p.kitchens.toString()],
                  ),
                ),
              if (p.floors != null)
                _InfoChip(
                  icon: Icons.stairs,
                  label: 'floors_with_value'.tr(args: [p.floors.toString()]),
                ),
              _InfoChip(
                icon: Icons.flag,
                label: 'purpose_with_value'.tr(
                  args: ['purpose.${p.purpose.name}'.tr()],
                ),
              ),
              _InfoChip(
                icon: Icons.check_circle,
                label: 'status_with_value'.tr(args: [p.status.name]),
              ),
              if (p.hasPool)
                _InfoChip(
                  icon: Icons.pool,
                  label: 'has_pool_with_value'.tr(args: ['yes'.tr()]),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
