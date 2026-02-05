import 'package:real_state/features/properties/domain/services/property_upload_service.dart';
import 'package:real_state/features/properties/models/property_editor_models.dart';

class UploadPropertyImagesUseCase {
  UploadPropertyImagesUseCase(this._uploadService);

  final PropertyUploadService _uploadService;

  Future<UploadResult> call(
    List<EditableImage> images,
    String propertyId, {
    void Function(double fraction)? onProgress,
  }) {
    return _uploadService.uploadImages(
      images,
      propertyId,
      onProgress: onProgress,
    );
  }
}
