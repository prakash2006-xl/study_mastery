import 'package:flutter/material.dart';
import 'package:perfect_freehand/perfect_freehand.dart';

class Stroke {
  final List<PointVector> points;
  final Color color;
  final double size;

  Stroke({required this.points, required this.color, required this.size});
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

  void _onPointerDown(PointerDownEvent event) {
    setState(() {
      currentStroke = Stroke(
        points: [PointVector(event.localPosition.dx, event.localPosition.dy)],
        color: _currentColor,
        size: _currentSize,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scribble Canvas'),
        actions: [
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
      bottomNavigationBar: BottomAppBar(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              icon: const Icon(Icons.circle, color: Colors.white),
              onPressed: () => setState(() => _currentColor = Colors.white),
            ),
            IconButton(
              icon: const Icon(Icons.circle, color: Colors.blueAccent),
              onPressed: () => setState(() => _currentColor = Colors.blueAccent),
            ),
            IconButton(
              icon: const Icon(Icons.circle, color: Colors.redAccent),
              onPressed: () => setState(() => _currentColor = Colors.redAccent),
            ),
            Slider(
              value: _currentSize,
              min: 2,
              max: 20,
              onChanged: (val) => setState(() => _currentSize = val),
            ),
          ],
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
