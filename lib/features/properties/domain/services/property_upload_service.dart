import 'package:real_state/features/properties/models/property_editor_models.dart';

/// Abstraction for uploading property images so domain logic stays decoupled from Firebase Storage.
abstract class PropertyUploadService {
  Future<UploadResult> uploadImages(
    List<EditableImage> images,
    String propertyId, {
    void Function(double fraction)? onProgress,
  });

  Future<void> deleteRemovedRemoteImages({required List<String> removedUrls});

  Future<void> resumePendingUploads({void Function(double fraction)? onProgress});
}
