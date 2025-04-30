import 'package:dicom_camera_app/Screens/HomePage.dart';
import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: AuthGate(), // Acts as a gate to the app
      debugShowCheckedModeBanner: false,
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _isAuthenticating = true;
  bool _isAuthenticated = false;

  @override
  void initState() {
    super.initState();
    _authenticate();
  }

  Future<void> _authenticate() async {
    final auth = LocalAuthentication();
    try {
      bool success = await auth.authenticate(
        localizedReason: 'Please authenticate to use the app',
        options: const AuthenticationOptions(biometricOnly: true),
      );

      setState(() {
        _isAuthenticated = success;
        _isAuthenticating = false;
      });
    } catch (e) {
      print("Authentication error: $e");
      setState(() {
        _isAuthenticating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isAuthenticating) {
      return const Scaffold(body: Center(child: Text("Authenticating...")));
    }

    if (_isAuthenticated) {
      return const HomePage(); // Main app screen
    } else {
      return const Scaffold(body: Center(child: Text("Authentication failed")));
    }
  }
}
