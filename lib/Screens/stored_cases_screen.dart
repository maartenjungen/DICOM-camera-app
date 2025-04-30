import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart'; // <<<<< ADD THIS!!!
import 'package:path_provider/path_provider.dart';
import '../services/case_manager.dart';
import 'package:dicom_camera_app/Screens/patient_info_screen.dart';
import 'package:dicom_camera_app/screens/homepage.dart';
import 'review_carousel_screen.dart';

class StoredCasesScreen extends StatefulWidget {
  const StoredCasesScreen({super.key});

  @override
  State<StoredCasesScreen> createState() => _StoredCasesScreenState();
}

class _StoredCasesScreenState extends State<StoredCasesScreen> {
  List<String> _caseIds = [];

  @override
  void initState() {
    super.initState();
    _loadCases();
  }

  Future<void> _loadCases() async {
    final cases = await CaseManager.listCases();
    setState(() {
      _caseIds = cases;
    });
  }

  Future<void> _deleteCase(String caseId) async {
    final dir = await CaseManager.getCaseDirectory(caseId);
    if (dir != null && await dir.exists()) {
      await dir.delete(recursive: true);
    }
    await _loadCases();
  }

  void _addPatientInfo(String caseId, List<File> images) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PatientInfoScreen(caseId: caseId, images: images),
      ),
    );
  }

  Future<List<File>> _getCaseImages(String caseId) async {
    final dir = await CaseManager.getCaseDirectory(caseId);
    if (dir == null || !(await dir.exists())) return [];
    final files = dir.listSync();
    return files
        .where(
          (f) =>
              f is File && (f.path.endsWith('.jpg') || f.path.endsWith('.png')),
        )
        .map((f) => File(f.path))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Stored Cases'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const HomePage()),
            );
          },
        ),
      ),
      body:
          _caseIds.isEmpty
              ? const Center(child: Text('No cases stored yet.'))
              : ListView.builder(
                itemCount: _caseIds.length,
                itemBuilder: (context, index) {
                  final caseId = _caseIds[index];
                  return FutureBuilder<List<File>>(
                    future: _getCaseImages(caseId),
                    builder: (context, snapshot) {
                      final images = snapshot.data ?? [];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Case: $caseId',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 8),
                              SizedBox(
                                height: 100,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: images.length,
                                  itemBuilder: (context, imgIndex) {
                                    return GestureDetector(
                                      onTap: () async {
                                        await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder:
                                                (_) => ReviewCarouselScreen(
                                                  caseId: caseId,
                                                  images: images,
                                                  onUpdate: (
                                                    index,
                                                    updatedFile, {
                                                    bool replace = true,
                                                  }) async {
                                                    final updatedImages =
                                                        List<File>.from(images);

                                                    if (replace) {
                                                      updatedImages[index] =
                                                          File(
                                                            updatedFile.path,
                                                          );
                                                    } else {
                                                      updatedImages.add(
                                                        File(updatedFile.path),
                                                      );
                                                    }

                                                    await CaseManager.updateCase(
                                                      caseId,
                                                      updatedImages
                                                          .map(
                                                            (file) => XFile(
                                                              file.path,
                                                            ),
                                                          )
                                                          .toList(),
                                                    );

                                                    setState(
                                                      () {},
                                                    ); // Refresh after update
                                                  },
                                                ),
                                          ),
                                        );

                                        setState(
                                          () {},
                                        ); // Also reload when returning
                                      },
                                      child: Container(
                                        margin: const EdgeInsets.only(right: 8),
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          color: Colors.white,
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black12,
                                              blurRadius: 4,
                                              offset: const Offset(2, 2),
                                            ),
                                          ],
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          child: Image.file(
                                            images[imgIndex],
                                            width: 100,
                                            height: 100,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  ElevatedButton.icon(
                                    icon: const Icon(Icons.person_add),
                                    label: const Text('Add Info'),
                                    onPressed:
                                        () => _addPatientInfo(caseId, images),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.deepOrange,
                                    ),
                                  ),
                                  ElevatedButton.icon(
                                    icon: const Icon(Icons.delete_forever),
                                    label: const Text('Delete'),
                                    onPressed: () => _deleteCase(caseId),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.redAccent,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
    );
  }
}
