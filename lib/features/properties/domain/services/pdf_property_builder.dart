import 'dart:typed_data';

import 'package:pdf/pdf.dart' as pdf;
import 'package:pdf/widgets.dart' as pw;
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
  Future<Uint8List> build({
    required Property property,
    required String titleText,
    required String descriptionText,
    String? localeCode,
    bool includeImages = true,
    List<PdfImageData> images = const [],
    Uint8List? logoBytes,
    pw.Font? arabicFont,
  }) async {
    final doc = pw.Document();
    final sanitizedImages = includeImages ? images : const <PdfImageData>[];

    _addImagePages(doc, sanitizedImages);
    _addDetailsPage(
      doc: doc,
      titleText: titleText,
      descriptionText: descriptionText,
      logoBytes: logoBytes,
      localeCode: localeCode,
      arabicFont: arabicFont,
    );
    _addLogoPage(
      doc: doc,
      logoBytes: logoBytes,
      titleText: titleText,
      descriptionText: descriptionText,
      localeCode: localeCode,
      arabicFont: arabicFont,
    );

    return doc.save();
  }

  void _addLogoPage({
    required pw.Document doc,
    required Uint8List? logoBytes,
    required String titleText,
    required String descriptionText,
    required String? localeCode,
    required pw.Font? arabicFont,
  }) {
    if (logoBytes == null) return;
    doc.addPage(
      pw.Page(
        pageTheme: pw.PageTheme(
          pageFormat: pdf.PdfPageFormat.a4,
          margin: pw.EdgeInsets.zero,
          buildBackground: (_) => pw.Container(color: pdf.PdfColors.grey900),
        ),
        build: (_) => _buildInfoPage(
          titleText: titleText,
          descriptionText: descriptionText,
          localeCode: localeCode,
          arabicFont: arabicFont,
          logoBytes: logoBytes,
        ),
      ),
    );
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
            color: pdf.PdfColors.grey900,
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

  void _addDetailsPage({
    required pw.Document doc,
    required String titleText,
    required String descriptionText,
    required Uint8List? logoBytes,
    required String? localeCode,
    required pw.Font? arabicFont,
  }) {
    doc.addPage(
      pw.Page(
        pageTheme: pw.PageTheme(
          pageFormat: pdf.PdfPageFormat.a4,
          margin: pw.EdgeInsets.zero,
          buildBackground: (_) => pw.Container(color: pdf.PdfColors.grey900),
        ),
        build: (_) => _buildInfoPage(
          titleText: titleText,
          descriptionText: descriptionText,
          localeCode: localeCode,
          arabicFont: arabicFont,
          logoBytes: logoBytes,
        ),
      ),
    );
  }

  pw.Widget _buildInfoPage({
    required String titleText,
    required String descriptionText,
    required String? localeCode,
    required pw.Font? arabicFont,
    required Uint8List? logoBytes,
  }) {
    const horizontalPadding = 44.0;
    const topPadding = 56.0;
    const bottomPadding = 44.0;
    const logoHeight = 72.0;
    const logoSpacing = 20.0;
    const titleSpacing = 12.0;
    final textColor = pdf.PdfColors.grey100;
    final accent = pdf.PdfColors.amber200;
    final arabicFontFallback = arabicFont != null ? [arabicFont] : null;
    final titleStyle = pw.TextStyle(
      fontSize: 30,
      fontWeight: pw.FontWeight.bold,
      color: accent,
      letterSpacing: 0.15,
      fontFallback: arabicFontFallback ?? const [],
    );
    final bodyStyle = pw.TextStyle(
      fontSize: 16,
      lineSpacing: 1.5,
      color: textColor,
      fontFallback: arabicFontFallback ?? const [],
    );
    final isArabicLocale = localeCode?.toLowerCase().startsWith('ar') ?? false;
    final description = descriptionText.trim();
    final layoutRtl =
        isArabicLocale || _containsArabic(titleText) || _containsArabic(description);
    final crossAxisAlignment =
        layoutRtl ? pw.CrossAxisAlignment.end : pw.CrossAxisAlignment.start;
    final logoAlignment =
        layoutRtl ? pw.Alignment.topRight : pw.Alignment.topLeft;

    pw.Widget localizedText(
      String text, {
      pw.TextStyle? style,
      bool underline = false,
      pdf.PdfColor? color,
    }) {
      final resolvedStyle = style ?? bodyStyle;
      final hasArabicCharacters = _containsArabic(text);
      final needsArabicFont = isArabicLocale || hasArabicCharacters;
      final effectiveStyle = resolvedStyle.copyWith(
        font: needsArabicFont && arabicFont != null ? arabicFont : resolvedStyle.font,
        fontFallback: arabicFontFallback ?? resolvedStyle.fontFallback,
        decoration: underline ? pw.TextDecoration.underline : resolvedStyle.decoration,
        color: color ?? resolvedStyle.color,
      );
      final textAlign =
          needsArabicFont ? pw.TextAlign.right : pw.TextAlign.left;

      return pw.Directionality(
        textDirection: needsArabicFont ? pw.TextDirection.rtl : pw.TextDirection.ltr,
        child: pw.Text(text, style: effectiveStyle, textAlign: textAlign),
      );
    }

    return pw.Container(
      width: double.infinity,
      height: double.infinity,
      padding: const pw.EdgeInsets.fromLTRB(
        horizontalPadding,
        topPadding,
        horizontalPadding,
        bottomPadding,
      ),
      child: pw.Column(
        mainAxisSize: pw.MainAxisSize.max,
        mainAxisAlignment: pw.MainAxisAlignment.start,
        crossAxisAlignment: crossAxisAlignment,
        children: [
          if (logoBytes != null)
            pw.Align(
              alignment: logoAlignment,
              child: pw.Image(
                pw.MemoryImage(logoBytes),
                height: logoHeight,
                fit: pw.BoxFit.contain,
              ),
            ),
          if (logoBytes != null) pw.SizedBox(height: logoSpacing),
          localizedText(
            titleText.isNotEmpty ? titleText : 'property',
            style: titleStyle,
          ),
          if (description.isNotEmpty) ...[
            pw.SizedBox(height: titleSpacing),
            localizedText(description, style: bodyStyle),
          ],
        ],
      ),
    );
  }

  bool _containsArabic(String text) {
    for (final codeUnit in text.runes) {
      if ((codeUnit >= 0x0600 && codeUnit <= 0x06FF) ||
          (codeUnit >= 0x0750 && codeUnit <= 0x077F) ||
          (codeUnit >= 0x08A0 && codeUnit <= 0x08FF) ||
          (codeUnit >= 0xFB50 && codeUnit <= 0xFDFF) ||
          (codeUnit >= 0xFE70 && codeUnit <= 0xFEFF)) {
        return true;
      }
    }
    return false;
  }
}
