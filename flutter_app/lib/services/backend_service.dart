import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:path/path.dart' as path;
import 'package:web_socket_channel/web_socket_channel.dart';
import 'api_client.dart';

/// Service for managing the Django backend lifecycle
class BackendService {
  Process? _backendProcess;
  final ApiClient _apiClient;
  Timer? _healthCheckTimer;
  bool _isRunning = false;

  // WebSocket Status
  WebSocketChannel? _statusChannel;
  final _statusController = StreamController<String>.broadcast();
  Stream<String> get statusStream => _statusController.stream;

  BackendService({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  bool get isRunning => _isRunning;

  /// Connect to WebSocket Status Server
  void _connectStatusWebSocket() {
    try {
      print('Connecting to Status WebSocket...');
      _statusChannel = WebSocketChannel.connect(
        Uri.parse('ws://127.0.0.1:8001'),
      );

      _statusChannel!.stream.listen(
        (message) {
          try {
            final data = jsonDecode(message);
            if (data['type'] == 'status') {
              final status = data['status']; // 'initializing' or 'ready'
              _statusController.add(status);
              if (status == 'ready') {
                _isRunning = true;
              }
            }
          } catch (e) {
            print('WS Parse Error: $e');
          }
        },
        onError: (error) {
          print('WS Error: $error');
          _statusController.add('disconnected');
          _retryWebSocket();
        },
        onDone: () {
          print('WS Closed');
          _statusController.add('disconnected');
          _retryWebSocket();
        },
      );
    } catch (e) {
      print('WS Connect Failed: $e');
      _retryWebSocket();
    }
  }

  void _retryWebSocket() {
    Future.delayed(const Duration(seconds: 2), () {
      if (_isRunning || _backendProcess != null) {
        _connectStatusWebSocket();
      }
    });
  }

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

      // Start WebSocket connection attempts immediately
      _connectStatusWebSocket();

      // Legacy Polling Fallback (Keep for HTTP health)
      _startHealthCheckTimer();

      return true;
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
      path.join(executableDir, 'backend', 'LiveIdolBackend.exe'),
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
      // Keep legacy HTTP check for API readiness
      final isHealthy = await _checkBackendHealth();
      if (isHealthy) {
        _isRunning = true;
        // Note: WebSocket stream updates are handled separately
      }
    });
  }

  /// Stop the backend process
  Future<void> stop() async {
    print('Stopping backend...');
    _healthCheckTimer?.cancel();
    _statusChannel?.sink.close();
    _statusController.close();
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
