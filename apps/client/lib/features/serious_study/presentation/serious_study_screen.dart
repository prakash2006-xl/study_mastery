import 'dart:io';
import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdfx/pdfx.dart';
import 'package:perfect_freehand/perfect_freehand.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:math';

import '../../../core/api/ai_gateway_service.dart';
import '../../../core/pdf/local_pdf_export_service.dart';
import '../application/annotation_provider.dart';
import '../../../core/database/annotation_repository.dart';

enum DrawingTool { pen, highlighter, eraser, sticky_note, bookmark, rectangle, circle, line, arrow }

class Stroke {
  final List<PointVector> points;
  final Color color;
  final double size;
  final DrawingTool tool;

  Stroke({required this.points, required this.color, required this.size, required this.tool});

  String toJsonStr() {
    return jsonEncode({
      'points': points.map((p) => {'x': p.x, 'y': p.y}).toList(),
      'color': color.value,
      'size': size,
      'tool': tool.index,
    });
  }

  static Stroke fromJsonStr(String jsonStr) {
    final map = jsonDecode(jsonStr);
    final pointsList = map['points'] as List;
    final points = pointsList.map((p) => PointVector(p['x'] as double, p['y'] as double)).toList();
    return Stroke(
      points: points,
      color: Color(map['color'] as int),
      size: map['size'] as double,
      tool: DrawingTool.values[map['tool'] as int],
    );
  }
}

class SeriousStudyScreen extends ConsumerStatefulWidget {
  final String? filePath;
  final String? documentId;
  
  const SeriousStudyScreen({super.key, this.filePath, this.documentId});

  @override
  ConsumerState<SeriousStudyScreen> createState() => _SeriousStudyScreenState();
}

class _SeriousStudyScreenState extends ConsumerState<SeriousStudyScreen> {
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
  bool _showBrushSettings = false;
  DrawingTool _currentTool = DrawingTool.pen;
  Stroke? _currentStroke;
  Color _currentColor = Colors.black;
  double _currentSize = 4.0;
  double _currentOpacity = 1.0;

  int _currentPage = 1;

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

  // --- Annotations & Gestures --- //

  void _onPanStart(DragStartDetails details, int page) {
    if (!_isDrawingMode) return;
    
    if (_currentTool == DrawingTool.sticky_note || _currentTool == DrawingTool.bookmark) return;

    setState(() {
      _showBrushSettings = false; // Hide settings when drawing starts
      _currentStroke = Stroke(
        points: [PointVector(details.localPosition.dx, details.localPosition.dy)],
        color: _currentTool == DrawingTool.highlighter ? _currentColor.withOpacity(0.4) : _currentColor.withOpacity(_currentOpacity),
        size: _currentSize,
        tool: _currentTool,
      );
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (!_isDrawingMode || _currentStroke == null) return;
    setState(() {
      if (_currentStroke!.tool == DrawingTool.pen || _currentStroke!.tool == DrawingTool.highlighter || _currentStroke!.tool == DrawingTool.eraser) {
        _currentStroke!.points.add(PointVector(details.localPosition.dx, details.localPosition.dy));
      } else {
        if (_currentStroke!.points.length > 1) {
          _currentStroke!.points.removeLast();
        }
        _currentStroke!.points.add(PointVector(details.localPosition.dx, details.localPosition.dy));
      }
    });
  }

  void _onPanEnd(DragEndDetails details, int page) {
    if (!_isDrawingMode || _currentStroke == null) return;
    
    final finalStroke = _currentStroke!;
    setState(() {
      _currentStroke = null;
    });

    if (finalStroke.points.length > 1 || finalStroke.tool == DrawingTool.pen || finalStroke.tool == DrawingTool.highlighter) {
      ref.read(annotationNotifierProvider(_currentDocumentId).notifier).addAnnotation(
        page: page,
        type: finalStroke.tool == DrawingTool.highlighter ? 'highlighter' : 'pen',
        geometry: finalStroke.toJsonStr(),
      );
    }
  }

  void _onTapUp(TapUpDetails details, int page) {
    if (!_isDrawingMode) return;

    if (_currentTool == DrawingTool.sticky_note) {
      _showStickyNoteDialog(page, details.localPosition);
    } else if (_currentTool == DrawingTool.bookmark) {
      final pos = {'x': details.localPosition.dx, 'y': details.localPosition.dy};
      ref.read(annotationNotifierProvider(_currentDocumentId).notifier).addAnnotation(
        page: page,
        type: 'bookmark',
        geometry: jsonEncode(pos),
      );
    }
  }

  Future<void> _showStickyNoteDialog(int page, Offset position) async {
    final textController = TextEditingController();
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Sticky Note'),
        content: TextField(
          controller: textController,
          maxLines: 3,
          decoration: const InputDecoration(hintText: 'Type your note here...'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, textController.text),
            child: const Text('Save'),
          ),
        ],
      ),
    ).then((value) {
      if (value != null && (value as String).isNotEmpty) {
        final pos = {'x': position.dx, 'y': position.dy};
        ref.read(annotationNotifierProvider(_currentDocumentId).notifier).addAnnotation(
          page: page,
          type: 'sticky_note',
          geometry: jsonEncode(pos),
          content: value,
        );
      }
    });
  }

  // --- Voice / AI Handlers --- //
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

  Future<void> _processAnnotations() async {
    if (widget.filePath == null) return;
    
    // Show loading
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Burning PDF Annotations Locally...')),
    );

    // Get all annotations
    final allAnnsAsync = ref.read(annotationNotifierProvider(_currentDocumentId));
    if (allAnnsAsync is! AsyncData) return;
    
    final annotations = allAnnsAsync.value!;
    
    // Prepare List of Maps for annotations and page metrics
    final List<Map<String, dynamic>> annList = [];
    for (var ann in annotations) {
      if (ann.geometry != null) {
        annList.add({
          'page': ann.page,
          'type': ann.type,
          'geometry': ann.geometry,
        });
      }
    }
    
    // For simplicity we will assume standard A4 size or a generic 800x1200 for the frontend canvas
    final Map<String, dynamic> metrics = {};
    for (int i = 1; i <= 300; i++) {
      metrics[i.toString()] = {'width': 800, 'height': 1200}; // Fallback for flutter canvas mapping
    }

    final localPdfService = LocalPdfExportService();
    final success = await localPdfService.burnAnnotationsToPdf(
      pdfPath: widget.filePath!,
      annotations: annList,
      pageMetrics: metrics,
    );

    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Annotations burned to PDF successfully (100% Offline)!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to burn annotations.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final annotationsAsync = ref.watch(annotationNotifierProvider(_currentDocumentId));

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: const Text('Serious Study Workspace'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save_alt),
            tooltip: 'Process / Burn to PDF',
            onPressed: _processAnnotations,
          ),
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
      body: Stack(
        children: [
          PdfView(
            controller: _pdfController,
            scrollDirection: Axis.vertical,
            onPageChanged: (page) {
              setState(() => _currentPage = page);
            },
            physics: _isDrawingMode ? const NeverScrollableScrollPhysics() : null,
            builders: PdfViewBuilders<DefaultBuilderOptions>(
              options: const DefaultBuilderOptions(),
              pageBuilder: (context, Future<PdfPageImage> pageImage, int index, PdfDocument document) {
                final pageNumber = index + 1;
                return PhotoViewGalleryPageOptions.customChild(
                  disableGestures: _isDrawingMode,
                  child: FutureBuilder<PdfPageImage>(
                    future: pageImage,
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                      
                      final image = snapshot.data!;
                      
                      List<StudyAnnotation> pageAnnotations = [];
                      if (annotationsAsync is AsyncData) {
                        pageAnnotations = annotationsAsync.value!.where((a) => a.page == pageNumber).toList();
                      }

                      final strokes = pageAnnotations
                          .where((a) => a.type == 'pen' || a.type == 'highlighter')
                          .map((a) => Stroke.fromJsonStr(a.geometry!))
                          .toList();

                      return Stack(
                        children: [
                          Positioned.fill(
                            child: Image.memory(
                              image.bytes,
                              fit: BoxFit.contain,
                            ),
                          ),
                          // Saved Strokes
                          Positioned.fill(
                            child: CustomPaint(
                              painter: ScribblePainter(strokes, _currentPage == pageNumber ? _currentStroke : null),
                            ),
                          ),
                          // Sticky Notes & Bookmarks
                          for (final ann in pageAnnotations.where((a) => a.type == 'sticky_note' || a.type == 'bookmark'))
                            _buildAnnotationOverlay(ann),
                          
                          // Input Layer
                          if (_isDrawingMode)
                            Positioned.fill(
                              child: GestureDetector(
                                onPanStart: (d) => _onPanStart(d, pageNumber),
                                onPanUpdate: _onPanUpdate,
                                onPanEnd: (d) => _onPanEnd(d, pageNumber),
                                onTapUp: (d) => _onTapUp(d, pageNumber),
                                behavior: HitTestBehavior.translucent,
                                child: Container(color: Colors.transparent),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                );
              },
            ),
          ),
          
          if (_isDrawingMode)
            Positioned(
              bottom: 24,
              left: 0,
              right: 0,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_showBrushSettings) _buildBrushSettingsPanel(),
                    if (_showBrushSettings) const SizedBox(height: 12),
                    _buildGlassmorphicDock(),
                  ],
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

  Widget _buildGlassmorphicDock() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface.withOpacity(0.6),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: Colors.white.withOpacity(0.2), width: 1.5),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, spreadRadius: -5),
            ],
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.undo, size: 22),
                  tooltip: 'Undo',
                  onPressed: () => ref.read(annotationNotifierProvider(_currentDocumentId).notifier).undo(),
                ),
                IconButton(
                  icon: const Icon(Icons.redo, size: 22),
                  tooltip: 'Redo',
                  onPressed: () => ref.read(annotationNotifierProvider(_currentDocumentId).notifier).redo(),
                ),
                Container(width: 1, height: 24, color: Colors.grey.withOpacity(0.5), margin: const EdgeInsets.symmetric(horizontal: 4)),
                _buildToolButton(DrawingTool.pen, Icons.edit),
                _buildToolButton(DrawingTool.highlighter, Icons.brush),
                _buildToolButton(DrawingTool.eraser, Icons.phonelink_erase),
                IconButton(
                  icon: Icon(Icons.tune, color: _showBrushSettings ? Theme.of(context).colorScheme.primary : Colors.grey),
                  tooltip: 'Brush Settings',
                  onPressed: () => setState(() => _showBrushSettings = !_showBrushSettings),
                ),
                Container(width: 1, height: 24, color: Colors.grey.withOpacity(0.5), margin: const EdgeInsets.symmetric(horizontal: 4)),
                _buildToolButton(DrawingTool.sticky_note, Icons.sticky_note_2),
                _buildToolButton(DrawingTool.rectangle, Icons.crop_square),
                _buildToolButton(DrawingTool.line, Icons.horizontal_rule),
                Container(width: 1, height: 24, color: Colors.grey.withOpacity(0.5), margin: const EdgeInsets.symmetric(horizontal: 4)),
                _buildColorButton(Colors.black),
                _buildColorButton(Colors.redAccent),
                _buildColorButton(Colors.blueAccent),
                _buildColorButton(Colors.greenAccent),
                _buildColorButton(Colors.yellow),
                _buildColorButton(Colors.white),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBrushSettingsPanel() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          width: 300,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface.withOpacity(0.7),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Icon(Icons.line_weight, size: 20),
                  const SizedBox(width: 8),
                  const Text('Size'),
                  Expanded(
                    child: Slider(
                      value: _currentSize,
                      min: 1.0,
                      max: 30.0,
                      divisions: 29,
                      label: _currentSize.round().toString(),
                      onChanged: (val) => setState(() => _currentSize = val),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  const Icon(Icons.opacity, size: 20),
                  const SizedBox(width: 8),
                  const Text('Opacity'),
                  Expanded(
                    child: Slider(
                      value: _currentOpacity,
                      min: 0.1,
                      max: 1.0,
                      divisions: 9,
                      label: '${(_currentOpacity * 100).round()}%',
                      onChanged: (val) => setState(() => _currentOpacity = val),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnnotationOverlay(StudyAnnotation ann) {
    if (ann.geometry == null) return const SizedBox();
    final posMap = jsonDecode(ann.geometry!);
    final dx = posMap['x'] as double;
    final dy = posMap['y'] as double;

    return Positioned(
      left: dx - 16,
      top: dy - 16,
      child: GestureDetector(
        onTap: () {
          if (ann.type == 'sticky_note') {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Sticky Note'),
                content: Text(ann.content ?? ''),
                actions: [
                  TextButton(
                    onPressed: () {
                      ref.read(annotationNotifierProvider(_currentDocumentId).notifier).deleteAnnotation(ann.id);
                      Navigator.pop(context);
                    },
                    child: const Text('Delete', style: TextStyle(color: Colors.red)),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                ],
              ),
            );
          }
        },
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: ann.type == 'sticky_note' ? Colors.yellow : Colors.redAccent,
            shape: BoxShape.circle,
            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
          ),
          child: Icon(
            ann.type == 'sticky_note' ? Icons.sticky_note_2 : Icons.bookmark,
            size: 16,
            color: Colors.black87,
          ),
        ),
      ),
    );
  }

  Widget _buildColorButton(Color color) {
    final isSelected = _currentColor.value == color.value;
    return GestureDetector(
      onTap: () => setState(() => _currentColor = color),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(horizontal: 6),
        width: isSelected ? 28 : 24,
        height: isSelected ? 28 : 24,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey.withOpacity(0.3),
            width: isSelected ? 3 : 1,
          ),
          boxShadow: isSelected ? [BoxShadow(color: color.withOpacity(0.4), blurRadius: 8)] : [],
        ),
      ),
    );
  }

  Widget _buildToolButton(DrawingTool tool, IconData icon) {
    final isSelected = _currentTool == tool;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: isSelected ? Theme.of(context).colorScheme.primary.withOpacity(0.2) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: IconButton(
        icon: Icon(icon, color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey, size: 22),
        onPressed: () => setState(() {
          _currentTool = tool;
          if (tool == DrawingTool.highlighter) {
            _currentSize = 15.0; // Default thicker for highlighter
          }
        }),
      ),
    );
  }
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
        ..style = stroke.tool == DrawingTool.pen || stroke.tool == DrawingTool.eraser || stroke.tool == DrawingTool.highlighter
            ? PaintingStyle.fill 
            : PaintingStyle.stroke;
            
      if (stroke.tool == DrawingTool.eraser) {
        paint.blendMode = BlendMode.clear;
        paint.style = PaintingStyle.stroke;
      }

      final start = Offset(stroke.points.first.x, stroke.points.first.y);
      final end = Offset(stroke.points.last.x, stroke.points.last.y);

      if (stroke.tool == DrawingTool.pen || stroke.tool == DrawingTool.eraser || stroke.tool == DrawingTool.highlighter) {
        if (stroke.points.length == 1) {
          canvas.drawCircle(start, stroke.size / 2, paint);
        } else {
          final path = Path();
          
          // Majestic brush physics logic:
          // Pen gets dynamic thinning, Highlighter is a static thick marker.
          final StrokeOptions options;
          if (stroke.tool == DrawingTool.pen) {
            options = StrokeOptions(
              size: stroke.size, 
              thinning: 0.6, // Tapers nicely based on velocity
              smoothing: 0.8, // Super smooth curves
              streamline: 0.7, 
              simulatePressure: true,
            );
          } else if (stroke.tool == DrawingTool.eraser) {
             options = StrokeOptions(
              size: stroke.size * 2, 
              thinning: 0,
              smoothing: 0.5,
              streamline: 0.5,
              simulatePressure: false,
            );
          } else {
            // Highlighter
            options = StrokeOptions(
              size: stroke.size, 
              thinning: -0.1, // Slightly wider at edges
              smoothing: 0.5, 
              streamline: 0.5, 
              simulatePressure: false,
            );
          }

          final outlinePoints = getStroke(stroke.points, options: options);
          
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
  bool shouldRepaint(covariant ScribblePainter oldDelegate) => true;
}
