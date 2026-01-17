import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'property_editor_progress.dart';

class PropertyEditorProgressOverlay extends StatelessWidget {
  final PropertyEditorProgress progress;

  const PropertyEditorProgressOverlay({super.key, required this.progress});

  @override
  Widget build(BuildContext context) {
    final clampedProgress = progress.clamp();
    final percent = (clampedProgress.fraction * 100).clamp(0, 100).toInt();
    final stageLabel = clampedProgress.stage.translationKey().tr();

    return Stack(
      children: [
        const ModalBarrier(color: Colors.black54, dismissible: false),
        Positioned.fill(
          child: Center(
            child: Card(
              elevation: 18,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 32,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'saving_property'.tr(),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    LinearProgressIndicator(
                      value: clampedProgress.fraction,
                      minHeight: 6,
                    ),
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
}

class PropertyEditorProgressOverlayController {
  final ValueNotifier<PropertyEditorProgress> _notifier;
  OverlayEntry? _entry;

  PropertyEditorProgressOverlayController(
    PropertyEditorProgress initialProgress,
  ) : _notifier = ValueNotifier(initialProgress);

  void show(BuildContext context) {
    if (_entry != null) return;
    final overlay = Overlay.of(context, rootOverlay: true);
    _entry = OverlayEntry(
      builder: (context) => ValueListenableBuilder<PropertyEditorProgress>(
        valueListenable: _notifier,
        builder: (context, progress, _) =>
            PropertyEditorProgressOverlay(progress: progress),
      ),
    );
    overlay.insert(_entry!);
  }

  void update(PropertyEditorProgress progress) {
    _notifier.value = progress;
  }

  void hide() {
    _entry?.remove();
    _entry = null;
    _notifier.dispose();
  }
}
