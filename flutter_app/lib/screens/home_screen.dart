import 'package:flutter/material.dart';
import '../services/backend_service.dart';
import '../models/api_models.dart';
import '../widgets/status_indicator.dart';

class HomeScreen extends StatefulWidget {
  final BackendService backendService;

  const HomeScreen({Key? key, required this.backendService}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _textController = TextEditingController();
  bool _isGenerating = false;
  String? _statusMessage;
  SpeakResponse? _lastResponse;
  SystemStatus? _systemStatus;

  @override
  void initState() {
    super.initState();
    _loadSystemStatus();
  }

  Future<void> _loadSystemStatus() async {
    try {
      final status = await widget.backendService.apiClient.getStatus();
      setState(() {
        _systemStatus = status;
      });

      // Auto-launch logic if backend is ready but services are down
      // Use a flag to ensure we only try auto-launch once per session if needed
      if (status.ttsInitialized) {
        // Auto-launch Unity if not running
        if (!status.unityRunning) {
          _launchUnity();
        }

        // Auto-launch OBS if not connected and we haven't tried connecting yet
        // Note: OBS launch check is tricky as we rely on WebSocket connection status
        // Check local variable first to avoid loops
        if (!status.obsConnected) {
          // We'll rely on user for OBS for now to avoid loops, or just try once
          // Un-comment below to auto-launch OBS
          // _launchObs();
        }
      }
    } catch (e) {
      print('Failed to load system status: $e');
    }
  }

  Future<void> _onSpeak() async {
    final text = _textController.text.trim();

    if (text.isEmpty) {
      setState(() {
        _statusMessage = 'Please enter some text';
      });
      return;
    }

    setState(() {
      _isGenerating = true;
      _statusMessage = 'Generating speech...';
      _lastResponse = null;
    });

    try {
      final response = await widget.backendService.apiClient.speak(
        text: text,
        voiceProfile: 'default',
        language: 'en',
      );

      setState(() {
        _isGenerating = false;
        _lastResponse = response;

        if (response.isSuccess) {
          _statusMessage =
              'Speech generated successfully! Duration: ${response.durationMs}ms';
        } else {
          _statusMessage = 'Error: ${response.error ?? "Unknown error"}';
        }
      });
    } catch (e) {
      setState(() {
        _isGenerating = false;
        _statusMessage = 'Error: $e';
      });
    }
  }

  Future<void> _launchUnity() async {
    setState(() {
      _statusMessage = 'Launching Unity Renderer...';
    });
    final result = await widget.backendService.apiClient.launchUnity();
    if (result['status'] == 'launched' ||
        result['status'] == 'already_running') {
      setState(() {
        _statusMessage = result['message'];
      });
      _loadSystemStatus();
    } else {
      setState(() {
        _statusMessage = 'Error launching Unity: ${result['error']}';
      });
    }
  }

  Future<void> _launchObs() async {
    setState(() {
      _statusMessage = 'Launching OBS Studio...';
    });
    final result = await widget.backendService.apiClient.launchObs();
    if (result['status'] == 'launched' ||
        result['status'] == 'already_running') {
      setState(() {
        _statusMessage = result['message'];
      });
      // Try to connect to OBS WebSocket after a short delay
      await Future.delayed(const Duration(seconds: 5));
      _connectObs();
    } else {
      setState(() {
        _statusMessage = 'Error launching OBS: ${result['error']}';
      });
    }
  }

  Future<void> _connectObs() async {
    setState(() {
      _statusMessage = 'Connecting to OBS...';
    });

    try {
      final success = await widget.backendService.apiClient.connectObs();
      if (success) {
        setState(() {
          _statusMessage = 'Connected to OBS!';
        });
        _loadSystemStatus(); // Refresh status
      } else {
        setState(() {
          _statusMessage = 'Failed to connect to OBS. Is it running?';
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Error connecting to OBS: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Idol Clone'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status Indicators
            Row(
              children: [
                Expanded(
                  child: StatusIndicator(
                    label: 'Backend',
                    isActive: widget.backendService.isRunning,
                    message: widget.backendService.isRunning
                        ? 'Running on port 8000'
                        : 'Not running',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: StatusIndicator(
                    label: 'TTS Engine',
                    isActive: _systemStatus?.ttsInitialized ?? false,
                    message: _systemStatus?.device ?? 'Unknown',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: StatusIndicator(
                    label: 'OBS Link',
                    isActive: _systemStatus?.obsConnected ?? false,
                    message: _systemStatus?.obsConnected == true
                        ? 'Connected'
                        : 'Disconnected',
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Control Buttons (Unity & OBS)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _launchUnity,
                    icon: Icon(
                      Icons.videogame_asset,
                      color: (_systemStatus?.unityRunning ?? false)
                          ? Colors.green
                          : Colors.purple,
                    ),
                    label: Text(
                      (_systemStatus?.unityRunning ?? false)
                          ? 'Unity Running'
                          : 'Launch Unity',
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: (_systemStatus?.unityRunning ?? false)
                          ? Colors.green
                          : Colors.deepPurple,
                      side: BorderSide(
                        color: (_systemStatus?.unityRunning ?? false)
                            ? Colors.green
                            : Colors.deepPurple,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: (_systemStatus?.obsConnected ?? false)
                        ? null
                        : _launchObs,
                    icon: Icon(
                      Icons.camera,
                      color: (_systemStatus?.obsConnected ?? false)
                          ? Colors.green
                          : Colors.orange,
                    ),
                    label: Text(
                      (_systemStatus?.obsConnected ?? false)
                          ? 'OBS Running'
                          : 'Launch OBS',
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: (_systemStatus?.obsConnected ?? false)
                          ? Colors.green
                          : Colors.orange,
                      side: BorderSide(
                        color: (_systemStatus?.obsConnected ?? false)
                            ? Colors.green
                            : Colors.orange,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            if (_systemStatus != null && !_systemStatus!.obsConnected) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _connectObs,
                icon: const Icon(Icons.link),
                label: const Text('Connect to OBS WebSocket (Manual)'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.grey,
                  side: const BorderSide(color: Colors.grey),
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Voice Profile Info
            if (_systemStatus != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.person, color: Colors.blue),
                    const SizedBox(width: 8),
                    Text(
                      'Voice Profiles: ${_systemStatus!.voiceProfiles.isEmpty ? "None (using default)" : _systemStatus!.voiceProfiles.join(", ")}',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Text Input
            const Text(
              'Enter text to speak:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _textController,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: 'Hello, welcome to our livestream!',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
            ),

            const SizedBox(height: 24),

            // Speak Button
            ElevatedButton.icon(
              onPressed: _isGenerating || !widget.backendService.isRunning
                  ? null
                  : _onSpeak,
              icon: _isGenerating
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.mic),
              label: Text(
                _isGenerating ? 'Generating...' : 'Speak',
                style: const TextStyle(fontSize: 18),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Status Message
            if (_statusMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _lastResponse?.isSuccess ?? false
                      ? Colors.green[50]
                      : Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _lastResponse?.isSuccess ?? false
                        ? Colors.green
                        : Colors.orange,
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _lastResponse?.isSuccess ?? false
                              ? Icons.check_circle
                              : Icons.info,
                          color: _lastResponse?.isSuccess ?? false
                              ? Colors.green
                              : Colors.orange,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _statusMessage!,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    if (_lastResponse != null &&
                        _lastResponse!.generationTimeMs != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Generation time: ${_lastResponse!.generationTimeMs}ms',
                        style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                      ),
                    ],
                  ],
                ),
              ),
            ],

            const Spacer(),

            // Instructions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Instructions:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  _buildInstruction(
                    '1. Ensure backend is running (green status)',
                  ),
                  _buildInstruction('2. Type your text in the input field'),
                  _buildInstruction('3. Click "Speak" to generate audio'),
                  _buildInstruction(
                    '4. Ensure OBS is running with WebSocket enabled (Port 4455)',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstruction(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(Icons.arrow_right, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 12, color: Colors.grey[700]),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }
}
