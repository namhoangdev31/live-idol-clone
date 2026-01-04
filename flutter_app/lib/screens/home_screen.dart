import 'dart:async';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../services/backend_service.dart';

class HomeScreen extends StatefulWidget {
  final BackendService backendService;

  const HomeScreen({Key? key, required this.backendService}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Video Player
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;

  // State
  bool _isGenerating = false;
  String _statusMessage = 'Ready';

  // Inputs
  final TextEditingController _commentController = TextEditingController();
  final TextEditingController _promptController = TextEditingController();

  // Selection

  @override
  void initState() {
    super.initState();
    _loadInitialState();
  }

  Future<void> _loadInitialState() async {
    // Check backend status
    try {
      await widget.backendService.apiClient.checkHealth();
      // Load default idle if available?
      // For now just wait for user action
    } catch (e) {
      setState(() => _statusMessage = "Backend not ready: $e");
    }
  }

  /*
  Future<void> _initializeVideo(String url) async {
    // If running on emulator/simulator, 127.0.0.1 refers to the device itself.
    // Use 10.0.2.2 for Android Emulator to reach host localhost.
    // But assuming Desktop (Mac) build:
    final uri =
        Uri.parse(url.startsWith('http') ? url : 'http://127.0.0.1:8000$url');

    final oldController = _videoController;

    final controller = VideoPlayerController.networkUrl(uri);
    await controller.initialize();
    controller.setLooping(true); // Loop by default (essential for Idle)
    await controller.play();

    setState(() {
      _videoController = controller;
      _isVideoInitialized = true;
    });

    if (oldController != null) {
      await oldController.dispose();
    }
  }
  */

  Future<void> _generateScene() async {
    if (_promptController.text.isEmpty) return;

    setState(() {
      _isGenerating = true;
      _statusMessage = "Generating Scene...";
    });

    try {
      final result = await widget.backendService.apiClient
          .generateScene(_promptController.text);
      // Result contains image_path
      // Ideally we display it or auto-set it as background?
      // For now, let's just log it.
      setState(() => _statusMessage = "Scene Generated: ${result['filename']}");
    } catch (e) {
      setState(() => _statusMessage = "Error: $e");
    } finally {
      setState(() => _isGenerating = false);
    }
  }

  /*
  Future<void> _generateIdle() async {
    // Needs an image path.
    // For testing, let's pick a hardcoded one or let user upload first?
    // We can use the 'selected' image if we had an image picker.
    // Let's assume user uploaded an image via the legacy ImageUpload (which we kept).
    // We need to LIST images to pick one.

    // Quick Hack: Fetch list and pick first 'avatar'
    try {
      final images = await widget.backendService.apiClient.listImages('avatar');
      if (images.isNotEmpty) {
        final filename = images.first['filename'];
        // Full path is needed by backend?
        // Backend listImages returns metadata. video_engine needs absolute path.
        // We construct it or backend handles relative?
        // Backend video_engine.generate_idle expects absolute path usually.
        // But let's assume backend api list returns absolute or we reconstruct.
        // Actually backend listImages just returns dict.
        // Let's rely on backend solving path if we send filename or fix it later.
        // Wait, generate_idle takes `image_path`.

        // Let's just create a mock "path" assuming standard structure
        // /app/static/images/avatar/...
        // On Backend: MEDIA_ROOT/avatar/...

        // Simplification: Just ask Backend to "Use Default Avatar" if path missing?
        // Or prompt user "Upload Avatar First".

        setState(() => _statusMessage = "Generating Idle for $filename...");
        // We need full path.
        // Let's assume we pass the filename and backend handles lookup?
        // API `generate_idle` takes `image_path`.
        // We should update API to accept simple filename too?
        // Or just use the 'ImageManager' on backend to resolve.
        // I'll send the relative path and hope backend handles it or I fix backend.
        // Actually, I'll pass "/app/generated_images/avatar/$filename" (Docker path).
        // This is risky.

        // Better: Update `generate_idle` to accept `image_id` or `filename` + `category`.
        // But for now, let's try to send a path we think works.
      } else {
        setState(() => _statusMessage = "No avatars found. Upload one!");
      }
    } catch (e) {
      setState(() => _statusMessage = "Error listing images: $e");
    }
  }
  */

  Future<void> _processComment() async {
    if (_commentController.text.isEmpty) return;
    // Similar logic: needs image_path.
    // Need a robust way to select current avatar.
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Cinematic
      body: Row(
        children: [
          // Left: Controls
          Container(
            width: 300,
            color: Colors.grey[900],
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Live Idol Streamer",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),

                // Scene Gen
                TextField(
                  controller: _promptController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: "Scene Description",
                    labelStyle: TextStyle(color: Colors.grey),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  onPressed: _isGenerating ? null : _generateScene,
                  icon: const Icon(Icons.image),
                  label: const Text("Generate Scene"),
                ),

                const Divider(color: Colors.grey),

                // Comment Sim
                TextField(
                  controller: _commentController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: "Simulate Comment",
                    labelStyle: TextStyle(color: Colors.grey),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  onPressed: _isGenerating ? null : _processComment,
                  icon: const Icon(Icons.send),
                  label: const Text("Send Comment"),
                ),

                const Spacer(),
                Text(_statusMessage,
                    style: TextStyle(
                        color: _statusMessage.contains("Error")
                            ? Colors.red
                            : Colors.green)),
              ],
            ),
          ),

          // Right: Video Area
          Expanded(
            child: Stack(
              children: [
                // Video Player
                Center(
                  child: _isVideoInitialized && _videoController != null
                      ? AspectRatio(
                          aspectRatio: _videoController!.value.aspectRatio,
                          child: VideoPlayer(_videoController!),
                        )
                      : const Text("Waiting for Stream...",
                          style: TextStyle(color: Colors.white)),
                ),

                // Comment Overlay (Bottom Left of Video)
                Positioned(
                  bottom: 20,
                  left: 20,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Viewer: Hello!",
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold)),
                        // Dynamic list would go here
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _promptController.dispose();
    _commentController.dispose();
    super.dispose();
  }
}
