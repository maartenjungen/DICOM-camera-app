import 'dart:io';
import 'package:flutter/material.dart';

class CaseDetailScreen extends StatelessWidget {
  final Map<String, dynamic> caseData;

  const CaseDetailScreen({super.key, required this.caseData});

  @override
  Widget build(BuildContext context) {
    final List<String> imagePaths = List<String>.from(caseData['images'] ?? []);

    return Scaffold(
      appBar: AppBar(title: Text('Case: ${caseData['caseId']}')),
      body:
          imagePaths.isEmpty
              ? Center(child: Text('No images found in this case.'))
              : GridView.builder(
                padding: const EdgeInsets.all(8),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, // 2 images per row
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                ),
                itemCount: imagePaths.length,
                itemBuilder: (context, index) {
                  final imgPath = imagePaths[index];
                  return GestureDetector(
                    onTap: () {
                      _openImageFullScreen(context, imgPath);
                    },
                    child: Hero(
                      tag: imgPath,
                      child: Image.file(File(imgPath), fit: BoxFit.cover),
                    ),
                  );
                },
              ),
    );
  }

  void _openImageFullScreen(BuildContext context, String imagePath) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FullScreenImageView(imagePath: imagePath),
      ),
    );
  }
}

class FullScreenImageView extends StatelessWidget {
  final String imagePath;

  const FullScreenImageView({super.key, required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Center(
          child: Hero(tag: imagePath, child: Image.file(File(imagePath))),
        ),
      ),
    );
  }
}
