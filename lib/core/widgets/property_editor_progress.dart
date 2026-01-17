/// Progress model for property create/edit operations.
class PropertyEditorProgress {
  final PropertyEditorStage stage;
  final double fraction;

  const PropertyEditorProgress({required this.stage, required this.fraction});

  PropertyEditorProgress clamp() {
    final clamped = fraction.clamp(0.0, 1.0).toDouble();
    return PropertyEditorProgress(stage: stage, fraction: clamped);
  }
}

enum PropertyEditorStage { uploadingImages, savingDetails }

extension PropertyEditorStageX on PropertyEditorStage {
  String translationKey() {
    switch (this) {
      case PropertyEditorStage.uploadingImages:
        return 'editor_progress_uploading_images';
      case PropertyEditorStage.savingDetails:
        return 'editor_progress_saving_details';
    }
  }

  double defaultFraction() {
    switch (this) {
      case PropertyEditorStage.uploadingImages:
        return 0.4;
      case PropertyEditorStage.savingDetails:
        return 0.9;
    }
  }
}
