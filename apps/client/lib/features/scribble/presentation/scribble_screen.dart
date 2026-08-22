import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:perfect_freehand/perfect_freehand.dart';

class Stroke {
  final List<PointVector> points;
  final Color color;
  final double size;
  final bool isEraser;

  Stroke({required this.points, required this.color, required this.size, this.isEraser = false});
}

class ScribbleScreen extends StatefulWidget {
  const ScribbleScreen({super.key});

  @override
  State<ScribbleScreen> createState() => _ScribbleScreenState();
}

class _ScribbleScreenState extends State<ScribbleScreen> {
  List<Stroke> strokes = [];
  Stroke? currentStroke;
  Color _currentColor = Colors.white;
  double _currentSize = 5.0;
  bool _isEraser = false;
  
  final GlobalKey _canvasKey = GlobalKey();

  void _onPointerDown(PointerDownEvent event) {
    setState(() {
      currentStroke = Stroke(
        points: [PointVector(event.localPosition.dx, event.localPosition.dy)],
        color: _isEraser ? Theme.of(context).colorScheme.surface : _currentColor,
        size: _isEraser ? _currentSize * 3 : _currentSize,
        isEraser: _isEraser,
      );
    });
  }

  void _onPointerMove(PointerMoveEvent event) {
    if (currentStroke != null) {
      setState(() {
        currentStroke!.points.add(PointVector(event.localPosition.dx, event.localPosition.dy));
      });
    }
  }

  void _onPointerUp(PointerUpEvent event) {
    if (currentStroke != null) {
      setState(() {
        strokes.add(currentStroke!);
        currentStroke = null;
      });
    }
  }

  void _clearCanvas() {
    setState(() {
      strokes.clear();
      currentStroke = null;
    });
  }

  void _undo() {
    setState(() {
      if (strokes.isNotEmpty) {
        strokes.removeLast();
      }
    });
  }

  Future<void> _saveCanvas() async {
    try {
      final boundary = _canvasKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

      final buffer = byteData.buffer.asUint8List();

      final docDir = await getApplicationDocumentsDirectory();
      final path = '${docDir.path}/Scribble_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File(path);
      await file.writeAsBytes(buffer);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Saved to Documents: Scribble_${DateTime.now().millisecondsSinceEpoch}.png')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save image: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scribble Canvas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveCanvas,
            tooltip: 'Save Image',
          ),
          IconButton(
            icon: const Icon(Icons.undo),
            onPressed: _undo,
            tooltip: 'Undo',
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _clearCanvas,
            tooltip: 'Clear Canvas',
          ),
        ],
      ),
      body: Listener(
        onPointerDown: _onPointerDown,
        onPointerMove: _onPointerMove,
        onPointerUp: _onPointerUp,
        child: RepaintBoundary(
          key: _canvasKey,
          child: Container(
            width: double.infinity,
            height: double.infinity,
            color: Theme.of(context).colorScheme.surface,
            child: CustomPaint(
              painter: ScribblePainter(
                strokes: strokes,
                currentStroke: currentStroke,
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              IconButton(
                icon: Icon(Icons.draw, color: !_isEraser ? Colors.white : Colors.grey),
                onPressed: () => setState(() => _isEraser = false),
                tooltip: 'Pen',
              ),
              IconButton(
                icon: Icon(Icons.cleaning_services, color: _isEraser ? Colors.white : Colors.grey),
                onPressed: () => setState(() => _isEraser = true),
                tooltip: 'Eraser',
              ),
              const SizedBox(width: 16),
              IconButton(
                icon: const Icon(Icons.circle, color: Colors.white),
                onPressed: () => setState(() { _currentColor = Colors.white; _isEraser = false; }),
              ),
              IconButton(
                icon: const Icon(Icons.circle, color: Colors.blueAccent),
                onPressed: () => setState(() { _currentColor = Colors.blueAccent; _isEraser = false; }),
              ),
              IconButton(
                icon: const Icon(Icons.circle, color: Colors.redAccent),
                onPressed: () => setState(() { _currentColor = Colors.redAccent; _isEraser = false; }),
              ),
              IconButton(
                icon: const Icon(Icons.circle, color: Colors.greenAccent),
                onPressed: () => setState(() { _currentColor = Colors.greenAccent; _isEraser = false; }),
              ),
              IconButton(
                icon: const Icon(Icons.circle, color: Colors.yellowAccent),
                onPressed: () => setState(() { _currentColor = Colors.yellowAccent; _isEraser = false; }),
              ),
              IconButton(
                icon: const Icon(Icons.circle, color: Colors.purpleAccent),
                onPressed: () => setState(() { _currentColor = Colors.purpleAccent; _isEraser = false; }),
              ),
              const SizedBox(width: 16),
              Slider(
                value: _currentSize,
                min: 2,
                max: 20,
                onChanged: (val) => setState(() => _currentSize = val),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ScribblePainter extends CustomPainter {
  final List<Stroke> strokes;
  final Stroke? currentStroke;

  ScribblePainter({required this.strokes, this.currentStroke});

  @override
  void paint(Canvas canvas, Size size) {
    for (final stroke in strokes) {
      _paintStroke(canvas, stroke);
    }
    if (currentStroke != null) {
      _paintStroke(canvas, currentStroke!);
    }
  }

  void _paintStroke(Canvas canvas, Stroke stroke) {
    final outlinePoints = getStroke(
      stroke.points,
      options: StrokeOptions(
        size: stroke.size,
        thinning: 0.5,
        smoothing: 0.5,
        streamline: 0.5,
      ),
    );

    final path = Path();
    if (outlinePoints.isNotEmpty) {
      path.moveTo(outlinePoints.first.dx, outlinePoints.first.dy);
      for (var i = 1; i < outlinePoints.length - 1; ++i) {
        final p0 = outlinePoints[i];
        final p1 = outlinePoints[i + 1];
        path.quadraticBezierTo(p0.dx, p0.dy, (p0.dx + p1.dx) / 2, (p0.dy + p1.dy) / 2);
      }
    }

    canvas.drawPath(path, Paint()..color = stroke.color);
  }

  @override
  bool shouldRepaint(covariant ScribblePainter oldDelegate) {
    return true; // Simplified for this stub
  }
}
