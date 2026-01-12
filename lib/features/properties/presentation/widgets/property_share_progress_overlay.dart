import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../domain/models/property_share_progress.dart';

class PropertyShareProgressOverlay extends StatelessWidget {
  final PropertyShareProgress progress;

  const PropertyShareProgressOverlay({
    super.key,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final clampedProgress = progress.clamp();
    final percent = (clampedProgress.fraction * 100).clamp(0, 100).toInt();
    final stageLabel = clampedProgress.stage.translationKey().tr();
    final detailLabel = _detailLabel(clampedProgress);

    return Stack(
      children: [
        const ModalBarrier(
          color: Colors.black54,
          dismissible: false,
        ),
        Positioned.fill(
          child: Center(
            child: Card(
              elevation: 18,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'share_progress_title'.tr(),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 16),
                    LinearProgressIndicator(
                      value: clampedProgress.fraction,
                      minHeight: 6,
                    ),
                    if (detailLabel != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        detailLabel,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            stageLabel,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                        Text(
                          '$percent%',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  String? _detailLabel(PropertyShareProgress progress) {
    if (!progress.isBulk) return null;
    final current = progress.currentIndex;
    final total = progress.totalProperties;
    if (current == null || total == null) return null;
    return 'share_progress_property_counter'.tr(args: ['$current', '$total']);
  }
}

class PropertyShareProgressOverlayController {
  final ValueNotifier<PropertyShareProgress> _notifier;
  OverlayEntry? _entry;

  PropertyShareProgressOverlayController(PropertyShareProgress initialProgress)
      : _notifier = ValueNotifier(initialProgress);

  void show(BuildContext context) {
    if (_entry != null) return;
    final overlay = Overlay.of(context, rootOverlay: true);
    _entry = OverlayEntry(
      builder: (context) => ValueListenableBuilder<PropertyShareProgress>(
        valueListenable: _notifier,
        builder: (context, progress, _) => PropertyShareProgressOverlay(progress: progress),
      ),
    );
    overlay.insert(_entry!);
  }

  void update(PropertyShareProgress progress) {
    _notifier.value = progress;
  }

  void hide() {
    _entry?.remove();
    _entry = null;
    _notifier.dispose();
  }
}
