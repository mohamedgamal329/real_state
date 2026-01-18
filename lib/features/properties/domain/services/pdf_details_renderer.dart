import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PdfDetailsRenderer {
  static Future<Uint8List> renderToPng({
    required String title,
    required String description,
    double width = 595.0 * 2.0, // A4 width * 2 for high density
  }) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    const padding = 48.0;
    final contentWidth = width - (padding * 2);

    final titleStyle = TextStyle(
      fontSize: 48,
      fontWeight: FontWeight.bold,
      color: Colors.white,
      fontFamily: 'Cairo',
    );

    final descStyle = TextStyle(
      fontSize: 32,
      fontWeight: FontWeight.normal,
      color: Colors.white,
      fontFamily: 'Cairo', // Ensures Arabic support
      height: 1.5,
    );

    final titlePainter = TextPainter(
      text: TextSpan(text: title, style: titleStyle),
      textDirection: _detectDirection(title),
      textAlign: TextAlign.center,
    );
    titlePainter.layout(maxWidth: contentWidth);

    final descPainter = TextPainter(
      text: TextSpan(text: description, style: descStyle),
      textDirection: _detectDirection(description),
      textAlign: _detectDirection(description) == TextDirection.rtl
          ? TextAlign.right
          : TextAlign.center,
    );
    descPainter.layout(maxWidth: contentWidth);

    // Calculate height
    final height =
        padding +
        titlePainter.height +
        40.0 + // Gap
        descPainter.height +
        padding;

    // Draw Background
    final bgPaint = Paint()..color = Colors.grey[900]!;
    canvas.drawRect(Rect.fromLTWH(0, 0, width, height), bgPaint);

    // Draw Title
    titlePainter.paint(
      canvas,
      Offset((width - titlePainter.width) / 2, padding),
    );

    // Draw Divider (Optional)
    final dividerY = padding + titlePainter.height + 20.0;
    canvas.drawLine(
      Offset(padding + 20, dividerY),
      Offset(width - padding - 20, dividerY),
      Paint()
        ..color = Colors.grey.shade400
        ..strokeWidth = 2.0,
    );

    // Draw Description

    // For RTL text aligned right, descX should be width - padding - width.
    // Wait, TextAlign.right aligns within the layout width.
    // If we want it visually right-aligned in the canvas:
    // If RTL, TextPainter aligns lines to right.
    // We just need to position the Top-Left of the painter box.
    // TextPainter.width is the width of the longest line.

    // Simplification: Just center the painter box horizontally if Center alignment,
    // or properly position for Right alignment.
    // Above I set TextAlign.right for RTL.
    // So simple offset calculation:
    double descOffsetX = padding;
    if (_detectDirection(description) == TextDirection.rtl) {
      // If RTL, we usually want it aligned to the right edge.
      // But TextPainter width might be smaller than contentWidth.
      // Let's force it to fill content width to respect alignment?
      // No, TextPainter.layout(maxWidth: contentWidth) constraints it.
      // If we want true right align relative to page, we should use contentWidth
      // and let TextAlign handle it?
      // Actually, TextPainter doesn't have "width=contentWidth" by default, it shrinks wraps.
      // So we should position it at (width - padding - painter.width) if we want right alignment visually.
      // But TextAlign.right only affects internal line alignment.
      descOffsetX = width - padding - descPainter.width;
    } else {
      // Center for English
      descOffsetX = (width - descPainter.width) / 2;
    }

    descPainter.paint(
      canvas,
      Offset(descOffsetX, padding + titlePainter.height + 40.0),
    );

    final picture = recorder.endRecording();
    final img = await picture.toImage(width.toInt(), height.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  static TextDirection _detectDirection(String text) {
    return _containsArabic(text) ? TextDirection.rtl : TextDirection.ltr;
  }

  static bool _containsArabic(String text) {
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
