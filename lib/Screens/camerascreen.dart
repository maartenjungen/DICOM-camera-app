import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:path/path.dart' show join;
import 'package:path_provider/path_provider.dart';
import 'package:dicom_camera_app/Screens/review_carousel_screen.dart';
import 'package:uuid/uuid.dart'; // <-- ADD THIS

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  Future<void>? _initializeControllerFuture;
  List<XFile> _capturedImages = [];
  String? _caseId; // <-- ADD THIS

  double _currentZoom = 1.0;
  double _minZoom = 1.0;
  double _maxZoom = 4.0;
  bool _flashOn = false;

  Offset? _focusPoint;
  bool _showFocusCircle = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _generateNewCaseId(); // <-- Generate a case ID
  }

  Future<void> _generateNewCaseId() async {
    final uuid = Uuid();
    _caseId = uuid.v4();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      final backCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      final controller = CameraController(
        backCamera,
        ResolutionPreset.high,
        enableAudio: false,
      );

      _initializeControllerFuture = controller.initialize();
      await _initializeControllerFuture;

      final zoomRange = await controller.getMaxZoomLevel();
      final minZoom = await controller.getMinZoomLevel();

      setState(() {
        _controller = controller;
        _minZoom = minZoom;
        _maxZoom = zoomRange;
      });
    } catch (e) {
      print('Camera init error: $e');
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _takePicture() async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    if (_capturedImages.length >= 6) return;

    try {
      final tempDir = await getTemporaryDirectory();
      final filePath = join(tempDir.path, '${DateTime.now()}.jpg');

      final photo = await _controller!.takePicture();
      await photo.saveTo(filePath);

      setState(() {
        _capturedImages.add(XFile(filePath));
      });
    } catch (e) {
      print('Error taking picture: $e');
    }
  }

  void _toggleFlash() async {
    if (_controller == null) return;
    _flashOn = !_flashOn;
    await _controller!.setFlashMode(_flashOn ? FlashMode.torch : FlashMode.off);
    setState(() {});
  }

  void _onTapFocus(TapDownDetails details, BoxConstraints constraints) async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    final offset = Offset(
      details.localPosition.dx / constraints.maxWidth,
      details.localPosition.dy / constraints.maxHeight,
    );

    try {
      await _controller!.setFocusPoint(offset);
      await _controller!.setExposurePoint(offset);
      await _controller!.setFocusMode(FocusMode.auto);

      setState(() {
        _focusPoint = details.localPosition;
        _showFocusCircle = true;
      });

      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) setState(() => _showFocusCircle = false);
      });
    } catch (e) {
      print('Focus error: $e');
    }
  }

  void _goToReviewScreen() {
    if (_capturedImages.isEmpty || _caseId == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => ReviewCarouselScreen(
              caseId: _caseId!,
              images:
                  _capturedImages
                      .map((xfile) => File(xfile.path))
                      .toList(), // <-- FIXED
              initialIndex: 0,
              onUpdate: (index, newFile, {bool replace = true}) {
                setState(() {
                  if (replace) {
                    _capturedImages[index] = XFile(newFile.path);
                  } else {
                    _capturedImages.add(XFile(newFile.path));
                  }
                });
              },
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Capture Photo'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
      ),
      body:
          (_initializeControllerFuture == null)
              ? const Center(child: CircularProgressIndicator())
              : FutureBuilder(
                future: _initializeControllerFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.done &&
                      _controller != null) {
                    return LayoutBuilder(
                      builder: (context, constraints) {
                        return GestureDetector(
                          onTapDown:
                              (details) => _onTapFocus(details, constraints),
                          child: Stack(
                            children: [
                              CameraPreview(_controller!),
                              if (_showFocusCircle && _focusPoint != null)
                                Positioned(
                                  left: _focusPoint!.dx - 20,
                                  top: _focusPoint!.dy - 20,
                                  child: Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: Colors.cyanAccent,
                                        width: 2,
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                              Positioned(
                                bottom: 160,
                                left: 0,
                                right: 0,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12.0,
                                  ),
                                  child: Wrap(
                                    alignment: WrapAlignment.center,
                                    spacing: 8,
                                    runSpacing: 8,
                                    children:
                                        _capturedImages.asMap().entries.map((
                                          entry,
                                        ) {
                                          final img = entry.value;
                                          return GestureDetector(
                                            onTap: _goToReviewScreen,
                                            child: Image.file(
                                              File(img.path),
                                              width: 60,
                                              height: 60,
                                              fit: BoxFit.cover,
                                            ),
                                          );
                                        }).toList(),
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: 20,
                                left: 0,
                                right: 0,
                                child: Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceEvenly,
                                      children: [
                                        IconButton(
                                          icon: Icon(
                                            _flashOn
                                                ? Icons.flash_on
                                                : Icons.flash_off,
                                          ),
                                          onPressed: _toggleFlash,
                                          color: Colors.white,
                                        ),
                                        FloatingActionButton(
                                          onPressed:
                                              _capturedImages.length >= 6
                                                  ? null
                                                  : _takePicture,
                                          backgroundColor:
                                              _capturedImages.length >= 6
                                                  ? Colors.grey
                                                  : Colors.blueAccent,
                                          child: const Icon(Icons.camera_alt),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.check),
                                          onPressed: _goToReviewScreen,
                                          color: Colors.white,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        const Padding(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 16.0,
                                          ),
                                          child: Text(
                                            'Zoom',
                                            style: TextStyle(
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          child: Slider(
                                            value: _currentZoom,
                                            min: _minZoom,
                                            max: _maxZoom,
                                            activeColor: Colors.cyanAccent,
                                            onChanged: (value) async {
                                              await _controller!.setZoomLevel(
                                                value,
                                              );
                                              setState(() {
                                                _currentZoom = value;
                                              });
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  } else {
                    return const Center(child: CircularProgressIndicator());
                  }
                },
              ),
    );
  }
}
