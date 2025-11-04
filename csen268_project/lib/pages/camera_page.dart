import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:csen268_project/cubits/camera_cubit.dart';
import 'package:csen268_project/cubits/camera_state.dart';
import 'package:csen268_project/widgets/bottom_nav_bar.dart';
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
        child: Column(
          children: [
            // 顶部栏
            _buildTopBar(context),
            // 相机预览区域
            Expanded(
              child: _buildCameraPreview(context),
            ),
            // 相机模式选择
            _buildCameraModeSelector(context),
            const SizedBox(height: 16),
            // 控制按钮
            _buildControlButtons(context),
            const SizedBox(height: 24),
            // 底部导航栏
            _buildBottomNavBar(context),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // 左侧关闭按钮 (iOS风格)
          IconButton(
            icon: Icon(
              Platform.isIOS ? CupertinoIcons.xmark : Icons.close,
              size: 24,
              color: const Color(0xFF9E9E9E),
            ),
            onPressed: () => context.pop(),
          ),
          const Spacer(),
          // 标题
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
          // 右侧设置按钮
          IconButton(
            icon: Image.asset(
              'assets/icons/setting.png',
              width: 24,
              height: 24,
            ),
            onPressed: () {
              // TODO: 打开设置
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
                // TODO: 实际的相机预览将替换这个占位符
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
                // 加载状态 (iOS风格使用CupertinoActivityIndicator)
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
            ),
          ),
        );
      },
    );
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
              // 图库按钮
              _buildGalleryButton(context),
              const SizedBox(width: 16),
              // 拍照按钮
              _buildCaptureButton(context),
              const SizedBox(width: 16),
              // 录像按钮
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
        context.read<CameraCubit>().openGallery();
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
            // 使用一个类似风景的图标组合
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

  Widget _buildBottomNavBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: BottomNavBar(
        currentIndex: 1, // 相机页面索引为1
        onTabSelected: (index) {
          // TODO: 处理导航
          if (index == 0) {
            context.go('/');
          }
        },
      ),
    );
  }
}
