import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:csen268_project/cubits/camera_cubit.dart';
import 'package:csen268_project/cubits/camera_state.dart';
import 'package:csen268_project/widgets/bottom_nav_bar.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io' show Platform;
import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';

class CameraPage extends StatelessWidget {
  const CameraPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => CameraCubit()..initializeCamera(),
      child: const _CameraPageView(),
    );
  }
}

class _CameraPageView extends StatelessWidget {
  const _CameraPageView();

  @override
  Widget build(BuildContext context) {
    return BlocListener<CameraCubit, CameraState>(
      // Only listen when gallerySaveSuccess or gallerySaveError changes
      listenWhen: (previous, current) {
        // Trigger only when gallerySaveSuccess changes from non-true to true,
        // or from non-false to false (with error)
        return previous.gallerySaveSuccess != current.gallerySaveSuccess ||
               previous.gallerySaveError != current.gallerySaveError;
      },
      listener: (context, state) {
        // Show feedback when saving to gallery
        if (state.gallerySaveSuccess == true) {
          // Determine if it's a video or photo based on last saved path
          final isVideo = state.lastRecordedVideoPath != null;
          final message = isVideo ? 'Video saved to gallery' : 'Photo saved to gallery';
          
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(
                    Platform.isIOS ? CupertinoIcons.check_mark_circled : Icons.check_circle,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(message),
                ],
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
          // Reset state after showing message to prevent duplicate triggers
          Future.microtask(() {
            context.read<CameraCubit>().resetGallerySaveStatus();
          });
        } else if (state.gallerySaveSuccess == false && state.gallerySaveError != null) {
          // Show error message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(
                    Platform.isIOS ? CupertinoIcons.exclamationmark_circle : Icons.error,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      state.gallerySaveError!,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
              behavior: SnackBarBehavior.floating,
              action: state.gallerySaveError!.contains('permission') ||
                      state.gallerySaveError!.contains('Settings')
                  ? SnackBarAction(
                      label: 'Settings',
                      textColor: Colors.white,
                      onPressed: () async {
                        await _openAppSettings(context);
                      },
                    )
                  : null,
            ),
          );
          // Reset state after showing message to prevent duplicate triggers
          Future.microtask(() {
            context.read<CameraCubit>().resetGallerySaveStatus();
          });
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF7FBF9),
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              // top bar
              _buildTopBar(context),
              // camera preview area
              Expanded(
                child: _buildCameraPreview(context),
              ),
              // camera mode selector
              _buildCameraModeSelector(context),
              const SizedBox(height: 16),
              // control buttons
              _buildControlButtons(context),
              const SizedBox(height: 24),
            ],
          ),
        ),
        bottomNavigationBar: BottomNavBar(currentIndex: 1),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // left close button (iOS style)
          IconButton(
            icon: Icon(
              Platform.isIOS ? CupertinoIcons.xmark : Icons.close,
              size: 24,
              color: const Color(0xFF9E9E9E),
            ),
            onPressed: () => context.go('/'),
          ),
          const Spacer(),
          // title
          const Text(
            'Camera',
            style: TextStyle(
              fontFamily: 'Spline Sans',
              fontSize: 18,
              fontWeight: FontWeight.w400,
              color: Color(0xFF9E9E9E),
            ),
          ),
          const Spacer(),
          // right setting button
          IconButton(
            icon: Image.asset(
              'assets/icons/setting.png',
              width: 24,
              height: 24,
            ),
            onPressed: () {
              // TODO: open settings
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCameraPreview(BuildContext context) {
    return BlocBuilder<CameraCubit, CameraState>(
      builder: (context, state) {
        return Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Dual camera mode
                if (state.cameraMode == CameraMode.dual) ...[
                  // Rear camera (main, full screen)
                  if (state.isRearInitialized && 
                      state.rearController != null && 
                      state.rearController!.value.isInitialized)
                    SizedBox.expand(
                      child: FittedBox(
                        fit: BoxFit.cover,
                        child: SizedBox(
                          width: state.rearController!.value.previewSize?.height ?? 1,
                          height: state.rearController!.value.previewSize?.width ?? 1,
                          child: CameraPreview(state.rearController!),
                        ),
                      ),
                    )
                  else
                    Container(
                      color: Colors.black87,
                      child: Center(
                        child: Platform.isIOS
                            ? const CupertinoActivityIndicator(
                                color: Colors.white,
                                radius: 12,
                              )
                            : const CircularProgressIndicator(
                                color: Colors.white,
                              ),
                      ),
                    ),
                  // Front camera (small preview in top right corner)
                  // Priority: Use frame data if available (more reliable on iOS)
                  // Fallback: Try CameraPreview directly (may not work in dual mode on iOS)
                  if (state.isFrontInitialized && 
                      state.frontController != null &&
                      state.frontCameraFrame != null &&
                      state.frontCameraFrameWidth != null &&
                      state.frontCameraFrameHeight != null)
                    // Use frame data (from image stream)
                    Positioned(
                      top: 16,
                      right: 16,
                      child: Container(
                        width: 120,
                        height: 160,
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white,
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.5),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: _buildFrontCameraPreviewFromFrame(
                            state.frontController!,
                            state.frontCameraFrame,
                            state.frontCameraFrameWidth,
                            state.frontCameraFrameHeight,
                          ),
                        ),
                      ),
                    )
                  // Fallback: Try CameraPreview directly (may show black screen on iOS)
                  else if (state.isFrontInitialized && 
                           state.frontController != null && 
                           state.frontController!.value.isInitialized)
                    Positioned(
                      top: 16,
                      right: 16,
                      child: Container(
                        width: 120,
                        height: 160,
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white,
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.5),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: _buildFrontCameraPreviewFromFrame(
                            state.frontController!,
                            state.frontCameraFrame,
                            state.frontCameraFrameWidth,
                            state.frontCameraFrameHeight,
                          ),
                        ),
                      ),
                    )
                  else if (state.isFrontInitialized && state.frontController != null)
                    // Front camera is initializing - show loading indicator
                    Positioned(
                      top: 16,
                      right: 16,
                      child: Container(
                        width: 120,
                        height: 160,
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.5),
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: Platform.isIOS
                              ? const CupertinoActivityIndicator(
                                  color: Colors.white,
                                  radius: 8,
                                )
                              : const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                ),
                        ),
                      ),
                    )
                ]
                // Single camera mode (front or rear)
                else ...[
                  if (state.isInitialized && state.controller != null)
                    SizedBox.expand(
                      child: FittedBox(
                        fit: BoxFit.cover,
                        child: SizedBox(
                          width: state.controller!.value.previewSize?.height ?? 1,
                          height: state.controller!.value.previewSize?.width ?? 1,
                          child: CameraPreview(state.controller!),
                        ),
                      ),
                    )
                  else
                    Container(
                      color: Colors.black87,
                      child: const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.camera_alt,
                              size: 64,
                              color: Colors.white54,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Camera Preview',
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  // loading state
                  if (!state.isInitialized)
                    Container(
                      color: Colors.black54,
                      child: Center(
                        child: Platform.isIOS
                            ? const CupertinoActivityIndicator(
                                color: Colors.white,
                                radius: 12,
                              )
                            : const CircularProgressIndicator(
                                color: Colors.white,
                              ),
                      ),
                    ),
                ],
                // Error message overlay
                if (state.errorMessage != null)
                  Positioned(
                    bottom: 16,
                    left: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            state.errorMessage!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          if (state.errorMessage!.contains('permanently denied') ||
                              state.errorMessage!.contains('Settings'))
                            Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: ElevatedButton(
                                onPressed: () async {
                                  await _openAppSettings(context);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: Colors.red,
                                ),
                                child: const Text('Open Settings'),
                              ),
                            )
                          else if (state.errorMessage!.contains('denied'))
                            Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: ElevatedButton(
                                onPressed: () {
                                  context.read<CameraCubit>().initializeCamera();
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: Colors.red,
                                ),
                                child: const Text('Retry'),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                // Recording duration overlay
                if (state.recordingState == RecordingState.recording &&
                    state.recordingDuration != null)
                  Positioned(
                    top: 16,
                    left: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(20),
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
                          const SizedBox(width: 8),
                          Text(
                            _formatDuration(state.recordingDuration!),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  Widget _buildFrontCameraPreviewFromFrame(
    CameraController controller,
    Uint8List? frameData,
    int? frameWidth,
    int? frameHeight,
  ) {
    final isInitialized = controller.value.isInitialized;
    
    print('📷 UI: Building front preview from frame - frameData: ${frameData != null ? "${frameData.length} bytes" : "null"}, size: ${frameWidth}x$frameHeight');
    
    if (!isInitialized) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: Icon(
            Icons.camera_alt,
            color: Colors.white54,
            size: 32,
          ),
        ),
      );
    }

    // If we have frame data, convert and display it
    if (frameData != null && frameData.isNotEmpty && frameWidth != null && frameHeight != null) {
      print('📷 UI: Converting frame data to image: ${frameWidth}x$frameHeight, ${frameData.length} bytes');
      return FutureBuilder<ui.Image>(
        future: _convertFrameDataToImage(frameData, frameWidth, frameHeight),
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data != null) {
            print('📷 UI: Image converted successfully, displaying');
            return Transform.scale(
              scaleX: -1.0, // Mirror horizontally for front camera
              child: CustomPaint(
                painter: _FramePainter(snapshot.data!),
                size: Size.infinite,
              ),
            );
          } else if (snapshot.hasError) {
            print('📷 UI: Error converting image: ${snapshot.error}');
            return Container(
              color: Colors.red.withValues(alpha: 0.3),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error,
                      color: Colors.white,
                      size: 24,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Error',
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                    ),
                  ],
                ),
              ),
            );
          } else {
            print('📷 UI: Converting image...');
            return Container(
              color: Colors.black54,
              child: Center(
                child: Platform.isIOS
                    ? const CupertinoActivityIndicator(
                        color: Colors.white,
                        radius: 8,
                      )
                    : const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      ),
              ),
            );
          }
        },
      );
    }

    // No frame data yet, show loading
    return Container(
      color: Colors.black54,
      child: Center(
        child: Platform.isIOS
            ? const CupertinoActivityIndicator(
                color: Colors.white,
                radius: 8,
              )
            : const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              ),
      ),
    );
  }

  Widget _buildFrontCameraPreviewDirect(CameraController controller) {
    final previewSize = controller.value.previewSize;
    if (previewSize == null || !controller.value.isInitialized) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: Icon(
            Icons.camera_alt,
            color: Colors.white54,
            size: 32,
          ),
        ),
      );
    }

    // Try to display CameraPreview directly
    // Use Transform to mirror flip for front camera
    return Transform.scale(
      scaleX: -1.0, // Mirror horizontally
      child: SizedBox.expand(
        child: FittedBox(
          fit: BoxFit.cover,
          alignment: Alignment.center,
          child: SizedBox(
            // Swap width and height to match orientation
            width: previewSize.height,
            height: previewSize.width,
            child: CameraPreview(controller),
          ),
        ),
      ),
    );
  }

  Future<ui.Image> _convertFrameDataToImage(Uint8List frameData, int width, int height) async {
    print('📷 UI: Converting frame to image - ${width}x$height, ${frameData.length} bytes');
    // BGRA8888 format: 4 bytes per pixel (B, G, R, A)
    final completer = Completer<ui.Image>();
    try {
      ui.decodeImageFromPixels(
        frameData,
        width,
        height,
        ui.PixelFormat.bgra8888,
        (ui.Image image) {
          print('📷 UI: Image decoded successfully: ${image.width}x${image.height}');
          completer.complete(image);
        },
      );
    } catch (e) {
      print('📷 UI: Error in decodeImageFromPixels: $e');
      completer.completeError(e);
    }
    return completer.future;
  }
}

class _FramePainter extends CustomPainter {
  final ui.Image image;

  _FramePainter(this.image);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    final srcRect = Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble());
    final dstRect = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawImageRect(image, srcRect, dstRect, paint);
  }

  @override
  bool shouldRepaint(_FramePainter oldDelegate) {
    return oldDelegate.image != image;
  }
}

extension _CameraPageViewExtension on _CameraPageView {
  Future<void> _openAppSettings(BuildContext context) async {
    final opened = await openAppSettings();
    if (opened) {
      // Wait a bit for user to return from settings
      await Future.delayed(const Duration(seconds: 1));
      // Re-initialize camera when user returns
      context.read<CameraCubit>().initializeCamera();
    }
  }

  Widget _buildCameraModeSelector(BuildContext context) {
    return BlocBuilder<CameraCubit, CameraState>(
      builder: (context, state) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFFE8E8E8),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildModeButton(
                  context,
                  label: 'Front',
                  mode: CameraMode.front,
                  isSelected: state.cameraMode == CameraMode.front,
                ),
                _buildModeButton(
                  context,
                  label: 'Rear',
                  mode: CameraMode.rear,
                  isSelected: state.cameraMode == CameraMode.rear,
                ),
                _buildModeButton(
                  context,
                  label: 'Dual',
                  mode: CameraMode.dual,
                  isSelected: state.cameraMode == CameraMode.dual,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildModeButton(
    BuildContext context, {
    required String label,
    required CameraMode mode,
    required bool isSelected,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          context.read<CameraCubit>().switchCameraMode(mode);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'Spline Sans',
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? const Color(0xFF0D1C17) : const Color(0xFF9E9E9E),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildControlButtons(BuildContext context) {
    return BlocBuilder<CameraCubit, CameraState>(
      builder: (context, state) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // gallery button
              _buildGalleryButton(context),
              const SizedBox(width: 16),
              // take picture button
              _buildCaptureButton(context),
              const SizedBox(width: 16),
              // record button
              _buildRecordButton(context, state),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGalleryButton(BuildContext context) {
    return GestureDetector(
      onTap: () {
        context.push('/media-selection');
      },
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: const Color(0xFFE8E8E8),
          shape: BoxShape.circle,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // use a combination of landscape icons
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 4,
                      height: 4,
                      decoration: const BoxDecoration(
                        color: Color(0xFF0D1C17),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 2),
                    Container(
                      width: 4,
                      height: 4,
                      decoration: const BoxDecoration(
                        color: Color(0xFF0D1C17),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Container(
                  width: 12,
                  height: 6,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D1C17),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCaptureButton(BuildContext context) {
    return GestureDetector(
      onTap: () {
        context.read<CameraCubit>().takePicture();
      },
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: const Color(0xFFE8E8E8),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(
          Icons.camera_alt,
          color: Color(0xFF0D1C17),
          size: 32,
        ),
      ),
    );
  }

  Widget _buildRecordButton(BuildContext context, CameraState state) {
    final isRecording = state.recordingState == RecordingState.recording;
    return GestureDetector(
      onTap: () {
        context.read<CameraCubit>().toggleRecording();
      },
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: isRecording ? Colors.red : const Color(0xFFE8E8E8),
          shape: BoxShape.circle,
          border: isRecording
              ? Border.all(color: Colors.red.shade700, width: 3)
              : null,
        ),
        child: isRecording
            ? Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
              )
            : Container(
                margin: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
      ),
    );
  }
}
