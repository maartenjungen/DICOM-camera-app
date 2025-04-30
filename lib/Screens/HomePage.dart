import 'package:flutter/material.dart';
import 'package:dicom_camera_app/Screens/camerascreen.dart';
import 'package:dicom_camera_app/Screens/stored_cases_screen.dart'; // ✅ Add this import!

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final buttonStyle = ElevatedButton.styleFrom(
      foregroundColor: Colors.white,
      backgroundColor: Colors.blueGrey.shade800,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      textStyle: const TextStyle(fontSize: 18),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 5,
    );

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('DICOM Camera App'),
        backgroundColor: Colors.blueGrey.shade900,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                _buildOptionButton(
                  context,
                  icon: Icons.camera_alt,
                  label: 'Camera Only',
                  onTap:
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const CameraScreen()),
                      ),
                  style: buttonStyle,
                ),
                const SizedBox(height: 20),
                _buildOptionButton(
                  context,
                  icon: Icons.qr_code,
                  label: 'Camera + Patient Info',
                  onTap: () {
                    // To be implemented
                  },
                  style: buttonStyle,
                ),
                const SizedBox(height: 20),
                _buildOptionButton(
                  context,
                  icon: Icons.folder_open,
                  label: 'Saved Cases',
                  onTap:
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const StoredCasesScreen(),
                        ),
                      ), // ✅ Corrected here
                  style: buttonStyle,
                ),
                const SizedBox(height: 20),
                _buildOptionButton(
                  context,
                  icon: Icons.settings,
                  label: 'Settings',
                  onTap: () {
                    // To be implemented
                  },
                  style: buttonStyle,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOptionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required ButtonStyle style,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: Icon(icon, size: 26),
        label: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(label),
        ),
        style: style,
        onPressed: onTap,
      ),
    );
  }
}
