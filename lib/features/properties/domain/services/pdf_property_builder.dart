import 'dart:typed_data';
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

    // FIX E2: Render details as PNG to support Arabic
    final detailsImageBytes = await PdfDetailsRenderer.renderToPng(
      title: titleText,
      description: descriptionText,
    );

    _addImagePages(doc, sanitizedImages);

    // FIX M: Move Details & Logo to END of PDF.
    _addDetailsPageImage(doc: doc, imageBytes: detailsImageBytes);
    _addLogoPage(doc: doc, logoBytes: logoBytes);

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

  pw.Widget _buildLogoPage({
    required Uint8List? logoBytes,
    required pdf.PdfPageFormat pageFormat,
  }) {
    if (logoBytes == null) {
      return pw.SizedBox.shrink();
    }

    final pageHeight = pageFormat.availableHeight;
    final logoHeight = pageHeight * _kPdfLogoPageLogoFactor;
    return pw.Center(
      child: pw.Image(
        pw.MemoryImage(logoBytes),
        height: logoHeight,
        fit: pw.BoxFit.contain,
      ),
    );
  }
}
