import 'dart:io';
import 'package:flutter/material.dart';
import 'package:screenshot/screenshot.dart';
import 'package:perfect_freehand/perfect_freehand.dart';
import 'package:go_router/go_router.dart';
import 'package:pdfx/pdfx.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:math';
import '../../../core/api/ai_gateway_service.dart';

class SeriousStudyScreen extends StatefulWidget {
  final String? filePath;
  final String? documentId;
  
  const SeriousStudyScreen({super.key, this.filePath, this.documentId});

  @override
  State<SeriousStudyScreen> createState() => _SeriousStudyScreenState();
}

class _SeriousStudyScreenState extends State<SeriousStudyScreen> {
  late PdfController _pdfController;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  
  final AiGatewayService _aiService = AiGatewayService();
  final TextEditingController _chatController = TextEditingController();
  final List<Map<String, String>> _messages = [];
  bool _isTyping = false;
  
  late String _currentDocumentId; 
  
  // Voice AI
  late AudioRecorder _audioRecorder;
  late AudioPlayer _audioPlayer;
  bool _isRecording = false;

  // Scribble Mode
  bool _isDrawingMode = false;
  DrawingTool _currentTool = DrawingTool.pen;
  List<Stroke> strokes = [];
  Stroke? currentStroke;
  Color _currentColor = Colors.redAccent;
  double _currentSize = 5.0;

  final ScreenshotController _screenshotController = ScreenshotController();

  void _onPointerDown(PointerDownEvent event) {
    if (!_isDrawingMode) return;
    setState(() {
      currentStroke = Stroke(
        points: [PointVector(event.localPosition.dx, event.localPosition.dy)],
        color: _currentColor,
        size: _currentSize,
        tool: _currentTool,
      );
    });
  }

  void _onPointerMove(PointerMoveEvent event) {
    if (!_isDrawingMode || currentStroke == null) return;
    setState(() {
      if (currentStroke!.tool == DrawingTool.pen || currentStroke!.tool == DrawingTool.eraser) {
        currentStroke!.points.add(PointVector(event.localPosition.dx, event.localPosition.dy));
      } else {
        // For shapes (rectangle, circle, line), we only track the start and current end point
        if (currentStroke!.points.length > 1) {
          currentStroke!.points.removeLast();
        }
        currentStroke!.points.add(PointVector(event.localPosition.dx, event.localPosition.dy));
      }
    });
  }

  void _onPointerUp(PointerUpEvent event) {
    if (!_isDrawingMode || currentStroke == null) return;
    setState(() {
      strokes.add(currentStroke!);
      currentStroke = null;
    });
  }

  Future<void> _saveScreenshot() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final path = '${directory.path}/LearningOS_Scribbles';
      final dir = Directory(path);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      
      final fileName = 'scribble_${DateTime.now().millisecondsSinceEpoch}.png';
      final image = await _screenshotController.captureAndSave(path, fileName: fileName);
      
      if (mounted && image != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Screenshot saved to: $image')),
        );
      }
    } catch (e) {
      debugPrint('Screenshot error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save screenshot: $e')),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _currentDocumentId = widget.documentId ?? "test_document_id";
    
    _audioRecorder = AudioRecorder();
    _audioPlayer = AudioPlayer();
    
    _pdfController = PdfController(
      document: widget.filePath != null 
          ? PdfDocument.openFile(widget.filePath!)
          : PdfDocument.openAsset('assets/sample.pdf'),
    );
  }

  @override
  void dispose() {
    _pdfController.dispose();
    _chatController.dispose();
    _audioRecorder.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final query = _chatController.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _messages.add({'sender': 'user', 'text': query});
      _isTyping = true;
    });
    _chatController.clear();

    final response = await _aiService.askDocument(_currentDocumentId, query);

    if (mounted) {
      setState(() {
        _messages.add({'sender': 'ai', 'text': response});
        _isTyping = false;
      });
    }
  }

  Future<void> _startRecording() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        final tempDir = await getTemporaryDirectory();
        final path = '${tempDir.path}/voice_query.m4a';
        await _audioRecorder.start(
          const RecordConfig(encoder: AudioEncoder.aacLc),
          path: path,
        );
        setState(() => _isRecording = true);
      }
    } catch (e) {
      debugPrint('Error starting record: $e');
    }
  }

  Future<void> _stopRecordingAndSend() async {
    try {
      final path = await _audioRecorder.stop();
      setState(() => _isRecording = false);
      
      if (path != null) {
        setState(() => _isTyping = true);
        
        final result = await _aiService.sendVoiceChat(_currentDocumentId, path);
        
        if (mounted) {
          setState(() {
            _isTyping = false;
            if (result != null) {
              _messages.add({'sender': 'user', 'text': result['transcript']!});
              _messages.add({'sender': 'ai', 'text': '🎤 (Voice Message Played)'});
              // Play the audio
              _audioPlayer.play(DeviceFileSource(result['audioPath']!));
            } else {
              _messages.add({'sender': 'ai', 'text': 'Error processing voice chat.'});
            }
          });
        }
      }
    } catch (e) {
      debugPrint('Error stopping record: $e');
      setState(() => _isRecording = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: const Text('Serious Study Workspace'),
        actions: [
          IconButton(
            icon: const Icon(Icons.psychology),
            tooltip: 'AI Companion',
            onPressed: () {
              _scaffoldKey.currentState?.openEndDrawer();
            },
          ),
          IconButton(
            icon: const Icon(Icons.mic),
            tooltip: 'Voice Note',
            onPressed: () {},
          ),
        ],
      ),
      body: Screenshot(
        controller: _screenshotController,
        child: Stack(
          children: [
            PdfView(
              controller: _pdfController,
              scrollDirection: Axis.vertical,
            ),
          if (_isDrawingMode)
            Positioned.fill(
              child: Listener(
                onPointerDown: _onPointerDown,
                onPointerMove: _onPointerMove,
                onPointerUp: _onPointerUp,
                child: CustomPaint(
                  painter: ScribblePainter(strokes, currentStroke),
                  size: Size.infinite,
                ),
              ),
            ),
          if (_isDrawingMode)
            Positioned(
              top: 16,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(color: Colors.black26, blurRadius: 4, spreadRadius: 1),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.undo),
                        onPressed: () {
                          if (strokes.isNotEmpty) setState(() => strokes.removeLast());
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => setState(() => strokes.clear()),
                      ),
                      IconButton(
                        icon: const Icon(Icons.save_alt),
                        onPressed: _saveScreenshot,
                      ),
                      Container(width: 1, height: 24, color: Colors.grey),
                      const SizedBox(width: 8),
                      _buildToolButton(DrawingTool.pen, Icons.edit),
                      _buildToolButton(DrawingTool.rectangle, Icons.crop_square),
                      _buildToolButton(DrawingTool.circle, Icons.circle_outlined),
                      _buildToolButton(DrawingTool.line, Icons.horizontal_rule),
                      _buildToolButton(DrawingTool.arrow, Icons.arrow_outward),
                      _buildToolButton(DrawingTool.eraser, Icons.phonelink_erase),
                      Container(width: 1, height: 24, color: Colors.grey),
                      const SizedBox(width: 8),
                      _buildColorButton(Colors.redAccent),
                      _buildColorButton(Colors.blueAccent),
                      _buildColorButton(Colors.greenAccent),
                      _buildColorButton(Colors.amber),
                      _buildColorButton(Colors.black),
                      _buildColorButton(Colors.white),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      endDrawer: Drawer(
        width: 350,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16.0),
              color: Theme.of(context).colorScheme.primaryContainer,
              width: double.infinity,
              child: const SafeArea(
                child: Text(
                  'AI Companion',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final msg = _messages[index];
                  final isUser = msg['sender'] == 'user';
                  return Align(
                    alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isUser 
                            ? Theme.of(context).colorScheme.primary 
                            : Theme.of(context).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        msg['text']!,
                        style: TextStyle(
                          color: isUser 
                              ? Theme.of(context).colorScheme.onPrimary 
                              : Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            if (_isTyping)
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: CircularProgressIndicator(),
              ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _chatController,
                      decoration: const InputDecoration(
                        hintText: 'Ask about this document...',
                        border: OutlineInputBorder(),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  GestureDetector(
                    onLongPressStart: (_) => _startRecording(),
                    onLongPressEnd: (_) => _stopRecordingAndSend(),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _isRecording ? Colors.red : Theme.of(context).colorScheme.primaryContainer,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _isRecording ? Icons.mic : Icons.mic_none,
                        color: _isRecording ? Colors.white : Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: _sendMessage,
                  ),
                ],
              ),
            )
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            _isDrawingMode = !_isDrawingMode;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_isDrawingMode ? 'Drawing Mode Enabled' : 'Drawing Mode Disabled (Scroll to pan)'),
              duration: const Duration(seconds: 2),
            ),
          );
        },
        tooltip: 'Toggle Drawing Mode',
        backgroundColor: _isDrawingMode ? Colors.redAccent : Theme.of(context).colorScheme.primaryContainer,
        child: Icon(_isDrawingMode ? Icons.edit_off : Icons.edit),
      ),
    );
  }

  Widget _buildColorButton(Color color) {
    final isSelected = _currentColor == color;
    return GestureDetector(
      onTap: () => setState(() => _currentColor = color),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? Colors.white : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            if (isSelected) const BoxShadow(color: Colors.black26, blurRadius: 4, spreadRadius: 1),
          ],
        ),
      ),
    );
  }

  Widget _buildToolButton(DrawingTool tool, IconData icon) {
    final isSelected = _currentTool == tool;
    return IconButton(
      icon: Icon(icon, color: isSelected ? Colors.redAccent : Colors.grey),
      onPressed: () => setState(() => _currentTool = tool),
    );
  }
}

enum DrawingTool { pen, eraser, rectangle, circle, line, arrow }

class Stroke {
  final List<PointVector> points;
  final Color color;
  final double size;
  final DrawingTool tool;

  Stroke({required this.points, required this.color, required this.size, required this.tool});
}

class ScribblePainter extends CustomPainter {
  final List<Stroke> strokes;
  final Stroke? currentStroke;

  ScribblePainter(this.strokes, this.currentStroke);

  @override
  void paint(Canvas canvas, Size size) {
    final allStrokes = List<Stroke>.from(strokes);
    if (currentStroke != null) {
      allStrokes.add(currentStroke!);
    }

    for (var stroke in allStrokes) {
      if (stroke.points.isEmpty) continue;
      
      final paint = Paint()
        ..color = stroke.tool == DrawingTool.eraser ? Colors.transparent : stroke.color
        ..strokeWidth = stroke.size
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = stroke.tool == DrawingTool.pen || stroke.tool == DrawingTool.eraser 
            ? PaintingStyle.fill 
            : PaintingStyle.stroke;
            
      if (stroke.tool == DrawingTool.eraser) {
        paint.blendMode = BlendMode.clear;
        paint.style = PaintingStyle.stroke;
      }

      final start = Offset(stroke.points.first.x, stroke.points.first.y);
      final end = Offset(stroke.points.last.x, stroke.points.last.y);

      if (stroke.tool == DrawingTool.pen || stroke.tool == DrawingTool.eraser) {
        if (stroke.points.length == 1) {
          canvas.drawCircle(start, stroke.size / 2, paint);
        } else {
          final path = Path();
          final outlinePoints = getStroke(
            stroke.points,
            options: StrokeOptions(size: stroke.size, thinning: 0.5, smoothing: 0.5, streamline: 0.5),
          );
          
          if (outlinePoints.isNotEmpty) {
            path.moveTo(outlinePoints.first.dx, outlinePoints.first.dy);
            for (var i = 1; i < outlinePoints.length; i++) {
              path.lineTo(outlinePoints[i].dx, outlinePoints[i].dy);
            }
            path.close();
            canvas.drawPath(path, paint..style = PaintingStyle.fill);
          }
        }
      } else if (stroke.tool == DrawingTool.rectangle) {
        canvas.drawRect(Rect.fromPoints(start, end), paint);
      } else if (stroke.tool == DrawingTool.circle) {
        final radius = (start - end).distance / 2;
        final center = Offset((start.dx + end.dx) / 2, (start.dy + end.dy) / 2);
        canvas.drawCircle(center, radius, paint);
      } else if (stroke.tool == DrawingTool.line) {
        canvas.drawLine(start, end, paint);
      } else if (stroke.tool == DrawingTool.arrow) {
        canvas.drawLine(start, end, paint);
        // Draw arrow head
        const arrowLength = 20.0;
        const arrowAngle = 0.5;
        final angle = (end - start).direction;
        final path = Path()
          ..moveTo(end.dx, end.dy)
          ..lineTo(end.dx - arrowLength * cos(angle - arrowAngle), end.dy - arrowLength * sin(angle - arrowAngle))
          ..moveTo(end.dx, end.dy)
          ..lineTo(end.dx - arrowLength * cos(angle + arrowAngle), end.dy - arrowLength * sin(angle + arrowAngle));
        canvas.drawPath(path, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant ScribblePainter oldDelegate) {
    return true;
  }
}
