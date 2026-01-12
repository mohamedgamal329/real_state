import 'dart:io';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/services.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:image/image.dart' as img;
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:real_state/core/errors/localized_exception.dart';
import 'package:real_state/features/models/entities/property.dart';
import 'package:real_state/features/properties/domain/services/pdf_property_builder.dart';
import 'package:share_plus/share_plus.dart';

import '../models/property_share_progress.dart';

class PropertyShareService {
  final BaseCacheManager _cacheManager;
  final PdfPropertyBuilder _pdfBuilder;
  Uint8List? _logoBytes;
  pw.Font? _arabicFont;

  PropertyShareService({
    BaseCacheManager? cacheManager,
    PdfPropertyBuilder? pdfBuilder,
  })  : _cacheManager = cacheManager ?? DefaultCacheManager(),
        _pdfBuilder = pdfBuilder ?? PdfPropertyBuilder();

  Future<void> shareImagesOnly({
    required Property property,
    PropertyShareProgressCallback? onProgress,
  }) async {
    _reportProgress(onProgress, PropertyShareStage.preparingData);
    final urls = _collectImageUrls(property);
    if (urls.isEmpty) {
      throw const LocalizedException('no_images_to_share');
    }
    final files = <XFile>[];
    _reportProgress(onProgress, PropertyShareStage.generatingPdf);
    for (final url in urls) {
      final file = await _loadImageFile(url);
      if (file != null) {
        files.add(XFile(file.path));
      }
    }
    if (files.isEmpty) {
      throw const LocalizedException('unable_load_images');
    }
    _reportProgress(onProgress, PropertyShareStage.uploadingSharing);
    // ignore: deprecated_member_use
    await Share.shareXFiles(files, text: property.title ?? 'property'.tr());
    _reportProgress(onProgress, PropertyShareStage.finalizing);
  }

  Future<void> sharePdf({
    required Property property,
    String? localeCode,
    bool locationVisible = true,
    bool includeImages = true,
    PropertyShareProgressCallback? onProgress,
  }) async {
    _reportProgress(onProgress, PropertyShareStage.preparingData);
    final pdfBytes = await buildPdfBytes(
      property: property,
      localeCode: localeCode,
      includeImages: includeImages,
    );
    _reportProgress(onProgress, PropertyShareStage.generatingPdf);
    await Printing.sharePdf(
      bytes: pdfBytes,
      filename: '${property.title ?? 'property'.tr()}.pdf',
    );
    _reportProgress(onProgress, PropertyShareStage.uploadingSharing);
    _reportProgress(onProgress, PropertyShareStage.finalizing);
  }

  Future<Uint8List> buildPdfBytes({
    required Property property,
    String? localeCode,
    bool includeImages = true,
    PropertyShareProgressCallback? onProgress,
  }) async {
    final titleText =
        property.title?.isNotEmpty == true ? property.title! : 'property'.tr();
    final descriptionText = property.description ?? '';
    _reportProgress(onProgress, PropertyShareStage.preparingData);
    final images = includeImages
        ? await _loadImagesOrThrow(_collectImageUrls(property))
        : const <PdfImageData>[];
    final logoBytes = await _loadLogoBytes();
    final arabicFont = await _loadArabicFont();
    final pdfBytes = await _pdfBuilder.build(
      property: property,
      titleText: titleText,
      descriptionText: descriptionText,
      localeCode: localeCode,
      includeImages: includeImages,
      images: images,
      logoBytes: logoBytes,
      arabicFont: arabicFont,
    );
    _reportProgress(onProgress, PropertyShareStage.generatingPdf);
    return pdfBytes;
  }

  List<String> _collectImageUrls(Property p) {
    final urls = <String>[];
    if (p.coverImageUrl != null) urls.add(p.coverImageUrl!);
    for (final url in p.imageUrls) {
      if (!urls.contains(url)) urls.add(url);
    }
    return urls;
  }

  Future<File?> _loadImageFile(String url) async {
    try {
      final cached = await _cacheManager.getSingleFile(url);
      if (await cached.exists()) return cached;
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<List<PdfImageData>> _loadImagesOrThrow(List<String> urls) async {
    final images = <PdfImageData>[];
    for (final url in urls) {
      try {
        final file = await _loadImageFile(url);
        if (file == null) throw const LocalizedException('unable_load_images');
        final bytes = await file.readAsBytes();
        final decoded = img.decodeImage(bytes);
        if (decoded == null) throw const LocalizedException('unable_load_images');
        images.add(
          PdfImageData(
            bytes: bytes,
            width: decoded.width.toDouble(),
            height: decoded.height.toDouble(),
          ),
        );
      } catch (_) {
        throw const LocalizedException('unable_load_images');
      }
    }
    return images;
  }

  Future<Uint8List?> _loadLogoBytes() async {
    if (_logoBytes != null) return _logoBytes;
    try {
      final bytes = await rootBundle.load('assets/images/logo.jpeg');
      _logoBytes = bytes.buffer.asUint8List();
      return _logoBytes;
    } catch (_) {
      return null;
    }
  }

  Future<pw.Font?> _loadArabicFont() async {
    if (_arabicFont != null) return _arabicFont;
    try {
      final data =
          await rootBundle.load('assets/fonts/noto_sans_arabic/NotoSansArabic-Regular.ttf');
      _arabicFont = pw.Font.ttf(data);
      return _arabicFont;
    } catch (_) {
      return null;
    }
  }

  void _reportProgress(
    PropertyShareProgressCallback? onProgress,
    PropertyShareStage stage,
  ) {
    if (onProgress == null) return;
    onProgress(PropertyShareProgress(
      stage: stage,
      fraction: stage.defaultFraction(),
    ));
  }
}
