import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:csen268_project/cubits/camera_state.dart';

class CameraCubit extends Cubit<CameraState> {
  CameraCubit() : super(const CameraState());

  void initializeCamera() {
    // TODO: 初始化相机
    emit(state.copyWith(isInitialized: true));
  }

  void switchCameraMode(CameraMode mode) {
    emit(state.copyWith(cameraMode: mode));
  }

  void takePicture() {
    // TODO: 拍照功能
    print('Taking picture...');
  }

  void toggleRecording() {
    if (state.recordingState == RecordingState.idle) {
      emit(state.copyWith(recordingState: RecordingState.recording));
      // TODO: 开始录制
    } else {
      emit(state.copyWith(recordingState: RecordingState.idle));
      // TODO: 停止录制
    }
  }

  void openGallery() {
    // TODO: 打开图库
    print('Opening gallery...');
  }

  @override
  Future<void> close() {
    // TODO: 释放相机资源
    return super.close();
  }
}
