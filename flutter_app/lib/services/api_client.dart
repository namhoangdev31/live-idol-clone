import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/api_models.dart';

/// HTTP client for communicating with Django backend API
class ApiClient {
  final String baseUrl;
  final http.Client _client;

  ApiClient({this.baseUrl = 'http://127.0.0.1:8000/api', http.Client? client})
    : _client = client ?? http.Client();

  /// Check backend health
  Future<HealthResponse> checkHealth() async {
    try {
      final response = await _client
          .get(Uri.parse('$baseUrl/health'))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return HealthResponse.fromJson(json);
      } else {
        throw Exception('Health check failed: ${response.statusCode}');
      }
    } on TimeoutException {
      throw Exception('Health check timed out');
    } on SocketException {
      throw Exception('Cannot connect to backend');
    } catch (e) {
      throw Exception('Health check error: $e');
    }
  }

  /// Get system status
  Future<SystemStatus> getStatus() async {
    try {
      final response = await _client
          .get(Uri.parse('$baseUrl/status'))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return SystemStatus.fromJson(json);
      } else {
        throw Exception('Status check failed: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Status check error: $e');
    }
  }

  /// Generate speech from text
  Future<SpeakResponse> speak({
    required String text,
    String voiceProfile = 'default',
    String language = 'en',
  }) async {
    try {
      final response = await _client
          .post(
            Uri.parse('$baseUrl/speak'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'text': text,
              'voice_profile': voiceProfile,
              'language': language,
            }),
          )
          .timeout(const Duration(seconds: 30));

      final json = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return SpeakResponse.fromJson(json);
      } else {
        // Error response
        return SpeakResponse(
          audioPath: null,
          durationMs: 0,
          voiceProfile: voiceProfile,
          status: 'error',
          error: json['error'] ?? 'Unknown error',
        );
      }
    } on TimeoutException {
      return SpeakResponse(
        audioPath: null,
        durationMs: 0,
        voiceProfile: voiceProfile,
        status: 'error',
        error: 'Request timed out',
      );
    } catch (e) {
      return SpeakResponse(
        audioPath: null,
        durationMs: 0,
        voiceProfile: voiceProfile,
        status: 'error',
        error: e.toString(),
      );
    }
  }

  /// Get list of available voice profiles
  Future<List<String>> getVoiceProfiles() async {
    try {
      final response = await _client
          .get(Uri.parse('$baseUrl/voice-profiles'))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return List<String>.from(json['profiles'] ?? []);
      } else {
        throw Exception('Failed to get voice profiles');
      }
    } catch (e) {
      throw Exception('Voice profiles error: $e');
    }
  }

  /// Attempt to connect to OBS
  Future<bool> connectObs() async {
    try {
      final response = await _client
          .post(Uri.parse('$baseUrl/obs/connect'))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  /// Launch Unity Renderer
  Future<Map<String, dynamic>> launchUnity() async {
    try {
      final response = await _client
          .post(Uri.parse('$baseUrl/unity/launch'))
          .timeout(const Duration(seconds: 10));

      return jsonDecode(response.body);
    } catch (e) {
      return {'status': 'failed', 'error': 'Connection error: $e'};
    }
  }

  /// Launch OBS Studio
  Future<Map<String, dynamic>> launchObs() async {
    try {
      final response = await _client
          .post(Uri.parse('$baseUrl/obs/launch'))
          .timeout(const Duration(seconds: 10));

      return jsonDecode(response.body);
    } catch (e) {
      return {'status': 'failed', 'error': 'Connection error: $e'};
    }
  }

  void dispose() {
    _client.close();
  }
}
