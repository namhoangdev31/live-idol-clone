/// Response model for /api/speak endpoint
class SpeakResponse {
  final String? audioPath;
  final int durationMs;
  final int? generationTimeMs;
  final String voiceProfile;
  final String status;
  final String? error;

  SpeakResponse({
    this.audioPath,
    required this.durationMs,
    this.generationTimeMs,
    required this.voiceProfile,
    required this.status,
    this.error,
  });

  factory SpeakResponse.fromJson(Map<String, dynamic> json) {
    return SpeakResponse(
      audioPath: json['audio_path'],
      durationMs: json['duration_ms'] ?? 0,
      generationTimeMs: json['generation_time_ms'],
      voiceProfile: json['voice_profile'] ?? 'default',
      status: json['status'] ?? 'unknown',
      error: json['error'],
    );
  }

  bool get isSuccess => status == 'success' && audioPath != null;
}

/// Response model for /api/health endpoint
class HealthResponse {
  final String status;
  final bool ttsReady;
  final String? device;

  HealthResponse({required this.status, required this.ttsReady, this.device});

  factory HealthResponse.fromJson(Map<String, dynamic> json) {
    return HealthResponse(
      status: json['status'] ?? 'unknown',
      ttsReady: json['tts_ready'] ?? false,
      device: json['device'],
    );
  }

  bool get isHealthy => status == 'ok' && ttsReady;
}

/// Response model for /api/status endpoint
class SystemStatus {
  final bool ttsInitialized;
  final String device;
  final List<String> voiceProfiles;
  final String outputDirectory;
  final bool obsConnected;
  final int obsPort;
  final bool unityRunning;

  SystemStatus({
    required this.ttsInitialized,
    required this.device,
    required this.voiceProfiles,
    required this.outputDirectory,
    required this.obsConnected,
    required this.obsPort,
    required this.unityRunning,
  });

  factory SystemStatus.fromJson(Map<String, dynamic> json) {
    return SystemStatus(
      ttsInitialized: json['tts_initialized'] ?? false,
      device: json['device'] ?? 'unknown',
      voiceProfiles: List<String>.from(json['voice_profiles'] ?? []),
      outputDirectory: json['output_directory'] ?? '',
      obsConnected: json['obs_connected'] ?? false,
      obsPort: json['obs_port'] ?? 4455,
      unityRunning: json['unity_running'] ?? false,
    );
  }
}
