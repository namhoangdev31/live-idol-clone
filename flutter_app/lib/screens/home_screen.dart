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
              ],
            ),

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
                    '4. Open OBS and capture Unity window + virtual audio',
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
