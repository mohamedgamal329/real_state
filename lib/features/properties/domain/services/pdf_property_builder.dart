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
const double _kPdfTitleFontSize = 36.0;
const double _kPdfBodyFontSize = 20.0;
const double _kPdfLineSpacing = 1.7;
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

    _addImagePages(doc, sanitizedImages);
    _addDetailsPage(
      doc: doc,
      titleText: titleText,
      descriptionText: descriptionText,
      logoBytes: logoBytes,
      localeCode: localeCode,
      arabicFont: arabicFont,
      isRtl: _shouldUseRtl(localeCode, [titleText, descriptionText]),
    );
    _addLogoPage(doc: doc, logoBytes: logoBytes);

    return doc.save();
  }

  void _addLogoPage({required pw.Document doc, required Uint8List? logoBytes}) {
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
          pageFormat: pdf.PdfPageFormat.a4,
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
    required bool isRtl,
  }) {
    doc.addPage(
      pw.Page(
        pageTheme: pw.PageTheme(
          pageFormat: pdf.PdfPageFormat.a4,
          margin: pw.EdgeInsets.zero,
          textDirection: isRtl ? pw.TextDirection.rtl : pw.TextDirection.ltr,
          buildBackground: (_) => pw.Container(color: pdf.PdfColors.grey900),
        ),
        build: (_) => _buildDetailsPage(
          titleText: titleText,
          descriptionText: descriptionText,
          localeCode: localeCode,
          arabicFont: arabicFont,
          logoBytes: logoBytes,
          pageFormat: pdf.PdfPageFormat.a4,
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
    required pdf.PdfPageFormat pageFormat,
  }) {
    final pageWidth = pageFormat.availableWidth;
    final pageHeight = pageFormat.availableHeight;
    final textColor = pdf.PdfColors.grey100;
    final accent = pdf.PdfColors.amber200;
    final arabicFontFallback = arabicFont != null ? [arabicFont] : null;

    final titleStyle = pw.TextStyle(
      fontSize: _kPdfTitleFontSize,
      fontWeight: pw.FontWeight.bold,
      color: accent,
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

    pw.Widget localizedText(
      String text, {
      pw.TextStyle? style,
      pw.TextAlign? align,
    }) {
      final resolvedStyle = style ?? bodyStyle;
      final hasArabicCharacters = _containsArabic(text);
      final needsArabicFont = isArabicLocale || hasArabicCharacters;
      final effectiveStyle = resolvedStyle.copyWith(
        font: (needsArabicFont && arabicFont != null)
            ? arabicFont
            : resolvedStyle.font,
        fontFallback: arabicFontFallback ?? resolvedStyle.fontFallback,
      );
      return pw.Directionality(
        textDirection: needsArabicFont
            ? pw.TextDirection.rtl
            : pw.TextDirection.ltr,
        child: pw.Text(
          text,
          style: effectiveStyle,
          textAlign:
              align ??
              (needsArabicFont ? pw.TextAlign.right : pw.TextAlign.center),
        ),
      );
    }

    return pw.Container(
      width: pageWidth,
      height: pageHeight,
      padding: const pw.EdgeInsets.symmetric(
        horizontal: _kPdfPadding,
        vertical: _kPdfPadding,
      ),
      child: pw.Center(
        child: pw.Column(
          mainAxisSize: pw.MainAxisSize.min,
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            /* Logo removed from details page as per FIX 6 requirements */
            pw.SizedBox(height: 10),
            localizedText(
              titleText.isNotEmpty ? titleText : 'Property',
              style: titleStyle,
            ),
            if (description.isNotEmpty) ...[
              pw.SizedBox(height: 30),
              pw.Divider(color: pdf.PdfColors.grey700),
              pw.SizedBox(height: 30),
              localizedText(description, style: bodyStyle),
            ],
          ],
        ),
      ),
    );
  }

  pw.Widget _buildLogoPage({
    required Uint8List? logoBytes,
    required pdf.PdfPageFormat pageFormat,
  }) {
    if (logoBytes == null) {
      return pw.SizedBox.shrink();
    }
    final pageWidth = pageFormat.availableWidth;
    final pageHeight = pageFormat.availableHeight;
    final logoHeight = pageHeight * _kPdfLogoPageLogoFactor;
    return pw.Container(
      width: pageWidth,
      height: pageHeight,
      padding: pw.EdgeInsets.zero,
      alignment: pw.Alignment.center,
      child: pw.Container(
        height: logoHeight,
        width: pageWidth,
        alignment: pw.Alignment.center,
        child: pw.Image(
          pw.MemoryImage(logoBytes),
          height: logoHeight,
          fit: pw.BoxFit.contain,
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

  bool _shouldUseRtl(String? localeCode, List<String> samples) {
    final isArabicLocale = localeCode?.toLowerCase().startsWith('ar') ?? false;
    if (isArabicLocale) return true;
    for (final text in samples) {
      if (_containsArabic(text)) return true;
    }
    return false;
  }
}
