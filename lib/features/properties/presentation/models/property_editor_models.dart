import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';

class EditableImage {
  final String? remoteUrl;
  final XFile? file;
  final Uint8List? preview;
  bool isCover;

  EditableImage({
    this.remoteUrl,
    this.file,
    this.preview,
    this.isCover = false,
  });

  bool get isLocal => remoteUrl == null;
}

class UploadResult {
  final List<String> urls;
  final String? coverUrl;

  UploadResult({required this.urls, required this.coverUrl});
}
