import 'package:flutter/material.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../screens/fullscreen_preview.dart';

/// Widget to display OBS livestream preview
/// Shows MJPEG stream from backend when OBS is connected
class VideoPreviewWidget extends StatefulWidget {
  final String baseUrl;
  final bool isOBSConnected;

  const VideoPreviewWidget({
    Key? key,
    required this.baseUrl,
    required this.isOBSConnected,
  }) : super(key: key);

  @override
  State<VideoPreviewWidget> createState() => _VideoPreviewWidgetState();
}

class _VideoPreviewWidgetState extends State<VideoPreviewWidget> {
  String? _errorMessage;
  bool _isLoading = true;
  String _quality = 'medium'; // low, medium, high
  bool _isRecording = false;
  Timer? _recordingCheckTimer;

  @override
  void initState() {
    super.initState();
    _checkStreamAvailability();
    _startRecordingCheck();
  }

  @override
  void didUpdateWidget(VideoPreviewWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isOBSConnected != widget.isOBSConnected) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
      _checkStreamAvailability();
      if (widget.isOBSConnected) {
        _startRecordingCheck();
      } else {
        _stopRecordingCheck();
      }
    }
  }

  @override
  void dispose() {
    _stopRecordingCheck();
    super.dispose();
  }

  void _startRecordingCheck() {
    _stopRecordingCheck();
    _checkRecordingStatus();
    _recordingCheckTimer = Timer.periodic(
      const Duration(seconds: 2),
      (_) => _checkRecordingStatus(),
    );
  }

  void _stopRecordingCheck() {
    _recordingCheckTimer?.cancel();
    _recordingCheckTimer = null;
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
      // Silently fail - recording indicator not critical
    }
  }

  Future<void> _checkStreamAvailability() async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _captureScreenshot() async {
    try {
      final response = await http.get(
        Uri.parse('http://127.0.0.1:8000/api/stream/snapshot'),
      );

      if (response.statusCode == 200) {
        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Screenshot captured!'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Screenshot failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _openFullscreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FullscreenPreview(
          baseUrl: widget.baseUrl,
          isOBSConnected: widget.isOBSConnected,
        ),
      ),
    );
  }

  String get _streamUrl {
    return '${widget.baseUrl}?quality=$_quality&adaptive=true';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: widget.isOBSConnected ? Colors.green : Colors.grey,
          width: 2,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: _buildContent(),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return _buildLoadingPlaceholder();
    }

    if (!widget.isOBSConnected) {
      return _buildNoOBSPlaceholder();
    }

    if (_errorMessage != null) {
      return _buildErrorPlaceholder();
    }

    // Display MJPEG stream
    return Stack(
      children: [
        Image.network(
          _streamUrl,
          fit: BoxFit.contain,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) {
              return child;
            }
            return _buildLoadingPlaceholder();
          },
          errorBuilder: (context, error, stackTrace) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() {
                  _errorMessage = error.toString();
                });
              }
            });
            return _buildErrorPlaceholder();
          },
        ),

        // Top bar with indicators
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
                  Colors.black.withOpacity(0.7),
                  Colors.transparent,
                ],
              ),
            ),
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Live badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                        'LIVE',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                // Recording indicator
                if (_isRecording)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
                            fontSize: 12,
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

        // Bottom controls
        Positioned(
          bottom: 12,
          left: 12,
          right: 12,
          child: Row(
            children: [
              // Stream analytics (left side)
              if (widget.isOBSConnected)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.speed, color: Colors.white, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        _quality == 'low'
                            ? '3 FPS'
                            : _quality == 'medium'
                                ? '5 FPS'
                                : '10 FPS',
                        style:
                            const TextStyle(color: Colors.white, fontSize: 11),
                      ),
                    ],
                  ),
                ),

              const Spacer(),

              // Fullscreen button
              IconButton(
                onPressed: _openFullscreen,
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.fullscreen,
                      color: Colors.white, size: 20),
                ),
              ),

              const SizedBox(width: 8),

              // Quality selector
              _buildQualityButton(),
              const SizedBox(width: 8),
              // Screenshot button
              _buildScreenshotButton(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQualityButton() {
    return PopupMenuButton<String>(
      initialValue: _quality,
      onSelected: (value) {
        setState(() {
          _quality = value;
        });
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

  Widget _buildScreenshotButton() {
    return IconButton(
      onPressed: _captureScreenshot,
      icon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.7),
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
      ),
    );
  }

  Widget _buildLoadingPlaceholder() {
    return Container(
      color: Colors.black,
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 16),
            Text(
              'Loading stream...',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoOBSPlaceholder() {
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.videocam_off,
              size: 64,
              color: Colors.grey[600],
            ),
            const SizedBox(height: 16),
            Text(
              'OBS Preview Not Available',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Launch OBS Studio to see preview',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorPlaceholder() {
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.orange[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Stream Error',
              style: TextStyle(
                color: Colors.orange[400],
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _errorMessage ?? 'Failed to load stream',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
