import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';

class CaseManager {
  static final _storage = FlutterSecureStorage();
  static final _uuid = Uuid();

  /// Create a new unique case ID
  static Future<String> _generateCaseId() async {
    return _uuid.v4();
  }

  /// Save a completely new case
  static Future<String> saveCase(List<XFile> images) async {
    final caseId = await _generateCaseId();
    await _saveCaseImages(caseId, images);
    await _storage.write(key: 'case_$caseId', value: 'saved');
    debugPrint('✅ New case saved: $caseId');
    return caseId;
  }

  /// Update an existing case
  static Future<void> updateCase(String caseId, List<XFile> images) async {
    final directory = await getApplicationDocumentsDirectory();
    final caseDir = Directory('${directory.path}/cases/$caseId');

    // Ensure case directory exists
    if (!await caseDir.exists()) {
      await caseDir.create(recursive: true);
    }

    // Delete old images (optional: you could just overwrite)
    final existingFiles = caseDir.listSync();
    for (var file in existingFiles) {
      if (file is File && file.path.endsWith('.jpg')) {
        await file.delete();
      }
    }

    // Save updated images
    for (int i = 0; i < images.length; i++) {
      final imageFile = File(images[i].path);
      final fileName = 'image_$i.jpg';
      final newPath = '${caseDir.path}/$fileName';

      if (await imageFile.exists()) {
        await imageFile.copy(newPath);
      } else {
        debugPrint('! Warning: Source image not found: ${imageFile.path}');
      }
    }

    debugPrint('✅ Case updated: $caseId');
  }

  /// Save images under a specific caseId (used internally)
  static Future<void> _saveCaseImages(String caseId, List<XFile> images) async {
    final directory = await getApplicationDocumentsDirectory();
    final caseDir = Directory('${directory.path}/cases/$caseId');

    if (!await caseDir.exists()) {
      await caseDir.create(recursive: true);
    }

    for (int i = 0; i < images.length; i++) {
      final imageFile = File(images[i].path);
      final fileName = 'image_$i.jpg';
      final newPath = '${caseDir.path}/$fileName';

      if (await imageFile.exists()) {
        await imageFile.copy(newPath);
      } else {
        debugPrint('! Warning: Missing file: ${imageFile.path}');
      }
    }
  }

  /// Save patient info securely
  static Future<void> savePatientInfo(
    String caseId,
    Map<String, String> patientData,
  ) async {
    await _storage.write(key: 'patient_$caseId', value: patientData.toString());
    debugPrint('✅ Patient info saved for case: $caseId');
  }

  /// List all stored case IDs
  static Future<List<String>> listCases() async {
    final directory = await getApplicationDocumentsDirectory();
    final casesDir = Directory('${directory.path}/cases');

    if (!await casesDir.exists()) {
      return [];
    }

    final caseDirs = casesDir.listSync();
    return caseDirs
        .where((e) => e is Directory)
        .map((e) => e.path.split('/').last)
        .toList();
  }

  /// Get the directory for a specific case
  static Future<Directory?> getCaseDirectory(String caseId) async {
    final directory = await getApplicationDocumentsDirectory();
    final caseDir = Directory('${directory.path}/cases/$caseId');

    return caseDir.exists().then((exists) => exists ? caseDir : null);
  }

  /// Delete a case completely
  static Future<void> deleteCase(String caseId) async {
    final dir = await getCaseDirectory(caseId);
    if (dir != null && await dir.exists()) {
      await dir.delete(recursive: true);
      debugPrint('🗑️ Case deleted: $caseId');
    }
  }
}
