import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PdfDetailsRenderer {
  static const double _a4Width = 595.0;
  static const double _a4Height = 842.0;
  static const int _pageBgColor = 0xFF212121;

  static Future<Uint8List> renderToPng({
    required String title,
    required String description,
    double width = _a4Width * 2.0, // A4 width * 2 for high density
    double height = _a4Height * 2.0,
  }) async {
    final pages = await renderToPngPages(
      title: title,
      description: description,
      width: width,
      height: height,
    );
    return pages.first;
  }

  static Future<List<Uint8List>> renderToPngPages({
    required String title,
    required String description,
    double width = _a4Width * 2.0, // A4 width * 2 for high density
    double height = _a4Height * 2.0,
  }) async {
    const padding = 48.0;
    const topPaddingFirstPage = 64.0;
    const titleToDescriptionGap = 40.0;
    final contentWidth = width - (padding * 2);
    if (kDebugMode) {
      final bgHex = _pageBgColor.toRadixString(16).padLeft(8, '0');
      debugPrint(
        'pdf_details_png_size=${width.toStringAsFixed(1)}x${height.toStringAsFixed(1)} '
        'contentWidth=${contentWidth.toStringAsFixed(1)} padding=$padding '
        'pageBg=0x$bgHex',
      );
    }

    final titleStyle = TextStyle(
      fontSize: 68,
      fontWeight: FontWeight.bold,
      color: Colors.white,
      fontFamily: 'Cairo',
      height: 1.3,
    );

    final descStyle = TextStyle(
      fontSize: 42,
      fontWeight: FontWeight.normal,
      color: Colors.white,
      fontFamily: 'Cairo', // Ensures Arabic support
      height: 1.6,
    );

    final titleDirection = _detectDirection(title);
    final descriptionDirection = _detectDirection(description);
    final titleAlign =
        titleDirection == TextDirection.rtl ? TextAlign.right : TextAlign.left;
    if (kDebugMode) {
      debugPrint(
        'pdf_details_text_align title=$titleAlign desc=${descriptionDirection == TextDirection.rtl ? TextAlign.right : TextAlign.left} '
        'textStartX=$padding',
      );
    }

    final titlePainter = TextPainter(
      text: TextSpan(text: title, style: titleStyle),
      textDirection: titleDirection,
      textAlign: titleAlign,
      textWidthBasis: TextWidthBasis.parent,
    );
    titlePainter.layout(maxWidth: contentWidth);

    final descAlign =
        descriptionDirection == TextDirection.rtl ? TextAlign.right : TextAlign.left;

    final pages = <Uint8List>[];
    var remaining = description;
    var isFirstPage = true;

    while (remaining.trim().isNotEmpty) {
      final pageRecorder = ui.PictureRecorder();
      final canvas = Canvas(pageRecorder);
      // Transparent background: paint text only so PDF page color is single source of truth.

      double descTop = padding;
      if (isFirstPage) {
        // Draw Title
        titlePainter.paint(
          canvas,
          Offset(padding, topPaddingFirstPage),
        );

        // Draw Divider
        final dividerY = topPaddingFirstPage + titlePainter.height + 20.0;
        canvas.drawLine(
          Offset(padding + 20, dividerY),
          Offset(width - padding - 20, dividerY),
          Paint()
            ..color = Colors.grey.shade400
            ..strokeWidth = 2.0,
        );

        descTop = topPaddingFirstPage + titlePainter.height + titleToDescriptionGap;
      } else {
        descTop = padding;
      }

      final availableHeight = height - descTop - padding;
      final maxChars = _fitTextLength(
        text: remaining,
        style: descStyle,
        maxWidth: contentWidth,
        maxHeight: availableHeight,
        textDirection: descriptionDirection,
        textAlign: descAlign,
      );

      int end;
      if (maxChars <= 0) {
        end = remaining.length < 200 ? remaining.length : 200;
        assert(() {
          debugPrint('pdf_details_paginate_fallback=true chunk=$end');
          return true;
        }());
      } else {
        end = _adjustCutIndex(remaining, maxChars);
      }
      final pageText = remaining.substring(0, end).trimRight();
      remaining = remaining.substring(end).trimLeft();

      final descPainter = TextPainter(
        text: TextSpan(text: pageText, style: descStyle),
        textDirection: descriptionDirection,
        textAlign: descAlign,
        textWidthBasis: TextWidthBasis.parent,
      );
      descPainter.layout(maxWidth: contentWidth);
      descPainter.paint(canvas, Offset(padding, descTop));

      final picture = pageRecorder.endRecording();
      final img = await picture.toImage(width.toInt(), height.toInt());
      final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
      pages.add(byteData!.buffer.asUint8List());
      isFirstPage = false;
    }

    if (pages.isEmpty) {
      final emptyRecorder = ui.PictureRecorder();
      final emptyCanvas = Canvas(emptyRecorder);
      // Keep transparent output for empty details pages as well.
      final picture = emptyRecorder.endRecording();
      final img = await picture.toImage(width.toInt(), height.toInt());
      final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
      pages.add(byteData!.buffer.asUint8List());
    }

    return pages;
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

  static int _fitTextLength({
    required String text,
    required TextStyle style,
    required double maxWidth,
    required double maxHeight,
    required TextDirection textDirection,
    required TextAlign textAlign,
  }) {
    if (text.isEmpty) return 0;
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: textDirection,
      textAlign: textAlign,
      textWidthBasis: TextWidthBasis.parent,
    );
    painter.layout(maxWidth: maxWidth);
    if (painter.height <= maxHeight) return text.length;

    final position = painter.getPositionForOffset(Offset(maxWidth, maxHeight));
    var end = position.offset;
    if (end <= 0) return 0;

    for (var i = end - 1; i > 0; i--) {
      final char = text[i];
      if (char.trim().isEmpty) {
        end = i;
        break;
      }
    }

    return end;
  }

  static int _adjustCutIndex(String text, int end) {
    final safeEnd = end > text.length ? text.length : end;
    final windowStart = safeEnd - 80 > 0 ? safeEnd - 80 : 0;
    final window = text.substring(windowStart, safeEnd);

    final lastNewline = window.lastIndexOf('\n');
    if (lastNewline != -1) {
      return windowStart + lastNewline;
    }

    final lastSpace = window.lastIndexOf(' ');
    if (lastSpace != -1) {
      return windowStart + lastSpace;
    }

    return safeEnd > 0 ? safeEnd : 1;
  }
}
