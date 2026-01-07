import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:image/image.dart' as img;
import 'package:real_state/core/handle_errors/error_mapper.dart';

import '../models/property_editor_models.dart';

class PropertyUploadService {
  /// Uploads images and returns their URLs plus cover.
  /// Does not delete remote assets; caller can decide cleanup.
  Future<UploadResult> uploadImages(
    List<EditableImage> images,
    String propertyId,
  ) async {
    final storage = FirebaseStorage.instance;
    final urls = <String>[];

    for (var i = 0; i < images.length; i++) {
      final imgItem = images[i];
      if (!imgItem.isLocal && imgItem.remoteUrl != null) {
        urls.add(imgItem.remoteUrl!);
        continue;
      }
      final rawBytes =
          imgItem.preview ?? await imgItem.file?.readAsBytes() ?? Uint8List(0);
      if (rawBytes.isEmpty) continue;
      final data = await _compress(rawBytes);
      final ref = storage.ref().child(
        'properties/$propertyId/${DateTime.now().millisecondsSinceEpoch}_$i.jpg',
      );
      try {
        await ref.putData(data, SettableMetadata(contentType: 'image/jpeg'));
        final url = await ref.getDownloadURL();
        urls.add(url);
      } on FirebaseException catch (e, st) {
        throw mapExceptionToFailure(e, st);
      } catch (e, st) {
        throw mapExceptionToFailure(e, st);
      }
    }

    final coverIndex = images.indexWhere((e) => e.isCover);
    final coverUrl = (coverIndex >= 0 && coverIndex < urls.length)
        ? urls[coverIndex]
        : (urls.isNotEmpty ? urls.first : null);
    return UploadResult(urls: urls, coverUrl: coverUrl);
  }

  /// Deletes remote images that were removed during edit.
  Future<void> deleteRemovedRemoteImages({
    required List<String> removedUrls,
  }) async {
    if (removedUrls.isEmpty) return;
    final storage = FirebaseStorage.instance;
    for (final url in removedUrls) {
      try {
        await storage.refFromURL(url).delete();
      } catch (_) {
        // Swallow errors to avoid impacting user flow; cleanup is best-effort.
      }
    }
  }

  Future<Uint8List> _compress(Uint8List bytes) async {
    final decoded = img.decodeImage(bytes);
    if (decoded == null) return bytes;
    final targetWidth = decoded.width > 1600 ? 1600 : decoded.width;
    final resized = img.copyResize(
      decoded,
      width: targetWidth,
      interpolation: img.Interpolation.linear,
    );
    final compressed = img.encodeJpg(resized, quality: 82);
    return Uint8List.fromList(compressed);
  }
}
