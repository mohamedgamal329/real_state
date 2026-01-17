import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:real_state/core/components/app_svg_icon.dart';
import 'package:real_state/core/constants/app_images.dart';

class PropertyDetailLocationSection extends StatelessWidget {
  const PropertyDetailLocationSection({
    super.key,
    required this.locationUrl,
    required this.hasLocation,
    required this.locationAccessible,
    this.onTap,
    this.onRequestLocation,
  });

  final String locationUrl;
  final bool hasLocation;
  final bool locationAccessible;
  final VoidCallback? onTap;
  final VoidCallback? onRequestLocation;

  @override
  Widget build(BuildContext context) {
    if (!hasLocation) return const SizedBox.shrink();
    if (locationAccessible) {
      return _AccessibleLocation(locationUrl: locationUrl, onTap: onTap);
    }
    return _HiddenLocation(onRequestLocation: onRequestLocation);
  }
}

class _AccessibleLocation extends StatelessWidget {
  const _AccessibleLocation({required this.locationUrl, this.onTap});

  final String locationUrl;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            AppSvgIcon(AppSVG.locationOn, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('open_location'.tr(), style: theme.textTheme.titleSmall),
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
            const AppSvgIcon(AppSVG.openInNew, size: 16),
          ],
        ),
      ),
    );
  }
}

class _HiddenLocation extends StatelessWidget {
  const _HiddenLocation({this.onRequestLocation});

  final VoidCallback? onRequestLocation;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            const AppSvgIcon(AppSVG.lock, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'location_hidden'.tr(),
                style: theme.textTheme.bodyMedium,
              ),
            ),
            if (onRequestLocation != null)
              ElevatedButton.icon(
                icon: const AppSvgIcon(AppSVG.lockOpen),
                label: Text('request_location_access'.tr()),
                onPressed: onRequestLocation,
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
