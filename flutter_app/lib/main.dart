import 'package:flutter/material.dart';
import 'services/backend_service.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const LiveIdolCloneApp());
}

class LiveIdolCloneApp extends StatelessWidget {
  const LiveIdolCloneApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Live Idol Clone',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.deepPurple, useMaterial3: true),
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final BackendService _backendService = BackendService();
  String _statusMessage = 'Initializing...';
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    setState(() {
      _statusMessage = 'Starting backend...';
      _hasError = false;
    });

    // Start the backend
    final started = await _backendService.start();

    if (started) {
      setState(() {
        _statusMessage = 'Backend started successfully!';
      });

      // Wait a moment to show success message
      await Future.delayed(const Duration(seconds: 1));

      // Navigate to home screen
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => HomeScreen(backendService: _backendService),
          ),
        );
      }
    } else {
      setState(() {
        _statusMessage = 'Failed to start backend. Please check installation.';
        _hasError = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.deepPurple,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App Icon/Logo
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.mic_external_on,
                size: 64,
                color: Colors.deepPurple,
              ),
            ),

            const SizedBox(height: 32),

            // App Title
            const Text(
              'Live Idol Clone',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'Voice Clone + VRM Avatar',
              style: TextStyle(fontSize: 16, color: Colors.white70),
            ),

            const SizedBox(height: 48),

            // Loading Indicator or Error
            if (!_hasError) ...[
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
              const SizedBox(height: 24),
            ],

            // Status Message
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _statusMessage,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: _hasError ? Colors.red[200] : Colors.white,
                ),
              ),
            ),

            if (_hasError) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _initializeApp,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.deepPurple,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    // Don't dispose backend service here as it's passed to HomeScreen
    super.dispose();
  }
}
