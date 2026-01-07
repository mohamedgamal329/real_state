import 'dart:async';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';

import '../../../../core/constants/app_collections.dart';
import '../../../../core/errors/localized_exception.dart';
import '../../../models/dtos/location_area_dto.dart';
import '../../../models/entities/location_area.dart';

class LocationRepository {
  final FirebaseFirestore _firestore;
  final String _collection;

  LocationRepository(this._firestore, {String? collection})
    : _collection = collection ?? AppCollections.locationAreas.path;

  Future<List<LocationArea>> fetchAll() async {
    final snap = await _firestore.collection(_collection).get();
    return snap.docs.map(LocationAreaDto.fromDoc).toList();
  }

  Future<String> create({
    required String nameAr,
    required String nameEn,
    required XFile imageFile,
  }) async {
    if (nameAr.trim().isEmpty || nameEn.trim().isEmpty) {
      throw const LocalizedException('name_required');
    }
    final doc = _firestore.collection(_collection).doc();
    final imageUrl = await _uploadImage(imageFile, doc.id);
    final area = LocationArea(
      id: doc.id,
      nameAr: nameAr,
      nameEn: nameEn,
      imageUrl: imageUrl,
      isActive: true,
      createdAt: DateTime.now(),
    );
    await doc.set(LocationAreaDto.toMap(area));
    return doc.id;
  }

  Future<void> update({
    required String id,
    required String nameAr,
    required String nameEn,
    XFile? imageFile,
    String? previousImageUrl,
  }) async {
    if (nameAr.trim().isEmpty || nameEn.trim().isEmpty) {
      throw const LocalizedException('name_required');
    }
    String? imageUrl = previousImageUrl;
    if (imageFile != null) {
      imageUrl = await _uploadImage(imageFile, id);
      if (previousImageUrl != null && previousImageUrl.isNotEmpty) {
        unawaited(_deleteImage(previousImageUrl));
      }
    }
    if (imageUrl == null || imageUrl.isEmpty) {
      throw const LocalizedException('location_image_required');
    }
    await _firestore.collection(_collection).doc(id).update({
      'name': nameEn,
      'name_ar': nameAr,
      'name_en': nameEn,
      'imageUrl': imageUrl,
    });
  }

  Future<bool> canDelete(String id) async {
    // Prevent deletion if any property uses this locationAreaId
    final snap = await _firestore
        .collection(AppCollections.properties.path)
        .where('locationAreaId', isEqualTo: id)
        .limit(1)
        .get();
    return snap.docs.isEmpty;
  }

  Future<void> delete(String id) async {
    await _firestore.collection(_collection).doc(id).delete();
  }

  Future<String> _uploadImage(XFile imageFile, String areaId) async {
    final bytes = await imageFile.readAsBytes();
    final compressed = await _compress(bytes);
    final ref = FirebaseStorage.instance.ref().child(
      'location_areas/$areaId-${DateTime.now().millisecondsSinceEpoch}.jpg',
    );
    await ref.putData(compressed, SettableMetadata(contentType: 'image/jpeg'));
    return ref.getDownloadURL();
  }

  Future<void> _deleteImage(String url) async {
    try {
      await FirebaseStorage.instance.refFromURL(url).delete();
    } catch (_) {
      // Best-effort cleanup; ignore failures.
    }
  }

  Future<Uint8List> _compress(Uint8List bytes) async {
    final decoded = img.decodeImage(bytes);
    if (decoded == null) return bytes;
    final targetWidth = decoded.width > 1500 ? 1500 : decoded.width;
    final resized = img.copyResize(
      decoded,
      width: targetWidth,
      interpolation: img.Interpolation.linear,
    );
    final compressed = img.encodeJpg(resized, quality: 82);
    return Uint8List.fromList(compressed);
  }
}
