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

  const CameraState({
    this.cameraMode = CameraMode.rear,
    this.recordingState = RecordingState.idle,
    this.isInitialized = false,
    this.errorMessage,
  });

  CameraState copyWith({
    CameraMode? cameraMode,
    RecordingState? recordingState,
    bool? isInitialized,
    String? errorMessage,
  }) {
    return CameraState(
      cameraMode: cameraMode ?? this.cameraMode,
      recordingState: recordingState ?? this.recordingState,
      isInitialized: isInitialized ?? this.isInitialized,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CameraState &&
        other.cameraMode == cameraMode &&
        other.recordingState == recordingState &&
        other.isInitialized == isInitialized &&
        other.errorMessage == errorMessage;
  }

  @override
  int get hashCode {
    return Object.hash(cameraMode, recordingState, isInitialized, errorMessage);
  }
}
