import 'dart:async';
import 'dart:io';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:real_state/core/errors/localized_exception.dart';
import 'package:real_state/features/models/entities/property.dart';
import 'package:real_state/features/properties/domain/services/pdf_property_builder.dart';
import 'package:share_plus/share_plus.dart';

import '../models/property_share_progress.dart';

class PropertyShareService {
  static const int _maxShareImages = 20;
  static const int _maxImageLongEdge = 1600;
  static const int _jpegQuality = 80;
  static const Duration _imageDownloadTimeout = Duration(seconds: 20);
  final BaseCacheManager _cacheManager;
  final PdfPropertyBuilder _pdfBuilder;
  Uint8List? _logoBytes;
  pw.Font? _arabicFont;
  pw.Font? _arabicFontBold;
  final Map<String, PdfImageData> _imageCache = {};

  PropertyShareService({
    BaseCacheManager? cacheManager,
    PdfPropertyBuilder? pdfBuilder,
  }) : _cacheManager = cacheManager ?? DefaultCacheManager(),
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
    for (var i = 0; i < urls.length; i++) {
      _reportProgressFraction(
        onProgress,
        PropertyShareStage.generatingPdf,
        (i / urls.length).clamp(0.0, 1.0),
      );
      final url = urls[i];
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
    final stopwatch = Stopwatch()..start();
    _reportProgress(onProgress, PropertyShareStage.preparingData);
    if (kDebugMode) {
      debugPrint('share_pdf_start ts=${DateTime.now().toIso8601String()}');
    }
    final pdfBytes = await buildPdfBytes(
      property: property,
      localeCode: localeCode,
      includeImages: includeImages,
      onProgress: onProgress,
    );
    _reportProgress(onProgress, PropertyShareStage.generatingPdf);
    if (kDebugMode) {
      debugPrint(
        'share_pdf_built bytes=${pdfBytes.length} ms=${stopwatch.elapsedMilliseconds}',
      );
    }

    // FIX F: Write to real temp file so Gmail sees correct filename (not UUID)
    final title = property.title?.trim();
    final baseTitle = title?.isNotEmpty == true ? title! : 'property'.tr();
    // Sanitization logic matching multi_pdf_share.dart
    final sanitizedBase = baseTitle
        .replaceAll(RegExp(r'[^\w\s\-]'), '_')
        .replaceAll(RegExp(r'[\s_]+'), ' ')
        .trim();
    final fileName = '$sanitizedBase.pdf';

    final tempDir = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final shareDir = Directory('${tempDir.path}/share_pdf_$timestamp');
    if (!await shareDir.exists()) {
      await shareDir.create(recursive: true);
    }
    final tempFile = File('${shareDir.path}/$fileName');
    await tempFile.writeAsBytes(pdfBytes);
    // Flush to ensure OS sees it.
    await tempFile.parent.create(recursive: true);

    // EXTREMELY CRITICAL: Use XFile with the explicit name
    final file = XFile(tempFile.path, name: fileName);

    if (kDebugMode) {
      debugPrint(
        'share_single_pdf_path=${tempFile.path} size=${pdfBytes.length}',
      );
      debugPrint('share_dir=${shareDir.path}');
    }

    _reportProgress(onProgress, PropertyShareStage.uploadingSharing);
    // ignore: deprecated_member_use
    if (kDebugMode) {
      debugPrint('share_pdf_share_invoke ts=${DateTime.now().toIso8601String()}');
    }
    await Share.shareXFiles([file], text: 'share_details_pdf'.tr());
    if (kDebugMode) {
      debugPrint('share_pdf_share_done ms=${stopwatch.elapsedMilliseconds}');
    }
    _reportProgress(onProgress, PropertyShareStage.finalizing);
  }

  Future<Uint8List> buildPdfBytes({
    required Property property,
    String? localeCode,
    bool includeImages = true,
    PropertyShareProgressCallback? onProgress,
  }) async {
    final stopwatch = Stopwatch()..start();
    final titleText = property.title?.isNotEmpty == true
        ? property.title!
        : 'property'.tr();
    final descriptionText = property.description ?? '';
    _reportProgress(onProgress, PropertyShareStage.preparingData);
    if (_imageCache.length > _maxShareImages) {
      _imageCache.clear();
    }
    final images = includeImages
        ? await _loadImagesOrThrow(
            _collectImageUrls(property),
            onProgress: onProgress,
          )
        : const <PdfImageData>[];
    if (kDebugMode) {
      debugPrint(
        'share_pdf: loaded ${images.length} images in ${stopwatch.elapsedMilliseconds}ms',
      );
    }
    final logoBytes = await _loadLogoBytes();
    final arabicFont = await _loadArabicFont();
    final arabicFontBold = await _loadArabicFontBold();
    if (kDebugMode) {
      debugPrint(
        'share_pdf: logo/font ready in ${stopwatch.elapsedMilliseconds}ms',
      );
    }
    final pdfBytes = await _pdfBuilder.build(
      property: property,
      titleText: titleText,
      descriptionText: descriptionText,
      localeCode: localeCode,
      includeImages: includeImages,
      images: images,
      logoBytes: logoBytes,
      arabicFont: arabicFont,
      arabicFontBold: arabicFontBold ?? arabicFont,
    );
    if (kDebugMode) {
      debugPrint('share_pdf: pdf built in ${stopwatch.elapsedMilliseconds}ms');
    }
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
      final cached = await _cacheManager
          .getSingleFile(url)
          .timeout(_imageDownloadTimeout);
      if (await cached.exists()) return cached;
      return null;
    } on TimeoutException {
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<List<PdfImageData>> _loadImagesOrThrow(
    List<String> urls, {
    PropertyShareProgressCallback? onProgress,
  }) async {
    final images = <PdfImageData>[];
    final effectiveUrls =
        urls.length > _maxShareImages ? urls.take(_maxShareImages).toList() : urls;
    if (kDebugMode && effectiveUrls.length != urls.length) {
      debugPrint(
        'share_pdf_images_capped total=${urls.length} used=${effectiveUrls.length}',
      );
    }
    for (var i = 0; i < effectiveUrls.length; i++) {
      try {
        _reportProgressFraction(
          onProgress,
          PropertyShareStage.preparingData,
          (i / effectiveUrls.length).clamp(0.0, 1.0),
        );
        final url = effectiveUrls[i];
        final cachedImage = _imageCache[url];
        if (cachedImage != null) {
          images.add(cachedImage);
          continue;
        }
        final file = await _loadImageFile(url);
        if (file == null) {
          if (kDebugMode) {
            debugPrint('share_pdf_image_skip url=$url reason=load_failed');
          }
          continue;
        }
        final bytes = await file.readAsBytes();
        if (kDebugMode) {
          debugPrint('share_pdf_image_bytes url=$url size=${bytes.length}');
        }
        final decoded = await compute(
          _resizeAndCompressImage,
          _ResizeRequest(
            bytes: bytes,
            maxLongEdge: _maxImageLongEdge,
            jpegQuality: _jpegQuality,
          ),
        );
        if (decoded == null) {
          if (kDebugMode) {
            debugPrint('share_pdf_image_skip url=$url reason=decode_failed');
          }
          continue;
        }
        final data = PdfImageData(
          bytes: decoded.bytes,
          width: decoded.width.toDouble(),
          height: decoded.height.toDouble(),
        );
        _imageCache[url] = data;
        images.add(data);
        if (kDebugMode) {
          debugPrint(
            'share_pdf_image_processed url=$url size=${data.bytes.length} dim=${data.width}x${data.height}',
          );
        }
      } catch (_) {
        if (kDebugMode) {
          debugPrint('share_pdf_image_skip url=${effectiveUrls[i]} reason=exception');
        }
        continue;
      }
    }
    if (images.isEmpty) {
      throw const LocalizedException('unable_load_images');
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
      final data = await rootBundle.load(
        'assets/fonts/noto_sans_arabic/NotoSansArabic-Regular.ttf',
      );
      _arabicFont = pw.Font.ttf(data);
      return _arabicFont;
    } catch (_) {
      return null;
    }
  }

  Future<pw.Font?> _loadArabicFontBold() async {
    if (_arabicFontBold != null) return _arabicFontBold;
    try {
      final data = await rootBundle.load(
        'assets/fonts/noto_sans_arabic/NotoSansArabic-Regular.ttf',
      );
      _arabicFontBold = pw.Font.ttf(data);
      return _arabicFontBold;
    } catch (_) {
      return null;
    }
  }

  void _reportProgress(
    PropertyShareProgressCallback? onProgress,
    PropertyShareStage stage,
  ) {
    if (onProgress == null) return;
    onProgress(
      PropertyShareProgress(stage: stage, fraction: stage.defaultFraction()),
    );
  }

  void _reportProgressFraction(
    PropertyShareProgressCallback? onProgress,
    PropertyShareStage stage,
    double fraction,
  ) {
    if (onProgress == null) return;
    onProgress(PropertyShareProgress(stage: stage, fraction: fraction));
  }
}

class _ResizeRequest {
  final Uint8List bytes;
  final int maxLongEdge;
  final int jpegQuality;

  const _ResizeRequest({
    required this.bytes,
    required this.maxLongEdge,
    required this.jpegQuality,
  });
}

class _ResizeResult {
  final Uint8List bytes;
  final int width;
  final int height;

  const _ResizeResult({
    required this.bytes,
    required this.width,
    required this.height,
  });
}

_ResizeResult? _resizeAndCompressImage(_ResizeRequest request) {
  final decoded = img.decodeImage(request.bytes);
  if (decoded == null) return null;
  final width = decoded.width;
  final height = decoded.height;
  final longEdge = width > height ? width : height;
  final scale =
      longEdge > request.maxLongEdge ? request.maxLongEdge / longEdge : 1.0;
  final resized = scale < 1.0
      ? img.copyResize(
          decoded,
          width: (width * scale).round(),
          height: (height * scale).round(),
        )
      : decoded;
  final jpeg = img.encodeJpg(resized, quality: request.jpegQuality);
  return _ResizeResult(
    bytes: Uint8List.fromList(jpeg),
    width: resized.width,
    height: resized.height,
  );
}
