import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

class LocalPdfExportService {
  /// Converts an ARGB int color to PdfColor
  PdfColor _colorFromInt(int colorValue) {
    final color = Color(colorValue);
    return PdfColor(color.red, color.green, color.blue);
  }

  /// Parses the geometry JSON string into a list of points
  List<Offset> _parsePoints(String geometryStr) {
    final map = jsonDecode(geometryStr);
    final pointsList = map['points'] as List?;
    if (pointsList == null) return [];
    
    return pointsList.map((p) => Offset(p['x'] as double, p['y'] as double)).toList();
  }

  /// Bakes annotations directly into the PDF using local Dart processing
  Future<bool> burnAnnotationsToPdf({
    required String pdfPath,
    required List<Map<String, dynamic>> annotations,
    required Map<String, dynamic> pageMetrics,
  }) async {
    try {
      final File file = File(pdfPath);
      if (!file.existsSync()) return false;

      // Load existing PDF document
      final List<int> bytes = file.readAsBytesSync();
      final PdfDocument document = PdfDocument(inputBytes: bytes);

      for (var ann in annotations) {
        final int pageIndex = ann['page'] - 1; // 1-indexed to 0-indexed
        if (pageIndex < 0 || pageIndex >= document.pages.count) continue;

        final PdfPage page = document.pages[pageIndex];
        final PdfGraphics graphics = page.graphics;

        final geometryStr = ann['geometry'];
        if (geometryStr == null) continue;

        final geom = jsonDecode(geometryStr);
        final points = _parsePoints(geometryStr);
        if (points.isEmpty) continue;

        final int colorValue = geom['color'] ?? Colors.black.value;
        final double size = (geom['size'] ?? 2.0).toDouble();
        final int toolIdx = geom['tool'] ?? 0;
        
        final pdfColor = _colorFromInt(colorValue);
        final opacity = Color(colorValue).opacity;
        
        // Calculate scaling
        final originalSize = page.size; 
        final metrics = pageMetrics[(pageIndex + 1).toString()] ?? {'width': 800.0, 'height': 1200.0};
        final double scaleX = originalSize.width / (metrics['width'] as num);
        final double scaleY = originalSize.height / (metrics['height'] as num);

        // Apply opacity state
        graphics.setTransparency(opacity);

        final PdfPen pen = PdfPen(pdfColor, width: size);
        pen.lineCap = PdfLineCap.round;
        pen.lineJoin = PdfLineJoin.round;
        
        final PdfBrush brush = PdfSolidBrush(pdfColor);

        // Scale points
        final scaledPoints = points.map((p) => Offset(p.dx * scaleX, p.dy * scaleY)).toList();

        if (toolIdx == 0 || toolIdx == 1) {
          // Pen or Highlighter
          if (scaledPoints.length == 1) {
            // Draw dot
            final p = scaledPoints.first;
            graphics.drawEllipse(Rect.fromCircle(center: p, radius: size / 2), brush: brush);
          } else {
            // Draw path segments
            final PdfPath path = PdfPath();
            path.addLine(scaledPoints[0], scaledPoints[1]);
            for (int i = 1; i < scaledPoints.length - 1; i++) {
              path.addLine(scaledPoints[i], scaledPoints[i + 1]);
            }
            graphics.drawPath(path, pen: pen);
          }
        } else if (toolIdx == 5) {
          // Rectangle
          if (scaledPoints.length >= 2) {
            final p1 = scaledPoints.first;
            final p2 = scaledPoints.last;
            final rect = Rect.fromLTRB(p1.dx, p1.dy, p2.dx, p2.dy);
            graphics.drawRectangle(pen: pen, bounds: rect);
          }
        } else if (toolIdx == 6) {
          // Circle
          if (scaledPoints.length >= 2) {
            final p1 = scaledPoints.first;
            final p2 = scaledPoints.last;
            final rect = Rect.fromLTRB(p1.dx, p1.dy, p2.dx, p2.dy);
            graphics.drawEllipse(rect, pen: pen);
          }
        } else if (toolIdx == 7) {
          // Line
          if (scaledPoints.length >= 2) {
            final p1 = scaledPoints.first;
            final p2 = scaledPoints.last;
            graphics.drawLine(pen, p1, p2);
          }
        } else if (toolIdx == 8) {
          // Arrow
          if (scaledPoints.length >= 2) {
            final p1 = scaledPoints.first;
            final p2 = scaledPoints.last;
            graphics.drawLine(pen, p1, p2);
            // Draw arrow head
            const arrowLength = 20.0;
            const arrowAngle = 0.5;
            final angle = (p2 - p1).direction;
            final path = PdfPath()
              ..addLine(p2, Offset(p2.dx - arrowLength * cos(angle - arrowAngle), p2.dy - arrowLength * sin(angle - arrowAngle)))
              ..addLine(Offset(p2.dx - arrowLength * cos(angle - arrowAngle), p2.dy - arrowLength * sin(angle - arrowAngle)), p2)
              ..addLine(p2, Offset(p2.dx - arrowLength * cos(angle + arrowAngle), p2.dy - arrowLength * sin(angle + arrowAngle)));
            graphics.drawPath(path, pen: pen);
          }
        } else if (toolIdx == 9) {
          // Triangle
          if (scaledPoints.length >= 2) {
            final start = scaledPoints.first;
            final end = scaledPoints.last;
            final path = PdfPath()
              ..addLine(Offset((start.dx + end.dx) / 2, start.dy), end)
              ..addLine(end, Offset(start.dx, end.dy))
              ..addLine(Offset(start.dx, end.dy), Offset((start.dx + end.dx) / 2, start.dy));
            graphics.drawPath(path, pen: pen);
          }
        } else if (toolIdx == 10) {
          // Star
          if (scaledPoints.length >= 2) {
            final start = scaledPoints.first;
            final end = scaledPoints.last;
            final radius = (start - end).distance / 2;
            final center = Offset((start.dx + end.dx) / 2, (start.dy + end.dy) / 2);
            final path = PdfPath();
            for (int i = 0; i <= 10; i++) {
              final angle = -pi / 2 + (i * pi / 5);
              final r = i.isEven ? radius : radius / 2;
              final p = Offset(center.dx + r * cos(angle), center.dy + r * sin(angle));
              if (i == 0) {
                path.addLine(p, p); // Hack to start path in Syncfusion
              } else {
                final prevAngle = -pi / 2 + ((i - 1) * pi / 5);
                final prevR = (i - 1).isEven ? radius : radius / 2;
                final prevP = Offset(center.dx + prevR * cos(prevAngle), center.dy + prevR * sin(prevAngle));
                path.addLine(prevP, p);
              }
            }
            graphics.drawPath(path, pen: pen);
          }
        }
      }

      // Save and overwrite the original document
      final List<int> updatedBytes = await document.save();
      document.dispose();
      file.writeAsBytesSync(updatedBytes);
      return true;
    } catch (e) {
      debugPrint('Error burning PDF locally: $e');
      return false;
    }
  }
}
