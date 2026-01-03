import 'dart:async';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'api_client.dart';

/// Service for managing the Django backend lifecycle
class BackendService {
  Process? _backendProcess;
  final ApiClient _apiClient;
  Timer? _healthCheckTimer;
  bool _isRunning = false;

  BackendService({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  bool get isRunning => _isRunning;

  /// Start the Django backend process
  Future<bool> start() async {
    if (_isRunning) {
      print('Backend already running');
      return true;
    }

    try {
      // Get the backend executable path
      final backendPath = _getBackendExecutablePath();

      if (backendPath == null || !File(backendPath).existsSync()) {
        print('Backend executable not found at: $backendPath');
        return false;
      }

      print('Starting backend: $backendPath');

      // Start the backend process (detached)
      _backendProcess = await Process.start(
        backendPath,
        [],
        mode: ProcessStartMode.detached,
      );

      print('Backend process started with PID: ${_backendProcess?.pid}');

      // Wait a bit for the backend to initialize
      await Future.delayed(const Duration(seconds: 3));

      // Check if backend is responding
      final isHealthy = await _checkBackendHealth();
      if (isHealthy) {
        _isRunning = true;
        _startHealthCheckTimer();
        print('Backend is running and healthy');
        return true;
      } else {
        print('Backend started but not healthy yet, will retry...');
        _isRunning = true;
        _startHealthCheckTimer();
        return true; // Still return true as process started
      }
    } catch (e) {
      print('Failed to start backend: $e');
      return false;
    }
  }

  /// Get the path to the backend executable
  String? _getBackendExecutablePath() {
    // Get the directory where the Flutter app is running
    final executablePath = Platform.resolvedExecutable;
    final executableDir = path.dirname(executablePath);

    // In development, backend might be in ../backend/dist/
    // In production (installed), it should be in the same directory
    final candidates = [
      // Production path (installed with Inno Setup)
      path.join(executableDir, 'LiveIdolBackend.exe'),
      // Development path
      path.join(
        executableDir,
        '..',
        '..',
        'backend',
        'dist',
        'LiveIdolBackend.exe',
      ),
      path.join(
        executableDir,
        '..',
        '..',
        '..',
        '..',
        'backend',
        'dist',
        'LiveIdolBackend.exe',
      ),
    ];

    for (final candidate in candidates) {
      final normalized = path.normalize(candidate);
      if (File(normalized).existsSync()) {
        print('Found backend at: $normalized');
        return normalized;
      }
    }

    print('Backend not found. Searched:');
    for (final candidate in candidates) {
      print('  - ${path.normalize(candidate)}');
    }

    return null;
  }

  /// Check if backend is healthy
  Future<bool> _checkBackendHealth() async {
    try {
      final health = await _apiClient.checkHealth();
      return health.isHealthy;
    } catch (e) {
      return false;
    }
  }

  /// Start periodic health check timer
  void _startHealthCheckTimer() {
    _healthCheckTimer?.cancel();
    _healthCheckTimer = Timer.periodic(const Duration(seconds: 5), (
      timer,
    ) async {
      final isHealthy = await _checkBackendHealth();
      if (!isHealthy) {
        print('Backend health check failed');
        _isRunning = false;
        timer.cancel();
      }
    });
  }

  /// Stop the backend process
  Future<void> stop() async {
    print('Stopping backend...');
    _healthCheckTimer?.cancel();
    _backendProcess?.kill();
    _isRunning = false;
  }

  /// Get API client for making requests
  ApiClient get apiClient => _apiClient;

  void dispose() {
    stop();
    _apiClient.dispose();
  }
}
