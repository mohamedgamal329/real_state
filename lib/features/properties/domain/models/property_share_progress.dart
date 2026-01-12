class PropertyShareProgress {
  final PropertyShareStage stage;
  final double fraction;
  final bool isBulk;
  final int? currentIndex;
  final int? totalProperties;

  const PropertyShareProgress({
    required this.stage,
    required this.fraction,
    this.isBulk = false,
    this.currentIndex,
    this.totalProperties,
  });

  PropertyShareProgress clamp() {
    final clamped = fraction.clamp(0.0, 1.0).toDouble();
    return copyWith(fraction: clamped);
  }

  PropertyShareProgress copyWith({
    PropertyShareStage? stage,
    double? fraction,
    bool? isBulk,
    int? currentIndex,
    int? totalProperties,
  }) {
    return PropertyShareProgress(
      stage: stage ?? this.stage,
      fraction: fraction ?? this.fraction,
      isBulk: isBulk ?? this.isBulk,
      currentIndex: currentIndex ?? this.currentIndex,
      totalProperties: totalProperties ?? this.totalProperties,
    );
  }
}

enum PropertyShareStage {
  preparingData,
  generatingPdf,
  uploadingSharing,
  finalizing,
}

extension PropertyShareStageX on PropertyShareStage {
  String translationKey() {
    switch (this) {
      case PropertyShareStage.preparingData:
        return 'share_progress_preparing_data';
      case PropertyShareStage.generatingPdf:
        return 'share_progress_generating_pdf';
      case PropertyShareStage.uploadingSharing:
        return 'share_progress_uploading';
      case PropertyShareStage.finalizing:
        return 'share_progress_finalizing';
    }
  }

  double defaultFraction() {
    switch (this) {
      case PropertyShareStage.preparingData:
        return 0.1;
      case PropertyShareStage.generatingPdf:
        return 0.4;
      case PropertyShareStage.uploadingSharing:
        return 0.7;
      case PropertyShareStage.finalizing:
        return 1.0;
    }
  }
}

typedef PropertyShareProgressCallback = void Function(PropertyShareProgress progress);
