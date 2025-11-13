import 'dart:async';
import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:csen268_project/cubits/camera_state.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class CameraCubit extends Cubit<CameraState> {
  Timer? _recordingTimer;
  int _recordingSeconds = 0;
  bool _isInitializing = false;

  CameraCubit() : super(const CameraState());

  Future<void> initializeCamera() async {
    if (_isInitializing || state.isInitialized) {
      print('📷 Camera already initializing or initialized, skipping...');
      return;
    }

    _isInitializing = true;
    try {
      // Check current permission status first
      final currentStatus = await Permission.camera.status;
      print('📷 Camera permission status: $currentStatus');
      print('📷 Is granted: ${currentStatus.isGranted}');
      print('📷 Is denied: ${currentStatus.isDenied}');
      print('📷 Is permanently denied: ${currentStatus.isPermanentlyDenied}');
      print('📷 Is restricted: ${currentStatus.isRestricted}');
      print('📷 Is limited: ${currentStatus.isLimited}');

      // Request camera permission if not already granted
      PermissionStatus cameraStatus;
      if (currentStatus.isGranted) {
        print('📷 Permission already granted, proceeding...');
        cameraStatus = currentStatus;
      } else if (currentStatus.isPermanentlyDenied) {
        print('📷 Permission permanently denied, cannot request again');
        emit(state.copyWith(
          errorMessage: 'Camera permission permanently denied. Please enable it in Settings.',
          isInitialized: false,
        ));
        return;
      } else {
        print('📷 Requesting camera permission...');
        cameraStatus = await Permission.camera.request();
        print('📷 Camera permission request result: $cameraStatus');
        print('📷 Request result - Is granted: ${cameraStatus.isGranted}');
        print('📷 Request result - Is denied: ${cameraStatus.isDenied}');
        print('📷 Request result - Is permanently denied: ${cameraStatus.isPermanentlyDenied}');
      }

      if (!cameraStatus.isGranted) {
        String errorMsg = 'Camera permission denied';
        if (cameraStatus.isPermanentlyDenied) {
          errorMsg = 'Camera permission permanently denied. Please enable it in Settings.';
        } else if (cameraStatus.isDenied) {
          errorMsg = 'Camera permission denied. Please grant camera access.';
        } else if (cameraStatus.isRestricted) {
          errorMsg = 'Camera access is restricted on this device.';
        }
        print('📷 ❌ Permission not granted: $errorMsg');
        emit(state.copyWith(
          errorMessage: errorMsg,
          isInitialized: false,
        ));
        return;
      }

      print('📷 ✅ Permission granted! Proceeding to get cameras...');

      // Get available cameras
      print('Getting available cameras...');
      final cameras = await availableCameras();
      print('Found ${cameras.length} cameras');
      
      if (cameras.isEmpty) {
        emit(state.copyWith(
          errorMessage: 'No cameras available on this device',
          isInitialized: false,
        ));
        return;
      }

      // Initialize with rear camera by default
      final rearCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      print('Initializing camera: ${rearCamera.name} (${rearCamera.lensDirection})');
      await _initializeController(rearCamera, cameras);
    } catch (e, stackTrace) {
      print('Error initializing camera: $e');
      print('Stack trace: $stackTrace');
      emit(state.copyWith(
        errorMessage: 'Failed to initialize camera: $e',
        isInitialized: false,
      ));
    } finally {
      _isInitializing = false;
    }
  }

  Future<void> _initializeController(
    CameraDescription camera,
    List<CameraDescription> availableCameras,
  ) async {
    try {
      // Dispose existing controller if any
      await state.controller?.dispose();

      print('Creating CameraController...');
      final controller = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: true,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      print('Initializing CameraController...');
      await controller.initialize();
      print('CameraController initialized successfully');

      emit(state.copyWith(
        controller: controller,
        availableCameras: availableCameras,
        isInitialized: true,
        errorMessage: null,
      ));
    } catch (e, stackTrace) {
      print('Error initializing camera controller: $e');
      print('Stack trace: $stackTrace');
      emit(state.copyWith(
        errorMessage: 'Failed to initialize camera controller: $e',
        isInitialized: false,
      ));
    }
  }

  Future<void> switchCameraMode(CameraMode mode) async {
    if (state.availableCameras.isEmpty) {
      emit(state.copyWith(
        errorMessage: 'No cameras available',
      ));
      return;
    }

    try {
      CameraDescription? targetCamera;

      switch (mode) {
        case CameraMode.front:
          targetCamera = state.availableCameras.firstWhere(
            (camera) => camera.lensDirection == CameraLensDirection.front,
            orElse: () => state.availableCameras.first,
          );
          break;
        case CameraMode.rear:
          targetCamera = state.availableCameras.firstWhere(
            (camera) => camera.lensDirection == CameraLensDirection.back,
            orElse: () => state.availableCameras.first,
          );
          break;
        case CameraMode.dual:
          // Dual camera mode is not directly supported by camera package
          // For now, we'll use rear camera and show a message
          targetCamera = state.availableCameras.firstWhere(
            (camera) => camera.lensDirection == CameraLensDirection.back,
            orElse: () => state.availableCameras.first,
          );
          emit(state.copyWith(
            errorMessage: 'Dual camera mode not fully supported. Using rear camera.',
          ));
          break;
      }

      await _initializeController(targetCamera, state.availableCameras);
      emit(state.copyWith(cameraMode: mode));
    } catch (e) {
      emit(state.copyWith(
        errorMessage: 'Failed to switch camera: $e',
      ));
    }
  }

  Future<void> takePicture() async {
    if (state.controller == null || !state.controller!.value.isInitialized) {
      emit(state.copyWith(
        errorMessage: 'Camera not initialized',
      ));
      return;
    }

    try {
      final XFile image = await state.controller!.takePicture();

      // Get temporary directory
      final Directory appDocDir = await getApplicationDocumentsDirectory();
      final String fileName = path.basename(image.path);
      final String savedPath = path.join(appDocDir.path, fileName);

      // Copy file to app documents directory
      await image.saveTo(savedPath);

      emit(state.copyWith(
        lastCapturedImagePath: savedPath,
        errorMessage: null,
      ));
    } catch (e) {
      emit(state.copyWith(
        errorMessage: 'Failed to take picture: $e',
      ));
    }
  }

  Future<void> toggleRecording() async {
    if (state.controller == null || !state.controller!.value.isInitialized) {
      emit(state.copyWith(
        errorMessage: 'Camera not initialized',
      ));
      return;
    }

    try {
      if (state.recordingState == RecordingState.idle) {
        // Request microphone permission for recording
        final micStatus = await Permission.microphone.request();
        if (!micStatus.isGranted) {
          emit(state.copyWith(
            errorMessage: 'Microphone permission denied',
          ));
          return;
        }

        // Start recording
        await state.controller!.startVideoRecording();
        _recordingSeconds = 0;
        _startRecordingTimer();

        emit(state.copyWith(
          recordingState: RecordingState.recording,
          recordingDuration: 0,
          errorMessage: null,
        ));
      } else {
        // Stop recording
        final XFile videoFile = await state.controller!.stopVideoRecording();
        _stopRecordingTimer();

        // Get temporary directory
        final Directory appDocDir = await getApplicationDocumentsDirectory();
        final String fileName = path.basename(videoFile.path);
        final String savedPath = path.join(appDocDir.path, fileName);

        // Copy file to app documents directory
        await videoFile.saveTo(savedPath);

        emit(state.copyWith(
          recordingState: RecordingState.idle,
          recordingDuration: null,
          lastRecordedVideoPath: savedPath,
          errorMessage: null,
        ));
      }
    } catch (e) {
      _stopRecordingTimer();
      emit(state.copyWith(
        recordingState: RecordingState.idle,
        recordingDuration: null,
        errorMessage: 'Failed to record video: $e',
      ));
    }
  }

  void _startRecordingTimer() {
    _recordingTimer?.cancel();
    _recordingSeconds = 0;
    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _recordingSeconds++;
      emit(state.copyWith(recordingDuration: _recordingSeconds));
    });
  }

  void _stopRecordingTimer() {
    _recordingTimer?.cancel();
    _recordingTimer = null;
    _recordingSeconds = 0;
  }

  // Note: Navigation should be handled in the UI layer, not in the cubit
  // This method is kept for compatibility but navigation should be done in the page

  @override
  Future<void> close() {
    _stopRecordingTimer();
    state.controller?.dispose();
    return super.close();
  }
}
