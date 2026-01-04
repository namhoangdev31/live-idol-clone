import 'package:flutter/material.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';

/// Fullscreen video preview with zoom and controls
class FullscreenPreview extends StatefulWidget {
  final String baseUrl;
  final bool isOBSConnected;

  const FullscreenPreview({
    Key? key,
    required this.baseUrl,
    required this.isOBSConnected,
  }) : super(key: key);

  @override
  State<FullscreenPreview> createState() => _FullscreenPreviewState();
}

class _FullscreenPreviewState extends State<FullscreenPreview> {
  String _quality = 'high'; // Default to high quality in fullscreen
  bool _showControls = true;
  Timer? _hideControlsTimer;
  double _zoom = 1.0;
  bool _isRecording = false;
  Timer? _recordingCheckTimer;

  // Stream analytics
  int _fps = 0;
  double _bitrate = 0.0;
  Timer? _analyticsTimer;
  int _frameCount = 0;

  @override
  void initState() {
    super.initState();
    _startRecordingCheck();
    _startAnalytics();
    _resetHideControlsTimer();
  }

  @override
  void dispose() {
    _hideControlsTimer?.cancel();
    _recordingCheckTimer?.cancel();
    _analyticsTimer?.cancel();
    super.dispose();
  }

  void _resetHideControlsTimer() {
    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showControls = false;
        });
      }
    });
  }

  void _startRecordingCheck() {
    _checkRecordingStatus();
    _recordingCheckTimer = Timer.periodic(
      const Duration(seconds: 2),
      (_) => _checkRecordingStatus(),
    );
  }

  Future<void> _checkRecordingStatus() async {
    if (!widget.isOBSConnected) return;

    try {
      final response = await http
          .get(
            Uri.parse('http://127.0.0.1:8000/api/obs/recording-status'),
          )
          .timeout(const Duration(seconds: 2));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            _isRecording = data['recording'] ?? false;
          });
        }
      }
    } catch (e) {
      // Silently fail
    }
  }

  void _startAnalytics() {
    _analyticsTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _fps = _frameCount;
          _frameCount = 0;

          // Rough bitrate calculation based on quality
          if (_quality == 'low') {
            _bitrate = 0.5; // ~500 KB/s
          } else if (_quality == 'medium') {
            _bitrate = 1.5; // ~1.5 MB/s
          } else {
            _bitrate = 3.0; // ~3 MB/s
          }
        });
      }
    });
  }

  void _onFrameLoaded() {
    _frameCount++;
  }

  String get _streamUrl {
    return '${widget.baseUrl}?quality=$_quality&adaptive=false';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () {
          setState(() {
            _showControls = !_showControls;
          });
          if (_showControls) {
            _resetHideControlsTimer();
          }
        },
        child: Stack(
          children: [
            // Video Stream
            Center(
              child: Transform.scale(
                scale: _zoom,
                child: Image.network(
                  _streamUrl,
                  fit: BoxFit.contain,
                  frameBuilder:
                      (context, child, frame, wasSynchronouslyLoaded) {
                    if (frame != null) {
                      _onFrameLoaded();
                    }
                    return child;
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return const Center(
                      child: Icon(
                        Icons.error_outline,
                        color: Colors.white,
                        size: 64,
                      ),
                    );
                  },
                ),
              ),
            ),

            // Top Controls Overlay
            if (_showControls)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.8),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      // Exit button
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close, color: Colors.white),
                      ),

                      const Spacer(),

                      // Live badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'LIVE',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      const SizedBox(width: 12),

                      // Recording indicator
                      if (_isRecording)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                'REC',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),

            // Bottom Controls
            if (_showControls)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withOpacity(0.8),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      // Zoom controls
                      _buildZoomControls(),

                      const Spacer(),

                      // Stream analytics
                      _buildAnalytics(),

                      const SizedBox(width: 16),

                      // Quality selector
                      _buildQualitySelector(),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildZoomControls() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: () {
              setState(() {
                _zoom = (_zoom - 0.25).clamp(0.5, 3.0);
              });
              _resetHideControlsTimer();
            },
            icon: const Icon(Icons.zoom_out, color: Colors.white),
          ),
          Text(
            '${(_zoom * 100).toInt()}%',
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
          IconButton(
            onPressed: () {
              setState(() {
                _zoom = (_zoom + 0.25).clamp(0.5, 3.0);
              });
              _resetHideControlsTimer();
            },
            icon: const Icon(Icons.zoom_in, color: Colors.white),
          ),
          IconButton(
            onPressed: () {
              setState(() {
                _zoom = 1.0;
              });
              _resetHideControlsTimer();
            },
            icon: const Icon(Icons.fit_screen, color: Colors.white),
            tooltip: 'Reset Zoom',
          ),
        ],
      ),
    );
  }

  Widget _buildAnalytics() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.speed, color: Colors.white, size: 16),
          const SizedBox(width: 6),
          Text(
            '$_fps FPS',
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
          const SizedBox(width: 12),
          const Icon(Icons.network_check, color: Colors.white, size: 16),
          const SizedBox(width: 6),
          Text(
            '${_bitrate.toStringAsFixed(1)} MB/s',
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildQualitySelector() {
    return PopupMenuButton<String>(
      initialValue: _quality,
      onSelected: (value) {
        setState(() {
          _quality = value;
        });
        _resetHideControlsTimer();
      },
      icon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.7),
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Icon(Icons.settings, color: Colors.white, size: 20),
      ),
      itemBuilder: (context) => [
        const PopupMenuItem(value: 'low', child: Text('Low Quality')),
        const PopupMenuItem(value: 'medium', child: Text('Medium Quality')),
        const PopupMenuItem(value: 'high', child: Text('High Quality')),
      ],
    );
  }
}
