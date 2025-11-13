import 'package:camera/camera.dart';

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
  final CameraController? controller;
  final List<CameraDescription> availableCameras;
  final int? recordingDuration; // in seconds
  final String? lastCapturedImagePath;
  final String? lastRecordedVideoPath;

  const CameraState({
    this.cameraMode = CameraMode.rear,
    this.recordingState = RecordingState.idle,
    this.isInitialized = false,
    this.errorMessage,
    this.controller,
    this.availableCameras = const [],
    this.recordingDuration,
    this.lastCapturedImagePath,
    this.lastRecordedVideoPath,
  });

  CameraState copyWith({
    CameraMode? cameraMode,
    RecordingState? recordingState,
    bool? isInitialized,
    String? errorMessage,
    CameraController? controller,
    List<CameraDescription>? availableCameras,
    int? recordingDuration,
    String? lastCapturedImagePath,
    String? lastRecordedVideoPath,
  }) {
    return CameraState(
      cameraMode: cameraMode ?? this.cameraMode,
      recordingState: recordingState ?? this.recordingState,
      isInitialized: isInitialized ?? this.isInitialized,
      errorMessage: errorMessage,
      controller: controller ?? this.controller,
      availableCameras: availableCameras ?? this.availableCameras,
      recordingDuration: recordingDuration ?? this.recordingDuration,
      lastCapturedImagePath: lastCapturedImagePath ?? this.lastCapturedImagePath,
      lastRecordedVideoPath: lastRecordedVideoPath ?? this.lastRecordedVideoPath,
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
        other.recordingDuration == recordingDuration;
  }

  @override
  int get hashCode {
    return Object.hash(
      cameraMode,
      recordingState,
      isInitialized,
      errorMessage,
      controller,
      recordingDuration,
    );
  }
}
