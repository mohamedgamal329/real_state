import 'package:flutter/foundation.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:pdf/pdf.dart' as pdf;
import 'package:pdf/widgets.dart' as pw;
import 'package:real_state/core/utils/price_formatter.dart';
import 'package:real_state/features/models/entities/property.dart';

class PdfImageData {
  final Uint8List bytes;
  final double width;
  final double height;

  const PdfImageData({
    required this.bytes,
    required this.width,
    required this.height,
  });
}

class PdfPropertyBuilder {
  static final pdf.PdfColor _pageBgColor = pdf.PdfColor.fromInt(0xFF212121);
  static const double _detailsMargin = 40.0;
  static const double _titleFontSize = 36.0;
  static const double _bodyFontSize = 21.0;
  static const double _metaFontSize = 20.0;
  static const double _bodyLineHeight = 1.6;

  Future<Uint8List> build({
    required Property property,
    required String titleText,
    required String descriptionText,
    String? localeCode,
    bool includeImages = true,
    List<PdfImageData> images = const [],
    Uint8List? logoBytes,
    pw.Font? arabicFont,
    pw.Font? arabicFontBold,
  }) async {
    final theme = arabicFont != null
        ? pw.ThemeData.withFont(
            base: arabicFont,
            bold: arabicFontBold ?? arabicFont,
          )
        : null;
    final doc = pw.Document(theme: theme);
    final sanitizedImages = includeImages ? images : const <PdfImageData>[];

    if (kDebugMode) {
      debugPrint('pdf_details_render_path=PdfPropertyBuilder.build');
    }

    _addImagePages(doc, sanitizedImages);

    _addDetailsPagesNative(
      doc: doc,
      property: property,
      title: titleText,
      description: descriptionText,
      localeCode: localeCode,
    );

    if (kDebugMode) {
      debugPrint('pdf_details_page_added=true');
    }

    // RESTORE LOGO PAGE (User Request)
    if (logoBytes != null) {
      _addLogoPage(doc, logoBytes);
    }

    return doc.save();
  }

  void _addDetailsPagesNative({
    required pw.Document doc,
    required Property property,
    required String title,
    required String description,
    String? localeCode,
  }) {
    final pageFormat = pdf.PdfPageFormat.a3;
    final contentWidth = pageFormat.width - (_detailsMargin * 2);
    final metaLines = _buildMetaLines(property, localeCode: localeCode);
    final effectiveDescription = description.trim().isEmpty
        ? 'No description'
        : description.trim();
    final isShortDescription = _estimateLineCount(
          effectiveDescription,
          contentWidth,
          _bodyFontSize,
        ) <=
        2;
    final showDetailsHeader = metaLines.isEmpty && isShortDescription;

    doc.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          pageFormat: pageFormat,
          margin: const pw.EdgeInsets.all(_detailsMargin),
          buildBackground: (_) => pw.Container(color: _pageBgColor),
        ),
        build: (_) => [
          pw.Directionality(
            textDirection: pw.TextDirection.rtl,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                pw.Text(
                  title,
                  textAlign: pw.TextAlign.right,
                  style: pw.TextStyle(
                    fontSize: _titleFontSize,
                    fontWeight: pw.FontWeight.bold,
                    color: pdf.PdfColors.white,
                    height: 1.2,
                  ),
                ),
                pw.SizedBox(height: 18),
                if (metaLines.isNotEmpty) ...[
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                    children: [
                      for (final line in metaLines)
                        pw.Padding(
                          padding: const pw.EdgeInsets.only(bottom: 6),
                          child: pw.Text(
                            line,
                            textAlign: pw.TextAlign.right,
                            style: pw.TextStyle(
                              fontSize: _metaFontSize,
                              color: pdf.PdfColors.grey200,
                              height: 1.4,
                            ),
                          ),
                        ),
                    ],
                  ),
                  pw.SizedBox(height: 16),
                ],
                pw.Container(
                  height: 1.25,
                  color: pdf.PdfColors.grey400,
                ),
                pw.SizedBox(height: 22),
                if (showDetailsHeader) ...[
                  pw.Text(
                    'details'.tr(),
                    textAlign: pw.TextAlign.right,
                    style: pw.TextStyle(
                      fontSize: _metaFontSize,
                      fontWeight: pw.FontWeight.bold,
                      color: pdf.PdfColors.grey200,
                    ),
                  ),
                  pw.SizedBox(height: 12),
                ],
                pw.Text(
                  effectiveDescription,
                  textAlign: pw.TextAlign.right,
                  softWrap: true,
                  style: pw.TextStyle(
                    fontSize: _bodyFontSize,
                    color: pdf.PdfColors.white,
                    height: _bodyLineHeight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<String> _buildMetaLines(
    Property property, {
    String? localeCode,
  }) {
    final lines = <String>[];
    if (property.price != null) {
      final formatted = PriceFormatter.format(
        property.price!,
        currency: 'AED',
        locale: localeCode,
      ).trim();
      lines.add('price_with_value'.tr(args: [formatted]));
    }
    if (property.rooms != null) {
      lines.add('rooms_with_value'.tr(args: ['${property.rooms}']));
    }
    if (property.kitchens != null) {
      lines.add('kitchens_with_value'.tr(args: ['${property.kitchens}']));
    }
    if (property.floors != null) {
      lines.add('floors_with_value'.tr(args: ['${property.floors}']));
    }
    if (property.hasPool) {
      lines.add('has_pool_with_value'.tr(args: ['${'yes'.tr()}']));
    }
    if (property.creatorName != null && property.creatorName!.trim().isNotEmpty) {
      final name = property.creatorName!.trim();
      lines.add('${'added_by'.tr()}: $name');
    }
    return lines;
  }

  int _estimateLineCount(
    String text,
    double contentWidth,
    double fontSize,
  ) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return 0;
    final approxCharsPerLine = (contentWidth / (fontSize * 0.6)).floor().clamp(
          20,
          120,
        );
    final newlineCount = '\n'.allMatches(trimmed).length;
    final normalized = trimmed.replaceAll('\n', ' ');
    final estimated = (normalized.length / approxCharsPerLine).ceil();
    return (estimated + newlineCount).clamp(1, 999);
  }

  void _addImagePages(pw.Document doc, List<PdfImageData> images) {
    if (images.isEmpty) return;
    for (final data in images) {
      final image = pw.MemoryImage(data.bytes);
      doc.addPage(
        pw.Page(
          pageFormat: pdf.PdfPageFormat(data.width, data.height),
          margin: pw.EdgeInsets.zero,
          build: (_) => pw.Container(
            color: pdf.PdfColors.grey800,
            child: pw.Center(
              child: pw.Image(
                image,
                width: data.width,
                height: data.height,
                fit: pw.BoxFit.contain,
              ),
            ),
          ),
        ),
      );
    }
  }

  void _addLogoPage(pw.Document doc, Uint8List logoBytes) {
    final image = pw.MemoryImage(logoBytes);
    final pageFormat = pdf.PdfPageFormat.a4;
    if (kDebugMode) {
      debugPrint(
        'pdf_logo_page_format=${pageFormat.width.toStringAsFixed(1)}x${pageFormat.height.toStringAsFixed(1)} '
        'margin=0 bg=0xFF212121',
      );
    }
    doc.addPage(
      pw.Page(
        pageTheme: pw.PageTheme(
          pageFormat: pageFormat,
          margin: pw.EdgeInsets.zero,
          buildBackground: (_) => pw.Container(color: _pageBgColor),
        ),
        build: (_) => pw.Stack(
          children: [
            pw.Positioned.fill(
              child: pw.Container(color: _pageBgColor),
            ),
            pw.Positioned.fill(
              child: pw.Container(
                alignment: pw.Alignment.center,
                child: pw.Container(
                  width: pageFormat.width * 0.85,
                  height: pageFormat.height * 0.45,
                  padding: const pw.EdgeInsets.all(24),
                  decoration: pw.BoxDecoration(
                    color: pdf.PdfColors.white,
                    borderRadius: pw.BorderRadius.circular(20),
                    border: pw.Border.all(
                      color: pdf.PdfColors.grey300,
                      width: 1.5,
                    ),
                  ),
                  child: pw.Center(
                    child: pw.Image(
                      image,
                      fit: pw.BoxFit.contain,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
