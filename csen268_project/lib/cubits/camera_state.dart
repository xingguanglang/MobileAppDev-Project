import 'package:camera/camera.dart';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';

enum CameraMode {
  front,
  rear,
  dual,
}

enum RecordingState {
  idle,
  recording,
}

class CameraState {
  final CameraMode cameraMode;
  final RecordingState recordingState;
  final bool isInitialized;
  final String? errorMessage;
  final CameraController? controller; // For single camera mode (backward compatibility)
  final CameraController? frontController; // For dual camera mode
  final CameraController? rearController; // For dual camera mode
  final bool isFrontInitialized; // Front camera initialization status
  final bool isRearInitialized; // Rear camera initialization status
  final List<CameraDescription> availableCameras;
  final int? recordingDuration; // in seconds
  final String? lastCapturedImagePath;
  final String? lastRecordedVideoPath;
  final Uint8List? frontCameraFrame; // Captured frame from front camera for preview
  final int? frontCameraFrameWidth; // Frame width
  final int? frontCameraFrameHeight; // Frame height
  final bool isSavingToGallery; // Whether saving image to gallery
  final bool? gallerySaveSuccess; // Gallery save success status (null = not attempted, true = success, false = failed)
  final String? gallerySaveError; // Gallery save error message

  const CameraState({
    this.cameraMode = CameraMode.rear,
    this.recordingState = RecordingState.idle,
    this.isInitialized = false,
    this.errorMessage,
    this.controller,
    this.frontController,
    this.rearController,
    this.isFrontInitialized = false,
    this.isRearInitialized = false,
    this.availableCameras = const [],
    this.recordingDuration,
    this.lastCapturedImagePath,
    this.lastRecordedVideoPath,
    this.frontCameraFrame,
    this.frontCameraFrameWidth,
    this.frontCameraFrameHeight,
    this.isSavingToGallery = false,
    this.gallerySaveSuccess,
    this.gallerySaveError,
  });

  // Getter to determine if cameras are initialized based on mode
  bool get areCamerasInitialized {
    switch (cameraMode) {
      case CameraMode.dual:
        return isFrontInitialized && isRearInitialized;
      case CameraMode.front:
      case CameraMode.rear:
        return isInitialized;
    }
  }

  CameraState copyWith({
    CameraMode? cameraMode,
    RecordingState? recordingState,
    bool? isInitialized,
    String? errorMessage,
    CameraController? controller,
    CameraController? frontController,
    CameraController? rearController,
    bool? isFrontInitialized,
    bool? isRearInitialized,
    List<CameraDescription>? availableCameras,
    int? recordingDuration,
    String? lastCapturedImagePath,
    String? lastRecordedVideoPath,
    Uint8List? frontCameraFrame,
    int? frontCameraFrameWidth,
    int? frontCameraFrameHeight,
    bool? isSavingToGallery,
    bool? gallerySaveSuccess,
    String? gallerySaveError,
  }) {
    return CameraState(
      cameraMode: cameraMode ?? this.cameraMode,
      recordingState: recordingState ?? this.recordingState,
      isInitialized: isInitialized ?? this.isInitialized,
      errorMessage: errorMessage,
      controller: controller ?? this.controller,
      frontController: frontController ?? this.frontController,
      rearController: rearController ?? this.rearController,
      isFrontInitialized: isFrontInitialized ?? this.isFrontInitialized,
      isRearInitialized: isRearInitialized ?? this.isRearInitialized,
      availableCameras: availableCameras ?? this.availableCameras,
      recordingDuration: recordingDuration ?? this.recordingDuration,
      lastCapturedImagePath: lastCapturedImagePath ?? this.lastCapturedImagePath,
      lastRecordedVideoPath: lastRecordedVideoPath ?? this.lastRecordedVideoPath,
      frontCameraFrame: frontCameraFrame ?? this.frontCameraFrame,
      frontCameraFrameWidth: frontCameraFrameWidth ?? this.frontCameraFrameWidth,
      frontCameraFrameHeight: frontCameraFrameHeight ?? this.frontCameraFrameHeight,
      isSavingToGallery: isSavingToGallery ?? this.isSavingToGallery,
      gallerySaveSuccess: gallerySaveSuccess ?? this.gallerySaveSuccess,
      gallerySaveError: gallerySaveError ?? this.gallerySaveError,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CameraState &&
        other.cameraMode == cameraMode &&
        other.recordingState == recordingState &&
        other.isInitialized == isInitialized &&
        other.errorMessage == errorMessage &&
        other.controller == controller &&
        other.frontController == frontController &&
        other.rearController == rearController &&
        other.isFrontInitialized == isFrontInitialized &&
        other.isRearInitialized == isRearInitialized &&
        other.recordingDuration == recordingDuration &&
        other.frontCameraFrame == frontCameraFrame &&
        other.frontCameraFrameWidth == frontCameraFrameWidth &&
        other.frontCameraFrameHeight == frontCameraFrameHeight &&
        other.isSavingToGallery == isSavingToGallery &&
        other.gallerySaveSuccess == gallerySaveSuccess &&
        other.gallerySaveError == gallerySaveError;
  }

  @override
  int get hashCode {
    return Object.hash(
      cameraMode,
      recordingState,
      isInitialized,
      errorMessage,
      controller,
      frontController,
      rearController,
      isFrontInitialized,
      isRearInitialized,
      recordingDuration,
      frontCameraFrame,
      frontCameraFrameWidth,
      frontCameraFrameHeight,
      isSavingToGallery,
      gallerySaveSuccess,
      gallerySaveError,
    );
  }
}
