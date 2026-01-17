import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

class PropertyPdfPreview extends StatelessWidget {
  final LayoutCallback buildPdf;

  const PropertyPdfPreview({super.key, required this.buildPdf});

  @override
  Widget build(BuildContext context) {
    return PdfPreview(
      build: buildPdf,
      maxPageWidth: double.infinity,
      canChangePageFormat: false,
      useActions: false,
    );
  }
}
