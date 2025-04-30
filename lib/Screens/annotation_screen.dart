import 'dart:io';
import 'dart:ui' as ui;
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:image_cropper/image_cropper.dart';

class AnnotationScreen extends StatefulWidget {
  final XFile imageFile;
  final Function(File newImage, {bool replace}) onSave;

  const AnnotationScreen({
    super.key,
    required this.imageFile,
    required this.onSave,
  });

  @override
  State<AnnotationScreen> createState() => _AnnotationScreenState();
}

enum ToolType { pen, circle, arrow, text, none }

class DrawAction {
  final ToolType type;
  List<Offset> points;
  final String? text;

  DrawAction({required this.type, required this.points, this.text});
}

class _AnnotationScreenState extends State<AnnotationScreen> {
  final List<DrawAction> _actions = [];
  ToolType _currentTool = ToolType.none;
  List<Offset> _currentPoints = [];
  final TextEditingController _textController = TextEditingController();
  bool _showTextField = false;
  Offset? _textPosition;
  late XFile _displayedFile;
  bool _isCropping = false;
  int? _selectedTextIndex;

  @override
  void initState() {
    super.initState();
    _displayedFile = widget.imageFile;
  }

  Future<void> _rotateImage() async {
    if (_isCropping) return;
    setState(() => _isCropping = true);

    try {
      final rotatedFile = await ImageCropper().cropImage(
        sourcePath: _displayedFile.path,
        compressFormat: ImageCompressFormat.png,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop & Rotate',
            toolbarColor: Colors.deepOrange,
            toolbarWidgetColor: Colors.white,
            lockAspectRatio: false,
            hideBottomControls: false,
            initAspectRatio: CropAspectRatioPreset.original,
            showCropGrid: true,
            cropGridRowCount: 3,
            cropGridColumnCount: 3,
          ),
          IOSUiSettings(title: 'Crop & Rotate'),
        ],
      );

      if (rotatedFile != null) {
        setState(() {
          _displayedFile = XFile(rotatedFile.path);
        });
      }
    } catch (e) {
      print('Rotation failed: $e');
    } finally {
      setState(() => _isCropping = false);
    }
  }

  Future<void> _smartCrop() async {
    // Simulated smart crop, real implementation would integrate ML.
    await _rotateImage();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Smart crop applied')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Annotate Image')),
      body: Column(
        children: [
          if (_showTextField && _textPosition != null)
            Padding(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).viewPadding.top + 8,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: TextField(
                        controller: _textController,
                        autofocus: true,
                        decoration: InputDecoration(
                          hintText: 'Enter label',
                          fillColor: Colors.white,
                          filled: true,
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.check),
                    onPressed: () {
                      setState(() {
                        _actions.add(
                          DrawAction(
                            type: ToolType.text,
                            points: [_textPosition!],
                            text: _textController.text,
                          ),
                        );
                        _textController.clear();
                        _showTextField = false;
                        _textPosition = null;
                        _currentTool = ToolType.none; // Deselect after adding
                      });
                    },
                  ),
                ],
              ),
            ),
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: Image.file(
                    File(_displayedFile.path),
                    fit: BoxFit.contain,
                  ),
                ),
                Positioned.fill(
                  child: GestureDetector(
                    onPanStart: _onPanStart,
                    onTapDown: (details) {
                      if (_currentTool == ToolType.text) {
                        setState(() {
                          _textPosition = details.localPosition;
                          _showTextField = true;
                        });
                      } else {
                        for (int i = 0; i < _actions.length; i++) {
                          final action = _actions[i];
                          if (action.type == ToolType.text &&
                              action.points.isNotEmpty) {
                            final tp = TextPainter(
                              text: TextSpan(
                                text: action.text,
                                style: TextStyle(fontSize: 18),
                              ),
                              textDirection: TextDirection.ltr,
                            );
                            tp.layout();
                            final bounds = Rect.fromLTWH(
                              action.points.first.dx,
                              action.points.first.dy,
                              tp.width + 8,
                              tp.height + 6,
                            );
                            if (bounds.contains(details.localPosition)) {
                              _selectedTextIndex = i;
                              return;
                            }
                          }
                        }
                        _selectedTextIndex = null;
                      }
                    },
                    onPanUpdate: (details) {
                      if (_selectedTextIndex != null) {
                        setState(() {
                          _actions[_selectedTextIndex!].points[0] +=
                              details.delta;
                        });
                      } else {
                        _onPanUpdate(details);
                      }
                    },
                    onPanEnd: (details) {
                      if (_selectedTextIndex != null) {
                        _selectedTextIndex = null;
                      } else {
                        _onPanEnd(details);
                      }
                    },
                    child: CustomPaint(
                      painter: _DrawingPainter(
                        _actions,
                        _currentPoints,
                        _currentTool,
                      ),
                      child: Container(),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Wrap(
            spacing: 8,
            children: [
              _buildToolButton(ToolType.pen, Icons.edit),
              _buildToolButton(ToolType.circle, Icons.circle_outlined),
              _buildToolButton(ToolType.arrow, Icons.arrow_forward),
              _buildToolButton(ToolType.text, Icons.text_fields),
              IconButton(
                icon: Icon(Icons.crop_rotate),
                onPressed: _isCropping ? null : _rotateImage,
              ),
              IconButton(
                icon: Icon(Icons.auto_fix_high),
                onPressed: _isCropping ? null : _smartCrop,
              ),
              IconButton(
                icon: Icon(Icons.undo),
                onPressed:
                    _actions.isNotEmpty
                        ? () => setState(() => _actions.removeLast())
                        : null,
              ),
              IconButton(
                icon: Icon(Icons.delete_forever),
                onPressed: () => setState(() => _actions.clear()),
              ),
              IconButton(
                icon: Icon(Icons.save),
                onPressed: _saveAnnotatedImage,
              ),
            ],
          ),
          SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildToolButton(ToolType tool, IconData icon) {
    return IconButton(
      icon: Icon(
        icon,
        color: _currentTool == tool ? Colors.blue : Colors.black,
      ),
      onPressed: () {
        setState(() {
          _currentTool = tool;
        });
      },
    );
  }

  void _onPanStart(DragStartDetails details) {
    if (_currentTool != ToolType.text) {
      setState(() => _currentPoints = [details.localPosition]);
    }
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_currentTool != ToolType.text) {
      setState(() => _currentPoints.add(details.localPosition));
    }
  }

  void _onPanEnd(DragEndDetails details) {
    if (_currentTool != ToolType.text && _currentPoints.isNotEmpty) {
      setState(() {
        _actions.add(
          DrawAction(type: _currentTool, points: List.from(_currentPoints)),
        );
        _currentPoints.clear();
      });
    }
  }

  Future<void> _saveAnnotatedImage() async {
    final imageFile = File(_displayedFile.path);
    final originalImage = await decodeImageFromList(
      await imageFile.readAsBytes(),
    );

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    final paint = Paint();
    canvas.drawImage(originalImage, Offset.zero, paint);

    final renderBox = context.findRenderObject() as RenderBox;
    final paintAreaSize = renderBox.size;

    final scaleX = originalImage.width / paintAreaSize.width;
    final scaleY = originalImage.height / paintAreaSize.height;
    canvas.scale(scaleX, scaleY);

    _DrawingPainter(_actions, [], _currentTool).paint(canvas, paintAreaSize);

    final picture = recorder.endRecording();
    final annotatedImage = await picture.toImage(
      originalImage.width,
      originalImage.height,
    );
    final byteData = await annotatedImage.toByteData(
      format: ui.ImageByteFormat.png,
    );

    final tempDir = await getTemporaryDirectory();
    final filePath = path.join(
      tempDir.path,
      'annotated_${DateTime.now().millisecondsSinceEpoch}.png',
    );
    final annotatedFile = File(filePath)
      ..writeAsBytesSync(byteData!.buffer.asUint8List());

    if (!mounted) return;
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Save Image'),
            content: const Text('Add to carousel or replace original?'),
            actions: [
              TextButton(
                child: const Text('Add New'),
                onPressed: () {
                  Navigator.pop(context); // close dialog
                  Navigator.of(
                    context,
                  ).pop({'file': annotatedFile, 'replace': false});
                },
              ),
              TextButton(
                child: const Text('Replace'),
                onPressed: () {
                  Navigator.pop(context); // close dialog
                  Navigator.of(
                    context,
                  ).pop({'file': annotatedFile, 'replace': true});
                },
              ),
            ],
          ),
    );
  }
}

class _DrawingPainter extends CustomPainter {
  final List<DrawAction> actions;
  final List<Offset> currentPoints;
  final ToolType tool;

  _DrawingPainter(this.actions, this.currentPoints, this.tool);

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = Colors.red
          ..strokeWidth = 3.0
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;

    for (final action in actions) {
      switch (action.type) {
        case ToolType.pen:
          _drawPath(canvas, paint, action.points);
          break;
        case ToolType.circle:
          if (action.points.length >= 2) {
            final rect = Rect.fromPoints(
              action.points.first,
              action.points.last,
            );
            canvas.drawOval(rect, paint);
          }
          break;
        case ToolType.arrow:
          if (action.points.length >= 2) {
            final p1 = action.points.first;
            final p2 = action.points.last;
            canvas.drawLine(p1, p2, paint);
            _drawArrowHead(canvas, p1, p2, paint);
          }
          break;
        case ToolType.text:
          final backgroundPaint =
              Paint()
                ..color = Colors.black.withOpacity(0.6)
                ..style = PaintingStyle.fill;

          final textSpan = TextSpan(
            text: action.text,
            style: TextStyle(color: Colors.white, fontSize: 20),
          );
          final tp = TextPainter(
            text: textSpan,
            textDirection: TextDirection.ltr,
          );
          tp.layout();
          final textOffset = action.points.first;

          final rect = Rect.fromLTWH(
            textOffset.dx,
            textOffset.dy,
            tp.width + 8,
            tp.height + 6,
          );
          canvas.drawRect(rect, backgroundPaint);
          tp.paint(canvas, Offset(textOffset.dx + 4, textOffset.dy + 3));
          break;
        case ToolType.none:
          break;
      }
    }

    if (tool == ToolType.pen) _drawPath(canvas, paint, currentPoints);
    if (tool == ToolType.circle && currentPoints.length >= 2) {
      final rect = Rect.fromPoints(currentPoints.first, currentPoints.last);
      canvas.drawOval(rect, paint);
    }
    if (tool == ToolType.arrow && currentPoints.length >= 2) {
      final p1 = currentPoints.first;
      final p2 = currentPoints.last;
      canvas.drawLine(p1, p2, paint);
      _drawArrowHead(canvas, p1, p2, paint);
    }
  }

  void _drawPath(Canvas canvas, Paint paint, List<Offset> points) {
    for (int i = 0; i < points.length - 1; i++) {
      canvas.drawLine(points[i], points[i + 1], paint);
    }
  }

  void _drawArrowHead(Canvas canvas, Offset p1, Offset p2, Paint paint) {
    final angle = (p2 - p1).direction;
    const size = 10.0;
    final path =
        Path()
          ..moveTo(p2.dx, p2.dy)
          ..lineTo(
            p2.dx - size * cos(angle - pi / 6),
            p2.dy - size * sin(angle - pi / 6),
          )
          ..lineTo(
            p2.dx - size * cos(angle + pi / 6),
            p2.dy - size * sin(angle + pi / 6),
          )
          ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
