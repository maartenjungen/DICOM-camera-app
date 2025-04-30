// review_carousel_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:dicom_camera_app/Screens/annotation_screen.dart';
import '../services/case_manager.dart';
import 'stored_cases_screen.dart';
import 'patient_info_screen.dart';

class ReviewCarouselScreen extends StatefulWidget {
  final String caseId;
  final List<File> images;
  final int initialIndex;
  final Function(int, XFile, {bool replace}) onUpdate;

  const ReviewCarouselScreen({
    Key? key,
    required this.caseId,
    required this.images,
    this.initialIndex = 0,
    required this.onUpdate,
  }) : super(key: key);

  @override
  _ReviewCarouselScreenState createState() => _ReviewCarouselScreenState();
}

class _ReviewCarouselScreenState extends State<ReviewCarouselScreen> {
  late int _currentIndex;
  late List<XFile> _images;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _images = widget.images.map((file) => XFile(file.path)).toList();
  }

  void _cropImage() async {
    final croppedFile = await ImageCropper().cropImage(
      sourcePath: _images[_currentIndex].path,
      compressFormat: ImageCompressFormat.png,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Crop & Rotate',
          toolbarColor: Colors.deepOrange,
          toolbarWidgetColor: Colors.white,
          lockAspectRatio: false,
          initAspectRatio: CropAspectRatioPreset.original,
        ),
        IOSUiSettings(title: 'Crop & Rotate'),
      ],
    );

    if (croppedFile != null) {
      setState(() {
        _images[_currentIndex] = XFile(croppedFile.path);
      });
    }
  }

  void _annotateImage() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => AnnotationScreen(
              imageFile: _images[_currentIndex],
              onSave: (editedFile, {bool replace = true}) {},
            ),
      ),
    );

    if (result != null && result is Map) {
      final File editedFile = result['file'];
      final bool replace = result['replace'];

      setState(() {
        if (replace) {
          _images[_currentIndex] = XFile(editedFile.path);
        } else {
          _images.add(XFile(editedFile.path));
          _currentIndex = _images.length - 1;
        }
      });
    }
  }

  Future<void> _saveCase({required bool addPatientInfo}) async {
    final caseDir = await CaseManager.getCaseDirectory(widget.caseId);
    String caseIdToUse = widget.caseId;

    if (caseDir == null) {
      caseIdToUse = await CaseManager.saveCase(_images);
      debugPrint('✅ Created new case: $caseIdToUse');
    } else {
      await CaseManager.updateCase(caseIdToUse, _images);
      debugPrint('✅ Updated existing case: $caseIdToUse');
    }

    if (!mounted) return;

    if (addPatientInfo) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder:
              (_) => PatientInfoScreen(
                caseId: caseIdToUse,
                images: _images.map((xfile) => File(xfile.path)).toList(),
              ),
        ),
      );
    } else {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const StoredCasesScreen()),
        (route) => false,
      );
    }
  }

  void _showSaveOptionsDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Save Case'),
            content: const Text('How would you like to save this case?'),
            actions: [
              TextButton(
                child: const Text('Save without Patient Info'),
                onPressed: () async {
                  Navigator.pop(context);
                  await _saveCase(addPatientInfo: false);
                },
              ),
              TextButton(
                child: const Text('Add Patient Info'),
                onPressed: () async {
                  Navigator.pop(context);
                  await _saveCase(addPatientInfo: true);
                },
              ),
            ],
          ),
    );
  }

  void _goToNext() {
    if (_currentIndex < _images.length - 1) {
      setState(() {
        _currentIndex++;
      });
    }
  }

  void _goToPrevious() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
      });
    }
  }

  void _finishReview() {
    _showSaveOptionsDialog();
  }

  @override
  Widget build(BuildContext context) {
    final image = File(_images[_currentIndex].path);
    return Scaffold(
      appBar: AppBar(
        title: Text('Review Images (${_currentIndex + 1}/${_images.length})'),
      ),
      body: Column(
        children: [
          Expanded(child: Center(child: Image.file(image))),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _goToPrevious,
              ),
              IconButton(icon: const Icon(Icons.crop), onPressed: _cropImage),
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: _annotateImage,
              ),
              IconButton(
                icon: const Icon(Icons.arrow_forward),
                onPressed: _goToNext,
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton.icon(
              onPressed: _finishReview,
              icon: const Icon(Icons.check),
              label: const Text('Next'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
