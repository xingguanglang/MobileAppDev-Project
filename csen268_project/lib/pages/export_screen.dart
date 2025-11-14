import 'dart:io';

import 'package:csen268_project/models/export_request.dart';
import 'package:flutter/material.dart';
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
  String _selectedResolution = '1080p';
  String _selectedFps = '30 fps';

  final List<String> _resolutions = ['720p', '1080p', '4K'];
  final List<String> _fpsOptions = ['24 fps', '30 fps', '60 fps'];
  VideoPlayerController? _videoController;
  bool _initializingVideo = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _initializePreview();
  }

  @override
  void didUpdateWidget(covariant ExportScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.request?.filePath != widget.request?.filePath ||
        oldWidget.request?.mediaType != widget.request?.mediaType) {
      _disposeVideo();
      _initializePreview();
    }
  }

  @override
  void dispose() {
    _disposeVideo();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
            const SizedBox(height: 24),

            // Settings title
            const Text(
              'Settings',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 16),

            // Resolution
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Resolution',
                  style: TextStyle(fontSize: 15, color: Colors.black),
                ),
                DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedResolution,
                    icon: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: Colors.black,
                    ),
                    items: _resolutions
                        .map(
                          (res) => DropdownMenuItem(
                            value: res,
                            child: Text(
                              res,
                              style: const TextStyle(
                                color: Colors.teal,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => _selectedResolution = v!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Frame Rate
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Frame Rate',
                  style: TextStyle(fontSize: 15, color: Colors.black),
                ),
                DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedFps,
                    icon: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: Colors.black,
                    ),
                    items: _fpsOptions
                        .map(
                          (fps) => DropdownMenuItem(
                            value: fps,
                            child: Text(
                              fps,
                              style: const TextStyle(
                                color: Colors.teal,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => _selectedFps = v!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),

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

            // Save button
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveToDevice,
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
      child = _buildPlaceholder('目前沒有可預覽的檔案');
    } else if (request.isVideo) {
      child = _buildVideoPreview();
    } else {
      child = _buildImagePreview(request.filePath);
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 200,
        width: double.infinity,
        color: Colors.black12,
        child: child,
      ),
    );
  }

  Widget _buildImagePreview(String path) {
    final file = File(path);
    if (!file.existsSync()) {
      return _buildPlaceholder('找不到圖片檔案');
    }
    return Image.file(
      file,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
    );
  }

  Widget _buildVideoPreview() {
    if (_initializingVideo) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_videoController == null || !_videoController!.value.isInitialized) {
      return _buildPlaceholder('無法載入影片預覽');
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

  Future<void> _initializePreview() async {
    final request = widget.request;
    if (request == null || !request.isVideo) return;

    final file = File(request.filePath);
    if (!file.existsSync()) {
      _showMessage('找不到影片檔案');
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
      _showMessage('影片初始化失敗：$e');
    }
  }

  void _disposeVideo() {
    _videoController?.dispose();
    _videoController = null;
  }

  Future<void> _shareToPlatform(String platformName) async {
    final request = widget.request;
    if (request == null) {
      _showMessage('請先從編輯器輸出檔案');
      return;
    }

    final file = File(request.filePath);
    if (!file.existsSync()) {
      _showMessage('找不到要分享的檔案');
      return;
    }

    try {
      await Share.shareXFiles([
        XFile(request.filePath),
      ], text: '我使用 CSEN268 Project 創作的作品，分享至 $platformName！');
    } catch (e) {
      _showMessage('分享失敗：$e');
    }
  }

  Future<void> _saveToDevice() async {
    final request = widget.request;
    if (request == null) {
      _showMessage('尚無可以儲存的檔案');
      return;
    }

    final file = File(request.filePath);
    if (!file.existsSync()) {
      _showMessage('找不到檔案，請重新輸出');
      return;
    }

    final hasPermission = await _ensurePermission();
    if (!hasPermission) {
      _showMessage('儲存權限被拒絕，請到設定中開啟');
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
      _showMessage(saved ? '已成功儲存到相簿' : '儲存失敗，請稍後再試');
    } catch (e) {
      if (!mounted) return;
      _showMessage('儲存失敗：$e');
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
}
