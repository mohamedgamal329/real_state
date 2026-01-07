import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:real_state/core/components/app_network_image.dart';
import 'package:real_state/features/models/entities/location_area.dart';

class LocationAreaCard extends StatelessWidget {
  const LocationAreaCard({
    super.key,
    required this.area,
    required this.localeCode,
    this.onEdit,
    this.onDelete,
    this.onTap,
  });

  final LocationArea area;
  final String localeCode;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final localized = area.localizedName(localeCode: localeCode);
    final displayName = localized.isNotEmpty ? localized : 'placeholder_dash'.tr();
    final secondary = localeCode.startsWith('ar') ? area.nameEn : area.nameAr;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap ?? onEdit,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: SizedBox(
                  width: 96,
                  height: 96,
                  child: LocationAreaImage(url: area.imageUrl),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      secondary.isNotEmpty ? secondary : 'placeholder_dash'.tr(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              if (onEdit != null || onDelete != null)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (onEdit != null)
                      IconButton(
                        onPressed: onEdit,
                        icon: const Icon(Icons.edit_outlined),
                        tooltip: 'edit'.tr(),
                      ),
                    if (onDelete != null)
                      IconButton(
                        onPressed: onDelete,
                        icon: const Icon(Icons.delete_outline),
                        color: theme.colorScheme.error,
                        tooltip: 'delete'.tr(),
                      ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class LocationAreaImage extends StatelessWidget {
  const LocationAreaImage({super.key, required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    if (url.isNotEmpty) {
      return AppNetworkImage(url: url, fit: BoxFit.cover);
    }
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Icon(
        Icons.image_not_supported_outlined,
        size: 40,
        color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
      ),
    );
  }
}
