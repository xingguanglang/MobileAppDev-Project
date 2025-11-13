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
    return Scaffold(
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
                // Camera preview
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
