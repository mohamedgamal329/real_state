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

const double _kPdfPadding = 36.0;
const double _kPdfLogoSpacing = 24.0;
const double _kPdfTitleFontSize = 34.0;
const double _kPdfBodyFontSize = 18.0;
const double _kPdfLineSpacing = 1.7;
const double _kPdfDetailsLogoFactor = 0.25;
const double _kPdfLogoPageLogoFactor = 0.45;

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
    );

    return doc.save();
  }

  void _addLogoPage({
    required pw.Document doc,
    required Uint8List? logoBytes,
  }) {
    if (logoBytes == null) return;
    doc.addPage(
      pw.Page(
        pageTheme: pw.PageTheme(
          pageFormat: pdf.PdfPageFormat.a4,
          margin: pw.EdgeInsets.zero,
          buildBackground: (_) => pw.Container(color: pdf.PdfColors.grey900),
        ),
        build: (_) => _buildLogoPage(
          logoBytes: logoBytes,
          pageHeight: pdf.PdfPageFormat.a4.height,
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
        build: (_) => _buildDetailsPage(
          titleText: titleText,
          descriptionText: descriptionText,
          localeCode: localeCode,
          arabicFont: arabicFont,
          logoBytes: logoBytes,
          pageHeight: pdf.PdfPageFormat.a4.height,
        ),
      ),
    );
  }

  pw.Widget _buildDetailsPage({
    required String titleText,
    required String descriptionText,
    required String? localeCode,
    required pw.Font? arabicFont,
    required Uint8List? logoBytes,
    required double pageHeight,
  }) {
    final textColor = pdf.PdfColors.grey100;
    final accent = pdf.PdfColors.amber200;
    final arabicFontFallback = arabicFont != null ? [arabicFont] : null;
    final titleStyle = pw.TextStyle(
      fontSize: _kPdfTitleFontSize,
      fontWeight: pw.FontWeight.bold,
      color: accent,
      letterSpacing: 0.1,
      fontFallback: arabicFontFallback ?? const [],
    );
    final bodyStyle = pw.TextStyle(
      fontSize: _kPdfBodyFontSize,
      lineSpacing: _kPdfLineSpacing,
      color: textColor,
      fontFallback: arabicFontFallback ?? const [],
    );
    final isArabicLocale = localeCode?.toLowerCase().startsWith('ar') ?? false;
    final description = descriptionText.trim();
    final detailsLogoHeight = pageHeight * _kPdfDetailsLogoFactor;
    pw.Widget localizedText(
      String text, {
      pw.TextStyle? style,
    }) {
      final resolvedStyle = style ?? bodyStyle;
      final hasArabicCharacters = _containsArabic(text);
      final needsArabicFont = isArabicLocale || hasArabicCharacters;
      final effectiveStyle = resolvedStyle.copyWith(
        font: needsArabicFont && arabicFont != null ? arabicFont : resolvedStyle.font,
        fontFallback: arabicFontFallback ?? resolvedStyle.fontFallback,
        color: resolvedStyle.color,
      );
      final textDirection =
          needsArabicFont ? pw.TextDirection.rtl : pw.TextDirection.ltr;
      return pw.Directionality(
        textDirection: textDirection,
        child: pw.Text(
          text,
          style: effectiveStyle,
          textAlign: pw.TextAlign.center,
        ),
      );
    }

    return pw.Container(
      width: double.infinity,
      height: double.infinity,
      padding: const pw.EdgeInsets.symmetric(
        horizontal: _kPdfPadding,
        vertical: _kPdfPadding,
      ),
      child: pw.Center(
        child: pw.Column(
          mainAxisSize: pw.MainAxisSize.min,
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            if (logoBytes != null)
              pw.Container(
                height: detailsLogoHeight,
                alignment: pw.Alignment.center,
                child: pw.Image(
                  pw.MemoryImage(logoBytes),
                  height: detailsLogoHeight,
                  fit: pw.BoxFit.contain,
                ),
              ),
            if (logoBytes != null) pw.SizedBox(height: _kPdfLogoSpacing),
            localizedText(
              titleText.isNotEmpty ? titleText : 'property',
              style: titleStyle,
            ),
            if (description.isNotEmpty) ...[
              pw.SizedBox(height: _kPdfLogoSpacing),
              localizedText(description, style: bodyStyle),
            ],
          ],
        ),
      ),
    );
  }

  pw.Widget _buildLogoPage({
    required Uint8List? logoBytes,
    required double pageHeight,
  }) {
    if (logoBytes == null) {
      return pw.SizedBox.shrink();
    }
    final logoHeight = pageHeight * _kPdfLogoPageLogoFactor;
    return pw.Container(
      width: double.infinity,
      height: double.infinity,
      padding: pw.EdgeInsets.zero,
      child: pw.Center(
        child: pw.Container(
          height: logoHeight,
          alignment: pw.Alignment.center,
          child: pw.Image(
            pw.MemoryImage(logoBytes),
            height: logoHeight,
            fit: pw.BoxFit.contain,
          ),
        ),
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
