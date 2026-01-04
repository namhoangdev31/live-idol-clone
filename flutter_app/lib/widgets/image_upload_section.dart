import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:http/http.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:cross_file/cross_file.dart';
import '../services/backend_service.dart';

/// Widget for uploading images (avatar/background/overlay)
class ImageUploadSection extends StatefulWidget {
  final BackendService backendService;

  const ImageUploadSection({
    Key? key,
    required this.backendService,
  }) : super(key: key);

  @override
  State<ImageUploadSection> createState() => _ImageUploadSectionState();
}

class _ImageUploadSectionState extends State<ImageUploadSection>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedCategory = 'background';
  bool _isUploading = false;
  String? _uploadMessage;
  List<Map<String, dynamic>> _images = [];
  List<Map<String, dynamic>> _filteredImages = [];
  bool _isLoadingImages = false;
  bool _isDragging = false;
  int _uploadingCount = 0;
  int _uploadedCount = 0;

  // Search and filter
  String _searchQuery = '';
  String _filterMode = 'all'; // 'all', 'favorites', 'recent'

  // Bulk delete
  bool _selectMode = false;
  Set<String> _selectedImages = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          switch (_tabController.index) {
            case 0:
              _selectedCategory = 'avatar';
              break;
            case 1:
              _selectedCategory = 'background';
              break;
            case 2:
              _selectedCategory = 'overlay';
              break;
          }
          _loadImages();
        });
      }
    });
    _loadImages();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadImages() async {
    setState(() {
      _isLoadingImages = true;
    });

    try {
      final images =
          await widget.backendService.apiClient.listImages(_selectedCategory);
      setState(() {
        _images = images;
        _applyFilters();
        _isLoadingImages = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingImages = false;
        _uploadMessage = 'Failed to load images: $e';
      });
    }
  }

  Future<void> _pickAndUploadImage({bool allowMultiple = false}) async {
    // Pick image file(s)
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: allowMultiple,
    );

    if (result == null) return;

    // Show preview and optionally crop before upload
    for (var platformFile in result.files) {
      final file = File(platformFile.path!);

      // Show preview dialog
      final shouldUpload = await _showImagePreview(file);
      if (shouldUpload == true) {
        await _uploadFile(file);
      }
    }
  }

  Future<bool?> _showImagePreview(File file) async {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Image Preview'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              constraints: const BoxConstraints(maxHeight: 300),
              child: Image.file(file, fit: BoxFit.contain),
            ),
            const SizedBox(height: 16),
            Text(
              'Size: ${(file.lengthSync() / 1024).toStringAsFixed(1)} KB',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              // Crop image
              Navigator.pop(context, false);
              final croppedFile = await _cropImage(file);
              if (croppedFile != null && mounted) {
                await _uploadFile(croppedFile);
              }
            },
            child: const Text('Crop & Upload'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Upload'),
          ),
        ],
      ),
    );
  }

  Future<File?> _cropImage(File file) async {
    try {
      CroppedFile? cropped = await ImageCropper().cropImage(
        sourcePath: file.path,
        aspectRatioPresets: [
          CropAspectRatioPreset.square,
          CropAspectRatioPreset.ratio16x9,
          CropAspectRatioPreset.ratio4x3,
          CropAspectRatioPreset.original,
        ],
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Image',
            toolbarColor: Colors.deepPurple,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: false,
          ),
          IOSUiSettings(
            title: 'Crop Image',
          ),
        ],
      );

      return cropped != null ? File(cropped.path) : null;
    } catch (e) {
      if (mounted) {
        setState(() {
          _uploadMessage = 'Crop failed: $e';
        });
      }
      return null;
    }
  }

  Future<void> _uploadFile(File file) async {
    setState(() {
      _isUploading = true;
      _uploadingCount++;
      _uploadMessage = 'Uploading $_uploadingCount file(s)...';
    });

    try {
      await widget.backendService.apiClient.uploadImage(
        file,
        _selectedCategory,
      );

      setState(() {
        _uploadedCount++;
        _uploadMessage = 'Uploaded $_uploadedCount of $_uploadingCount files';
      });

      // Reload images after short delay
      await Future.delayed(const Duration(milliseconds: 500));
      await _loadImages();
    } catch (e) {
      setState(() {
        _uploadMessage = 'Upload failed: $e';
      });
    } finally {
      setState(() {
        if (_uploadedCount >= _uploadingCount) {
          _isUploading = false;
          _uploadingCount = 0;
          _uploadedCount = 0;

          // Clear message after 3 seconds
          Future.delayed(const Duration(seconds: 3), () {
            if (mounted) {
              setState(() {
                _uploadMessage = null;
              });
            }
          });
        }
      });
    }
  }

  Future<void> _handleDroppedFiles(List<XFile> files) async {
    for (var xfile in files) {
      final file = File(xfile.path);

      // Verify it's an image
      final extension = file.path.split('.').last.toLowerCase();
      if (['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(extension)) {
        await _uploadFile(file);
      }
    }
  }

  Future<void> _deleteImage(String filename) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Image'),
        content: const Text('Are you sure you want to delete this image?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await widget.backendService.apiClient.deleteImage(
        _selectedCategory,
        filename,
      );

      setState(() {
        _uploadMessage = 'Image deleted';
      });

      await _loadImages();
    } catch (e) {
      setState(() {
        _uploadMessage = 'Failed to delete: $e';
      });
    }
  }

  void _applyFilters() {
    List<Map<String, dynamic>> filtered = List.from(_images);

    // Apply filter mode
    if (_filterMode == 'favorites') {
      filtered = filtered.where((img) => img['is_favorite'] == true).toList();
    } else if (_filterMode == 'recent') {
      // Already sorted by filename (UUID timestamp)
      filtered = filtered.take(10).toList();
    }

    // Apply search query
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((img) {
        final filename = img['filename'].toString().toLowerCase();
        return filename.contains(_searchQuery.toLowerCase());
      }).toList();
    }

    setState(() {
      _filteredImages = filtered;
    });
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
      _applyFilters();
    });
  }

  void _onFilterChanged(String? mode) {
    if (mode != null) {
      setState(() {
        _filterMode = mode;
        _applyFilters();
      });
    }
  }

  void _toggleSelectMode() {
    setState(() {
      _selectMode = !_selectMode;
      _selectedImages.clear();
    });
  }

  void _toggleImageSelection(String filename) {
    setState(() {
      if (_selectedImages.contains(filename)) {
        _selectedImages.remove(filename);
      } else {
        _selectedImages.add(filename);
      }
    });
  }

  Future<void> _bulkDelete() async {
    if (_selectedImages.isEmpty) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bulk Delete'),
        content: Text('Delete ${_selectedImages.length} selected images?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    int deletedCount = _selectedImages.length;

    // Delete all selected images
    for (var filename in List.from(_selectedImages)) {
      try {
        await widget.backendService.apiClient.deleteImage(
          _selectedCategory,
          filename,
        );
      } catch (e) {
        // Continue deleting others even if one fails
      }
    }

    setState(() {
      _selectedImages.clear();
      _selectMode = false;
      _uploadMessage = 'Deleted $deletedCount images';
    });

    await _loadImages();
  }

  Future<void> _toggleFavorite(String filename, bool currentStatus) async {
    try {
      final response = await widget.backendService.apiClient.post(
        '/images/$_selectedCategory/$filename/favorite',
        {},
      );

      // Update local state
      final imageIndex =
          _images.indexWhere((img) => img['filename'] == filename);
      if (imageIndex != -1) {
        setState(() {
          _images[imageIndex]['is_favorite'] = !currentStatus;
          _applyFilters();
        });
      }
    } catch (e) {
      setState(() {
        _uploadMessage = 'Failed to toggle favorite: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return DropTarget(
      onDragDone: (details) async {
        setState(() {
          _isDragging = false;
        });
        await _handleDroppedFiles(details.files);
      },
      onDragEntered: (details) {
        setState(() {
          _isDragging = true;
        });
      },
      onDragExited: (details) {
        setState(() {
          _isDragging = false;
        });
      },
      child: Container(
        decoration: BoxDecoration(
          color: _isDragging ? Colors.deepPurple[50] : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _isDragging ? Colors.deepPurple : Colors.grey[300]!,
            width: _isDragging ? 3 : 1,
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              children: [
                const Icon(Icons.photo_library, color: Colors.deepPurple),
                const SizedBox(width: 8),
                const Text(
                  'Livestream Images',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Tab Bar
            TabBar(
              controller: _tabController,
              labelColor: Colors.deepPurple,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Colors.deepPurple,
              tabs: const [
                Tab(text: 'Avatar'),
                Tab(text: 'Background'),
                Tab(text: 'Overlay'),
              ],
            ),

            const SizedBox(height: 16),

            // Upload Buttons Row
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isUploading ? null : _pickAndUploadImage,
                    icon: _isUploading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.upload_file),
                    label: Text(_isUploading ? 'Uploading...' : 'Upload Image'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isUploading
                        ? null
                        : () => _pickAndUploadImage(allowMultiple: true),
                    icon: _isUploading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.file_upload),
                    label: Text(_isUploading ? 'Uploading...' : 'Batch Upload'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple[300],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),

            // Upload Message
            if (_uploadMessage != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _uploadMessage!.contains('failed') ||
                          _uploadMessage!.contains('Failed')
                      ? Colors.red[50]
                      : Colors.green[50],
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _uploadMessage!,
                  style: TextStyle(
                    fontSize: 12,
                    color: _uploadMessage!.contains('failed') ||
                            _uploadMessage!.contains('Failed')
                        ? Colors.red[900]
                        : Colors.green[900],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Images Grid
            Expanded(
              child: _isLoadingImages
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredImages.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.image_not_supported,
                                  size: 48, color: Colors.grey[400]),
                              const SizedBox(height: 8),
                              Text(
                                _searchQuery.isNotEmpty || _filterMode != 'all'
                                    ? 'No matching images'
                                    : 'No images uploaded yet',
                                style: TextStyle(
                                    color: Colors.grey[600], fontSize: 14),
                              ),
                            ],
                          ),
                        )
                      : GridView.builder(
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                            childAspectRatio: 1,
                          ),
                          itemCount: _filteredImages.length,
                          itemBuilder: (context, index) {
                            final image = _filteredImages[index];
                            return _buildImageCard(image);
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageCard(Map<String, dynamic> image) {
    final filename = image['filename'] as String;
    final width = image['width'] ?? 0;
    final height = image['height'] ?? 0;
    final isFavorite = image['is_favorite'] ?? false;
    final isSelected = _selectedImages.contains(filename);

    return GestureDetector(
      onTap: _selectMode ? () => _toggleImageSelection(filename) : null,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 3,
                  child: Container(
                    color: Colors.grey[300],
                    child: Image.network(
                      'http://127.0.0.1:8000/api/images/$_selectedCategory/$filename',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Icon(
                        Icons.broken_image,
                        size: 32,
                        color: Colors.grey[500],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${width}x$height',
                          style:
                              const TextStyle(fontSize: 10, color: Colors.grey),
                        ),
                        const SizedBox(height: 4),
                        if (!_selectMode)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Favorite button
                              IconButton(
                                icon: Icon(
                                  isFavorite ? Icons.star : Icons.star_border,
                                  size: 16,
                                  color:
                                      isFavorite ? Colors.amber : Colors.grey,
                                ),
                                onPressed: () =>
                                    _toggleFavorite(filename, isFavorite),
                                tooltip: isFavorite ? 'Unfavorite' : 'Favorite',
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                              const SizedBox(width: 4),

                              IconButton(
                                icon: const Icon(Icons.delete, size: 16),
                                onPressed: () => _deleteImage(filename),
                                tooltip: 'Delete',
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                color: Colors.red,
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // Selection checkbox (top-left)
            if (_selectMode)
              Positioned(
                top: 4,
                left: 4,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: Checkbox(
                    value: isSelected,
                    onChanged: (_) => _toggleImageSelection(filename),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ),

            // Favorite star indicator (top-right)
            if (!_selectMode && isFavorite)
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.9),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.star,
                    size: 12,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
