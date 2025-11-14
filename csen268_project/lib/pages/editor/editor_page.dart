// lib/pages/editor/editor_page.dart

import 'dart:io';
import 'dart:math' as math;
import 'package:csen268_project/models/export_request.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:video_player/video_player.dart';

import 'editor_models.dart';
import 'editor_common_widgets.dart';
import 'editor_photo_controls.dart';
import 'editor_video_controls.dart';
import 'trim_page.dart';

class EditorPage extends StatefulWidget {
  final List<String> selectedMediaPaths;
  const EditorPage({super.key, this.selectedMediaPaths = const []});
  @override
  State<EditorPage> createState() => _EditorPageState();
}

class _EditorPageState extends State<EditorPage> {
  // ---------------- PHOTO STATE -------------------
  double _rotationDeg = 0;
  double _brightness = 0;
  double _contrast = 1;
  double _saturation = 1;
  double _temperature = 0;

  File? _imageFile;
  EditorTab _tab = EditorTab.adjust;

  // ---------------- VIDEO STATE -------------------
  EditMode _mode = EditMode.photo;

  File? _videoFile;
  VideoPlayerController? _videoController;

  final ImagePicker _picker = ImagePicker();
  @override
  void initState() {
    super.initState();
    // If media paths are provided, load the first one
    if (widget.selectedMediaPaths.isNotEmpty) {
      _imageFile = File(widget.selectedMediaPaths.first);
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  // =====================================================
  //                    MAIN UI
  // =====================================================
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0F1115) : const Color(0xFFF7FAF7);
    final cardColor = isDark ? const Color(0xFF171B20) : Colors.white;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
        title: const Text("Editor"),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 6),

            /// Photo / Video 模式切换
            ModeSwitcher(
              mode: _mode,
              onChanged: (m) => setState(() => _mode = m),
            ),

            /// Preview 区域
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(EditorConstants.radius),
                  child: Container(
                    color: isDark
                        ? const Color(0xFF1B1F24)
                        : const Color(0xFFEFF3EF),
                    child: Center(
                      child: _mode == EditMode.photo
                          ? _buildPhotoPreview(isDark)
                          : _buildVideoPreview(isDark),
                    ),
                  ),
                ),
              ),
            ),

            /// Bottom Controls
            if (_mode == EditMode.photo)
              PhotoBottomControls(
                tab: _tab,
                onTabChanged: (t) async {
                  if (t == EditorTab.clip) {
                    await _cropImageFlow();
                  } else {
                    setState(() => _tab = t);
                  }
                },
                // rotate
                rotation: _rotationDeg,
                onRotation: (v) => setState(() => _rotationDeg = v),

                // adjust
                brightness: _brightness,
                contrast: _contrast,
                saturation: _saturation,
                temperature: _temperature,
                onBrightness: (v) => setState(() => _brightness = v),
                onContrast: (v) => setState(() => _contrast = v),
                onSaturation: (v) => setState(() => _saturation = v),
                onTemperature: (v) => setState(() => _temperature = v),

                onImport: _importImage,
                onExport: _exportPhoto,
                background: cardColor,
              )
            else
              VideoControls(
                background: cardColor,
                onImportVideo: _importVideo,
                onTrimVideo: _openTrimVideo,
                onExportVideo: _exportVideo,
              ),
          ],
        ),
      ),
    );
  }

  // =====================================================
  //                      PHOTO PREVIEW
  // =====================================================
  Widget _buildPhotoPreview(bool isDark) {
    final c = _contrast;
    final b = _brightness;
    final offset = 128.0 * (1 - c) + 255.0 * b;

    List<double> matrix = [
      c,
      0,
      0,
      0,
      offset,
      0,
      c,
      0,
      0,
      offset,
      0,
      0,
      c,
      0,
      offset,
      0,
      0,
      0,
      1,
      0,
    ];

    /// Saturation
    const lumR = 0.3086, lumG = 0.6094, lumB = 0.0820;
    final s = _saturation;
    final inv = 1 - s;
    final List<double> satMatrix = [
      lumR * inv + s,
      lumG * inv,
      lumB * inv,
      0,
      0,
      lumR * inv,
      lumG * inv + s,
      lumB * inv,
      0,
      0,
      lumR * inv,
      lumG * inv,
      lumB * inv + s,
      0,
      0,
      0,
      0,
      0,
      1,
      0,
    ];
    matrix = _mulMatrix(satMatrix, matrix);

    /// Temperature
    final t = _temperature;
    final warm = 0.25 * t;
    final cool = -0.25 * t;
    final List<double> tempMatrix = [
      1 + warm,
      0,
      0,
      0,
      0,
      0,
      1,
      0,
      0,
      0,
      0,
      0,
      1 + cool,
      0,
      0,
      0,
      0,
      0,
      1,
      0,
    ];
    matrix = _mulMatrix(tempMatrix, matrix);

    final angle = _rotationDeg * math.pi / 180;

    Widget content = _imageFile == null
        ? Icon(
            Icons.image_outlined,
            size: 72,
            color: isDark ? Colors.white70 : Colors.black54,
          )
        : Image.file(_imageFile!, fit: BoxFit.contain);

    return Transform.rotate(
      angle: angle,
      child: ColorFiltered(
        colorFilter: ColorFilter.matrix(matrix),
        child: content,
      ),
    );
  }

  List<double> _mulMatrix(List<double> a, List<double> b) {
    final out = List<double>.filled(20, 0);
    for (int r = 0; r < 4; r++) {
      for (int c = 0; c < 5; c++) {
        out[r * 5 + c] =
            b[r * 5 + 0] * a[0 + c] +
            b[r * 5 + 1] * a[5 + c] +
            b[r * 5 + 2] * a[10 + c] +
            b[r * 5 + 3] * a[15 + c] +
            (c == 4 ? b[r * 5 + 4] : 0);
      }
    }
    return out;
  }

  // =====================================================
  //                  PHOTO IMPORT & CROP
  // =====================================================
  Future<void> _importImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _imageFile = File(picked.path));
    }
  }

  Future<void> _cropImageFlow() async {
    if (_imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please import an image first.")),
      );
      return;
    }

    final result = await ImageCropper().cropImage(
      sourcePath: _imageFile!.path,
      compressFormat: ImageCompressFormat.jpg,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: "Crop",
          activeControlsWidgetColor: EditorConstants.green,
        ),
        IOSUiSettings(title: "Crop"),
      ],
    );

    if (result != null) {
      setState(() => _imageFile = File(result.path));
    }
  }

  // =====================================================
  //                       VIDEO PREVIEW
  // =====================================================
  Widget _buildVideoPreview(bool isDark) {
    if (_videoController == null || !_videoController!.value.isInitialized) {
      return Icon(
        Icons.video_library_outlined,
        size: 72,
        color: isDark ? Colors.white70 : Colors.black45,
      );
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
      child: AspectRatio(
        aspectRatio: _videoController!.value.aspectRatio,
        child: VideoPlayer(_videoController!),
      ),
    );
  }

  Future<void> _importVideo() async {
    final picked = await _picker.pickVideo(source: ImageSource.gallery);
    if (picked == null) return;

    _videoFile = File(picked.path);
    await _loadVideoPlayer();
  }

  Future<void> _loadVideoPlayer() async {
    if (_videoFile == null) return;
    _videoController?.dispose();
    _videoController = VideoPlayerController.file(_videoFile!);
    await _videoController!.initialize();
    _videoController!.setLooping(true);
    setState(() {});
    _videoController!.play();
  }

  // =====================================================
  //                   OPEN TRIM PAGE (video_editor)
  // =====================================================
  Future<void> _openTrimVideo() async {
    if (_videoFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please import a video first.")),
      );
      return;
    }

    final result = await Navigator.push<String?>(
      context,
      MaterialPageRoute(builder: (_) => TrimPage(videoFile: _videoFile!)),
    );

    if (result != null) {
      _videoFile = File(result);
      await _loadVideoPlayer();
    }
  }

  // =====================================================
  //                    EXPORT VIDEO
  // =====================================================
  Future<void> _exportPhoto() async {
    if (_imageFile == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("No image to export.")));
      return;
    }
    final request = ExportRequest(
      filePath: _imageFile!.path,
      mediaType: ExportMediaType.photo,
    );
    if (!mounted) return;
    context.push('/export', extra: request);
  }

  Future<void> _exportVideo() async {
    if (_videoFile == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("No video to export.")));
      return;
    }

    final request = ExportRequest(
      filePath: _videoFile!.path,
      mediaType: ExportMediaType.video,
      duration: _videoController?.value.duration,
    );
    if (!mounted) return;
    context.push('/export', extra: request);
  }
}
