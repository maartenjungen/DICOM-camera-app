import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../services/case_manager.dart';

class PatientInfoScreen extends StatefulWidget {
  final String caseId;
  final List<File> images;

  const PatientInfoScreen({
    Key? key,
    required this.caseId,
    required this.images,
  }) : super(key: key);

  @override
  _PatientInfoScreenState createState() => _PatientInfoScreenState();
}

class _PatientInfoScreenState extends State<PatientInfoScreen> {
  final _formKey = GlobalKey<FormState>();

  String _patientName = '';
  String _patientId = '';
  String _birthDate = '';
  String _gender = '';

  void _savePatientInfo() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final patientData = {
        'patientName': _patientName,
        'patientId': _patientId,
        'birthDate': _birthDate,
        'gender': _gender,
      };

      await CaseManager.savePatientInfo(widget.caseId, patientData);

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/stored_cases');
    }
  }

  void _scanQRCode() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('QR scanning not implemented yet')));
  }

  void _selectFromWorklist() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('MWL lookup not implemented yet')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Patient Info')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const Text(
                'Manual Entry',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Patient Name'),
                validator:
                    (value) =>
                        value == null || value.isEmpty
                            ? 'Please enter name'
                            : null,
                onSaved: (value) => _patientName = value!,
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Patient ID'),
                validator:
                    (value) =>
                        value == null || value.isEmpty
                            ? 'Please enter ID'
                            : null,
                onSaved: (value) => _patientId = value!,
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Birth Date (YYYY-MM-DD)',
                ),
                validator:
                    (value) =>
                        value == null || value.isEmpty
                            ? 'Please enter birth date'
                            : null,
                onSaved: (value) => _birthDate = value!,
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Gender'),
                validator:
                    (value) =>
                        value == null || value.isEmpty
                            ? 'Please enter gender'
                            : null,
                onSaved: (value) => _gender = value!,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _savePatientInfo,
                icon: const Icon(Icons.save),
                label: const Text('Save and Finish'),
              ),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 8),
              const Text(
                'Or use Quick Methods',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _scanQRCode,
                icon: const Icon(Icons.qr_code_scanner),
                label: const Text('Scan QR Code'),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _selectFromWorklist,
                icon: const Icon(Icons.list),
                label: const Text('Select from Worklist'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
