import 'dart:io';

import 'package:csen268_project/models/export_request.dart';
import 'package:csen268_project/models/project_model.dart';
import 'package:csen268_project/repositories/project_repository.dart';
import 'package:csen268_project/cubits/user_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_player/video_player.dart';

class ExportScreen extends StatefulWidget {
  final ExportRequest? request;
  const ExportScreen({super.key, this.request});

  @override
  State<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends State<ExportScreen> {
  final TextEditingController _projectNameController = TextEditingController();
  int _previewVersion = 0; // bump to force rebuild when file updates
  VideoPlayerController? _videoController;
  bool _initializingVideo = false;
  bool _isSaving = false;
  bool _isSavingProject = false;

  @override
  void initState() {
    super.initState();
    _projectNameController.text = _defaultProjectName();
    _initializePreview(initial: true);
  }

  @override
  void didUpdateWidget(covariant ExportScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.request?.filePath != widget.request?.filePath ||
        oldWidget.request?.mediaType != widget.request?.mediaType) {
      _evictImageCache(widget.request?.filePath);
      _previewVersion++;
      _projectNameController.text = _defaultProjectName();
      _disposeVideo();
      _initializePreview(initial: true);
    }
  }

  @override
  void dispose() {
    _disposeVideo();
    _projectNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isVideo = widget.request?.isVideo ?? false;
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.grey[50],
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Export',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: _handleClose,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPreviewSection(),
            const SizedBox(height: 32),

            // Share title
            const Text(
              'Share',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 16),

            // four platform icons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildShareButton(Icons.facebook, 'Facebook'),
                _buildShareButton(Icons.video_library, 'YouTube'),
                _buildShareButton(Icons.music_note, 'TikTok'),
                _buildShareButton(Icons.camera_alt, 'Instagram'),
              ],
            ),

            const Spacer(),

            // Save to My Projects
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Save to My Projects',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _projectNameController,
                    decoration: InputDecoration(
                      hintText: 'Project name',
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Colors.black12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: (_isSavingProject || widget.request == null) ? null : _saveToProjects,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black87,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: _isSavingProject
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              'Save to My Projects',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Save button
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: (widget.request == null || _isSaving) ? null : _saveToDevice,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00A86B),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : const Text(
                        'Save to Device',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewSection() {
    final request = widget.request;
    Widget child;

    if (request == null) {
      child = _buildPlaceholder('No preview available yet');
    } else if (request.isVideo) {
      child = _buildVideoPreview();
    } else {
      child = _buildImagePreview(request.filePath);
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        // increased height since settings were removed; use available space for preview
        height: 280,
        width: double.infinity,
        color: Colors.black12,
        child: child,
      ),
    );
  }

  Widget _buildImagePreview(String path) {
    final file = File(path);
    if (!file.existsSync()) {
      return _buildPlaceholder('Image file not found');
    }
    final imageProvider = FileImage(file);
    imageProvider.evict(); // ensure refreshed when path reused
    return Center(
      child: Image(
        key: ValueKey('${path}_${_fileModifiedAtMs(file)}_$_previewVersion'),
        image: imageProvider,
        fit: BoxFit.contain,
        width: double.infinity,
        height: double.infinity,
      ),
    );
  }

  Widget _buildVideoPreview() {
    if (_initializingVideo) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_videoController == null || !_videoController!.value.isInitialized) {
      return _buildPlaceholder('Unable to load video preview');
    }

    return GestureDetector(
      onTap: () {
        if (_videoController!.value.isPlaying) {
          _videoController!.pause();
        } else {
          _videoController!.play();
        }
        setState(() {});
      },
          child: Stack(
            alignment: Alignment.center,
            children: [
              AspectRatio(
                aspectRatio: _videoController!.value.aspectRatio,
                child: VideoPlayer(_videoController!),
              ),
              if (!_videoController!.value.isPlaying)
                Container(
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(40),
              ),
              padding: const EdgeInsets.all(12),
                  child: const Icon(
                    Icons.play_arrow,
                    size: 40,
                    color: Colors.white,
                  ),
                ),
            ],
          ),
        );
  }

  Widget _buildPlaceholder(String message) {
    return Container(
      color: Colors.grey[200],
      child: Center(
        child: Text(message, style: const TextStyle(color: Colors.black54)),
      ),
    );
  }

  Widget _buildShareButton(IconData icon, String label) {
    return InkWell(
      onTap: () => _shareToPlatform(label),
      borderRadius: BorderRadius.circular(50),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.teal.withOpacity(0.1),
              borderRadius: BorderRadius.circular(50),
            ),
            padding: const EdgeInsets.all(14),
            child: Icon(icon, color: Colors.teal, size: 26),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Colors.black87),
          ),
        ],
      ),
    );
  }

  Future<void> _initializePreview({bool initial = false}) async {
    final request = widget.request;
    if (request == null || !request.isVideo) return;

    final file = File(request.filePath);
    if (!file.existsSync()) {
      _showMessage('Video file not found');
      return;
    }

    setState(() {
      _initializingVideo = true;
    });

    final controller = VideoPlayerController.file(file);
    try {
      await controller.initialize();
      controller.setLooping(true);
      await controller.play();
      if (!mounted) {
        controller.dispose();
        return;
      }
      setState(() {
        _videoController = controller;
        _initializingVideo = false;
      });
    } catch (e) {
      controller.dispose();
      if (!mounted) return;
      setState(() {
        _initializingVideo = false;
      });
      _showMessage('Failed to initialize video: $e');
    }
  }

  void _disposeVideo() {
    _videoController?.dispose();
    _videoController = null;
  }

  Future<void> _shareToPlatform(String platformName) async {
    final request = widget.request;
    if (request == null) {
      _showMessage('Please export from the editor first');
      return;
    }

    final file = File(request.filePath);
    if (!file.existsSync()) {
      _showMessage('File to share not found');
      return;
    }

    try {
      await Share.shareXFiles([
        XFile(file.path),
      ], text: 'Created with CSEN268 Project and sharing on $platformName!');
    } catch (e) {
      _showMessage('Share failed: $e');
    }
  }

  Future<void> _saveToDevice() async {
    final request = widget.request;
    if (request == null) {
      _showMessage('No file available to save');
      return;
    }

    final file = File(request.filePath);
    if (!file.existsSync()) {
      _showMessage('File not found, please export again');
      return;
    }

    final hasPermission = await _ensurePermission();
    if (!hasPermission) {
      _showMessage('Storage permission denied, please enable it in settings');
      return;
    }

    if (!mounted) return;
    setState(() {
      _isSaving = true;
    });

    setState(() {
      _isSaving = true;
    });

    try {
      final saved = request.isVideo
          ? await _saveVideoToGallery(request.filePath)
          : await _saveImageToGallery(request.filePath);

      if (!mounted) return;
      _showMessage(
        saved ? 'Saved to gallery successfully' : 'Save failed, please retry',
      );
    } catch (e) {
      if (!mounted) return;
      _showMessage('Save failed: $e');
    } finally {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
      });
    }
  }

  Future<bool> _saveImageToGallery(String path) async {
    final entity = await PhotoManager.editor.saveImageWithPath(
      path,
      title: _fileNameFromPath(path),
    );
    return entity != null;
  }

  Future<bool> _saveVideoToGallery(String path) async {
    final entity = await PhotoManager.editor.saveVideo(
      File(path),
      title: _fileNameFromPath(path),
    );
    return entity != null;
  }

  Future<bool> _ensurePermission() async {
    final result = await PhotoManager.requestPermissionExtend();
    if (result.isAuth || result == PermissionState.limited) {
      return true;
    }
    await PhotoManager.openSetting();
    return false;
  }

  String _fileNameFromPath(String path) {
    final segments = path.split(RegExp(r'[\\/]+'));
    return segments.isNotEmpty ? segments.last : 'exported_file';
  }

  void _handleClose() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      Navigator.of(context).maybePop();
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _evictImageCache(String? path) {
    if (path == null || path.isEmpty) return;
    final file = File(path);
    if (!file.existsSync()) return;
    FileImage(file).evict();
  }

  int _fileModifiedAtMs(File file) {
    try {
      return file.lastModifiedSync().millisecondsSinceEpoch;
    } catch (_) {
      return 0;
    }
  }

  String _defaultProjectName() {
    final path = widget.request?.filePath;
    if (path == null || path.isEmpty) return 'Edited Project';
    final segments = path.split(RegExp(r'[\\/]+'));
    final fileName = segments.isNotEmpty ? segments.last : 'Edited Project';
    return fileName;
  }

  Future<void> _saveToProjects() async {
    final request = widget.request;
    if (request == null) {
      _showMessage('No file available to save');
      return;
    }

    final userId = context.read<UserCubit>().state.user?.id;
    if (userId == null || userId.isEmpty) {
      _showMessage('Please sign in to save projects');
      return;
    }

    final name = _projectNameController.text.trim().isEmpty
        ? _defaultProjectName()
        : _projectNameController.text.trim();

    if (!mounted) return;
    setState(() {
      _isSavingProject = true;
    });

    final repository = ProjectRepository(userId: userId);
    try {
      await repository.createProjectAutoId(
        Project(id: '', name: name, imageUrl: request.filePath),
      );
      if (!mounted) return;
      _showMessage('Saved to My Projects');
    } catch (e) {
      if (!mounted) return;
      _showMessage('Save failed: $e');
    } finally {
      if (!mounted) return;
      setState(() {
        _isSavingProject = false;
      });
    }
  }

}
