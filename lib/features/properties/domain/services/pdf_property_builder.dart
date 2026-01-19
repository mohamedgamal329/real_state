import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart' as pdf;
import 'package:pdf/widgets.dart' as pw;
import 'package:real_state/features/models/entities/property.dart';
import 'pdf_details_renderer.dart';

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

    // FIX E2: Render details as PNG to support Arabic (NO pw.Text for Arabic)
    final detailsImageBytes = await PdfDetailsRenderer.renderToPng(
      title: titleText,
      description: descriptionText,
    );

    if (kDebugMode) {
      debugPrint('pdf_details_png_bytes=${detailsImageBytes.length}');
    }

    _addImagePages(doc, sanitizedImages);

    // FIX M: Move Details to END of PDF (NO LOGO on details page).
    _addDetailsPageImage(doc: doc, imageBytes: detailsImageBytes);

    if (kDebugMode) {
      debugPrint('pdf_details_page_added=true');
    }

    return doc.save();
  }

  void _addDetailsPageImage({
    required pw.Document doc,
    required Uint8List imageBytes,
  }) {
    final image = pw.MemoryImage(imageBytes);
    doc.addPage(
      pw.Page(
        pageTheme: pw.PageTheme(
          pageFormat: pdf.PdfPageFormat.a4,
          margin: pw.EdgeInsets.zero,
          buildBackground: (_) => pw.Container(
            color: pdf.PdfColors.grey900, // Match dark theme
          ),
        ),
        build: (_) => pw.Align(
          alignment: pw.Alignment.topCenter, // Start text from top
          child: pw.Image(
            image,
            fit: pw.BoxFit.contain,
            width: pdf.PdfPageFormat.a4.width,
          ),
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
}
