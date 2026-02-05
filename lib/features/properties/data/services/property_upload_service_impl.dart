import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:image/image.dart' as img;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:real_state/core/handle_errors/error_mapper.dart';
import 'package:real_state/features/properties/domain/services/property_upload_service.dart';
import 'package:real_state/features/properties/models/property_editor_models.dart';

class PropertyUploadServiceImpl implements PropertyUploadService {
  static const String _pendingKey = 'pending_property_uploads_v1';
  static const int _maxBackoffMs = 30000;

  /// Uploads images and returns their URLs plus cover.
  /// Does not delete remote assets; caller can decide cleanup.
  @override
  Future<UploadResult> uploadImages(
    List<EditableImage> images,
    String propertyId, {
    void Function(double fraction)? onProgress,
  }) async {
    final storage = FirebaseStorage.instance;
    final urls = <String>[];
    final pending = await _loadPending();
    final total = images.length;
    var completed = 0;

    for (var i = 0; i < images.length; i++) {
      final imgItem = images[i];
      if (!imgItem.isLocal && imgItem.remoteUrl != null) {
        urls.add(imgItem.remoteUrl!);
        completed++;
        onProgress?.call(_progress(completed, total));
        continue;
      }
      final localPath = imgItem.file?.path;
      if (localPath != null && localPath.isNotEmpty) {
        final storagePath = _buildStoragePath(propertyId, i);
        _upsertPending(
          pending,
          _PendingUpload(
            propertyId: propertyId,
            index: i,
            localPath: localPath,
            storagePath: storagePath,
          ),
        );
        await _savePending(pending);
      }
      final rawBytes =
          imgItem.preview ?? await imgItem.file?.readAsBytes() ?? Uint8List(0);
      if (rawBytes.isEmpty) continue;
      final data = await _compress(rawBytes);
      final ref = storage
          .ref()
          .child(_buildStoragePath(propertyId, i));
      try {
        await ref.putData(data, SettableMetadata(contentType: 'image/jpeg'));
        final url = await ref.getDownloadURL();
        urls.add(url);
        _removePending(pending, propertyId, i);
        await _savePending(pending);
      } on FirebaseException catch (e, st) {
        throw mapExceptionToFailure(e, st);
      } catch (e, st) {
        throw mapExceptionToFailure(e, st);
      }
      completed++;
      onProgress?.call(_progress(completed, total));
    }

    final coverIndex = images.indexWhere((e) => e.isCover);
    final coverUrl = (coverIndex >= 0 && coverIndex < urls.length)
        ? urls[coverIndex]
        : (urls.isNotEmpty ? urls.first : null);
    return UploadResult(urls: urls, coverUrl: coverUrl);
  }

  /// Deletes remote images that were removed during edit.
  @override
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

  @override
  Future<void> resumePendingUploads({
    void Function(double fraction)? onProgress,
  }) async {
    final pending = await _loadPending();
    if (pending.isEmpty) return;
    final storage = FirebaseStorage.instance;
    var completed = 0;
    final total = pending.length;
    final now = DateTime.now().millisecondsSinceEpoch;
    for (final item in List<_PendingUpload>.from(pending)) {
      if (item.nextAttemptAtMs != null && now < item.nextAttemptAtMs!) {
        completed++;
        onProgress?.call(_progress(completed, total));
        continue;
      }
      try {
        final bytes = await _readLocalBytes(item.localPath);
        final data = await _compress(bytes);
        if (data.isEmpty) {
          _removePending(pending, item.propertyId, item.index);
          await _savePending(pending);
          completed++;
          onProgress?.call(_progress(completed, total));
          continue;
        }
        final ref = storage.ref().child(
          item.storagePath ??
              _buildStoragePath(item.propertyId, item.index),
        );
        await ref.putData(data, SettableMetadata(contentType: 'image/jpeg'));
        _removePending(pending, item.propertyId, item.index);
        await _savePending(pending);
      } catch (_) {
        final nextAttempt = item.attempts + 1;
        final backoffMs = _computeBackoffMs(nextAttempt);
        _updatePending(
          pending,
          item.copyWith(
            attempts: nextAttempt,
            nextAttemptAtMs: now + backoffMs,
          ),
        );
        await _savePending(pending);
      }
      completed++;
      onProgress?.call(_progress(completed, total));
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

  double _progress(int completed, int total) {
    if (total <= 0) return 0;
    return (completed / total).clamp(0.0, 1.0);
  }

  Future<Uint8List> _readLocalBytes(String path) async {
    try {
      return await File(path).readAsBytes();
    } catch (_) {
      return Uint8List(0);
    }
  }

  Future<List<_PendingUpload>> _loadPending() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_pendingKey);
    if (raw == null || raw.isEmpty) return [];
    final decoded = jsonDecode(raw);
    if (decoded is! List) return [];
    return decoded
        .whereType<Map>()
        .map((e) => _PendingUpload.fromMap(e.cast<String, dynamic>()))
        .toList();
  }

  Future<void> _savePending(List<_PendingUpload> items) async {
    final prefs = await SharedPreferences.getInstance();
    if (items.isEmpty) {
      await prefs.remove(_pendingKey);
      return;
    }
    final raw = jsonEncode(items.map((e) => e.toMap()).toList());
    await prefs.setString(_pendingKey, raw);
  }

  void _upsertPending(List<_PendingUpload> items, _PendingUpload item) {
    final index = items.indexWhere(
      (e) => e.propertyId == item.propertyId && e.index == item.index,
    );
    if (index == -1) {
      items.add(item);
    } else {
      items[index] = item;
    }
  }

  void _updatePending(List<_PendingUpload> items, _PendingUpload item) {
    final index = items.indexWhere(
      (e) => e.propertyId == item.propertyId && e.index == item.index,
    );
    if (index == -1) return;
    items[index] = item;
  }

  void _removePending(List<_PendingUpload> items, String propertyId, int index) {
    items.removeWhere(
      (e) => e.propertyId == propertyId && e.index == index,
    );
  }

  String _buildStoragePath(String propertyId, int index) {
    return 'properties/$propertyId/pending_$index.jpg';
  }

  int _computeBackoffMs(int attempt) {
    final clamped = attempt.clamp(1, 5);
    final delay = switch (clamped) {
      1 => 2000,
      2 => 5000,
      3 => 10000,
      4 => 20000,
      _ => _maxBackoffMs,
    };
    return delay;
  }
}

class _PendingUpload {
  final String propertyId;
  final int index;
  final String localPath;
  final String? storagePath;
  final int attempts;
  final int? nextAttemptAtMs;

  const _PendingUpload({
    required this.propertyId,
    required this.index,
    required this.localPath,
    this.storagePath,
    this.attempts = 0,
    this.nextAttemptAtMs,
  });

  factory _PendingUpload.fromMap(Map<String, dynamic> map) {
    return _PendingUpload(
      propertyId: map['propertyId'] as String? ?? '',
      index: (map['index'] as num?)?.toInt() ?? 0,
      localPath: map['localPath'] as String? ?? '',
      storagePath: map['storagePath'] as String?,
      attempts: (map['attempts'] as num?)?.toInt() ?? 0,
      nextAttemptAtMs: (map['nextAttemptAtMs'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toMap() => {
    'propertyId': propertyId,
    'index': index,
    'localPath': localPath,
    'storagePath': storagePath,
    'attempts': attempts,
    'nextAttemptAtMs': nextAttemptAtMs,
  };

  _PendingUpload copyWith({
    String? storagePath,
    int? attempts,
    int? nextAttemptAtMs,
  }) {
    return _PendingUpload(
      propertyId: propertyId,
      index: index,
      localPath: localPath,
      storagePath: storagePath ?? this.storagePath,
      attempts: attempts ?? this.attempts,
      nextAttemptAtMs: nextAttemptAtMs ?? this.nextAttemptAtMs,
    );
  }
}
