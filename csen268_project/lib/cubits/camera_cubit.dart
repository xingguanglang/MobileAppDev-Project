import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:csen268_project/cubits/camera_state.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:photo_manager/photo_manager.dart';

class CameraCubit extends Cubit<CameraState> {
  Timer? _recordingTimer;
  Timer? _frontCameraSnapshotTimer;
  int _recordingSeconds = 0;
  bool _isInitializing = false;
  bool _isCapturingFrontFrames = false;
  DateTime? _lastFrameEmitTime;
  static const Duration _frameEmitInterval = Duration(milliseconds: 100); // Emit every 100ms (10 FPS)
  
  // Platform channels for iOS front camera frame capture
  static const MethodChannel _methodChannel = MethodChannel('com.csen268_project/front_camera');
  static const EventChannel _eventChannel = EventChannel('com.csen268_project/front_camera_frames');
  StreamSubscription? _frontCameraFrameSubscription;

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
      await _initializeSingleController(rearCamera, cameras);
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

  Future<void> _initializeSingleController(
    CameraDescription camera,
    List<CameraDescription> availableCameras,
  ) async {
    try {
      // Dispose existing controller if any
      await state.controller?.dispose();
      await state.frontController?.dispose();
      await state.rearController?.dispose();

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
        frontController: null,
        rearController: null,
        isFrontInitialized: false,
        isRearInitialized: false,
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

  Future<void> _initializeDualCameras() async {
    if (state.availableCameras.isEmpty) {
      emit(state.copyWith(
        errorMessage: 'No cameras available',
      ));
      return;
    }

    try {
      // Find front and rear cameras
      final frontCamera = state.availableCameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => throw Exception('Front camera not found'),
      );

      final rearCamera = state.availableCameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => throw Exception('Rear camera not found'),
      );

      print('📷 Initializing dual cameras...');
      print('📷 Front camera: ${frontCamera.name}');
      print('📷 Rear camera: ${rearCamera.name}');

      // Dispose existing controllers
      await state.controller?.dispose();
      await state.frontController?.dispose();
      await state.rearController?.dispose();

      // Create controllers
      final frontController = CameraController(
        frontCamera,
        ResolutionPreset.medium, // Lower resolution for front camera (small preview)
        enableAudio: false, // Only rear camera needs audio
        imageFormatGroup: ImageFormatGroup.yuv420, // YUV format needed for startImageStream
      );

      final rearController = CameraController(
        rearCamera,
        ResolutionPreset.high, // High resolution for rear camera (main preview)
        enableAudio: true,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      // Initialize both cameras in parallel
      print('📷 Initializing cameras in parallel...');
      final results = await Future.wait([
        frontController.initialize().then((_) {
          print('📷 ✅ Front camera initialized');
          return true;
        }).catchError((e) {
          print('📷 ❌ Front camera initialization failed: $e');
          return false;
        }),
        rearController.initialize().then((_) {
          print('📷 ✅ Rear camera initialized');
          return true;
        }).catchError((e) {
          print('📷 ❌ Rear camera initialization failed: $e');
          return false;
        }),
      ]);

      final frontInitialized = results[0];
      final rearInitialized = results[1];

      if (!frontInitialized && !rearInitialized) {
        // Both failed
        await frontController.dispose();
        await rearController.dispose();
        emit(state.copyWith(
          errorMessage: 'Failed to initialize both cameras',
          frontController: null,
          rearController: null,
          isFrontInitialized: false,
          isRearInitialized: false,
        ));
        return;
      }

      if (!frontInitialized) {
        // Front failed, dispose it and use only rear
        await frontController.dispose();
        emit(state.copyWith(
          errorMessage: 'Front camera failed to initialize. Using rear camera only.',
          frontController: null,
          rearController: rearController,
          isFrontInitialized: false,
          isRearInitialized: true,
        ));
        return;
      }

      if (!rearInitialized) {
        // Rear failed, dispose it and use only front
        await rearController.dispose();
        emit(state.copyWith(
          errorMessage: 'Rear camera failed to initialize. Using front camera only.',
          frontController: frontController,
          rearController: null,
          isFrontInitialized: true,
          isRearInitialized: false,
        ));
        return;
      }

      // Both initialized successfully
      print('📷 ✅ Both cameras initialized successfully');
      print('📷 Front camera - isInitialized: ${frontController.value.isInitialized}');
      print('📷 Front camera - previewSize: ${frontController.value.previewSize}');
      print('📷 Rear camera - isInitialized: ${rearController.value.isInitialized}');
      print('📷 Rear camera - previewSize: ${rearController.value.previewSize}');
      
      emit(state.copyWith(
        controller: null, // Clear single controller
        frontController: frontController,
        rearController: rearController,
        isFrontInitialized: true,
        isRearInitialized: true,
        isInitialized: false, // Use areCamerasInitialized getter instead
        errorMessage: null,
      ));
      
      // Start frame capture for front camera
      // Note: Try starting image stream before rear camera preview is fully active
      print('📷 Starting frame capture on front controller: ${frontController.description.name}');
      print('📷 Front controller lens direction: ${frontCamera.lensDirection}');
      
      // Try to start front camera stream immediately after initialization
      // Use platform channel on iOS to bypass the limitation
      if (Platform.isIOS) {
        _startFrontCameraFrameCaptureViaPlatform();
      } else {
        _startFrontCameraFrameCapture(frontController);
      }
    } catch (e, stackTrace) {
      print('📷 ❌ Error initializing dual cameras: $e');
      print('Stack trace: $stackTrace');
      emit(state.copyWith(
        errorMessage: 'Failed to initialize dual cameras: $e',
        isFrontInitialized: false,
        isRearInitialized: false,
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
      switch (mode) {
        case CameraMode.front:
          _stopFrontCameraFrameCapture();
          final targetCamera = state.availableCameras.firstWhere(
            (camera) => camera.lensDirection == CameraLensDirection.front,
            orElse: () => state.availableCameras.first,
          );
          await _initializeSingleController(targetCamera, state.availableCameras);
          emit(state.copyWith(cameraMode: mode));
          break;

        case CameraMode.rear:
          _stopFrontCameraFrameCapture();
          final targetCamera = state.availableCameras.firstWhere(
            (camera) => camera.lensDirection == CameraLensDirection.back,
            orElse: () => state.availableCameras.first,
          );
          await _initializeSingleController(targetCamera, state.availableCameras);
          emit(state.copyWith(cameraMode: mode));
          break;

        case CameraMode.dual:
          // Check if device has both front and rear cameras
          final hasFront = state.availableCameras.any(
            (camera) => camera.lensDirection == CameraLensDirection.front,
          );
          final hasRear = state.availableCameras.any(
            (camera) => camera.lensDirection == CameraLensDirection.back,
          );

          if (!hasFront || !hasRear) {
            emit(state.copyWith(
              errorMessage: 'Dual camera mode requires both front and rear cameras. This device does not support it.',
              cameraMode: mode,
            ));
            return;
          }

          // Initialize dual cameras
          await _initializeDualCameras();
          emit(state.copyWith(cameraMode: mode));
          break;
      }
    } catch (e) {
      print('📷 ❌ Error switching camera mode: $e');
      emit(state.copyWith(
        errorMessage: 'Failed to switch camera: $e',
      ));
    }
  }

  Future<void> takePicture() async {
    CameraController? activeController;

    // Determine which controller to use based on mode
    if (state.cameraMode == CameraMode.dual) {
      // In dual mode, use rear camera (main camera) for taking picture
      if (state.rearController == null || !state.rearController!.value.isInitialized) {
        emit(state.copyWith(
          errorMessage: 'Rear camera not initialized',
        ));
        return;
      }
      activeController = state.rearController;
    } else {
      // Single camera mode
      if (state.controller == null || !state.controller!.value.isInitialized) {
        emit(state.copyWith(
          errorMessage: 'Camera not initialized',
        ));
        return;
      }
      activeController = state.controller;
    }

    try {
      final XFile image = await activeController!.takePicture();

      // Get temporary directory
      final Directory appDocDir = await getApplicationDocumentsDirectory();
      final String fileName = path.basename(image.path);
      final String savedPath = path.join(appDocDir.path, fileName);

      // Copy file to app documents directory
      await image.saveTo(savedPath);

      emit(state.copyWith(
        lastCapturedImagePath: savedPath,
        errorMessage: null,
        gallerySaveSuccess: null,
        gallerySaveError: null,
      ));

      // Save to gallery asynchronously
      await _saveImageToGallery(savedPath);
    } catch (e) {
      emit(state.copyWith(
        errorMessage: 'Failed to take picture: $e',
        gallerySaveSuccess: null,
        gallerySaveError: null,
      ));
    }
  }

  /// Check and request photo library permission
  Future<bool> _checkPhotoLibraryPermission() async {
    try {
      // Use photo_manager's permission API for better cross-platform support
      final PermissionState permissionState = await PhotoManager.requestPermissionExtend();
      
      if (permissionState == PermissionState.authorized || 
          permissionState == PermissionState.limited) {
        print('📷 ✅ Photo library permission granted');
        return true;
      } else {
        print('📷 ❌ Photo library permission denied: $permissionState');
        return false;
      }
    } catch (e) {
      print('📷 ❌ Error checking photo library permission: $e');
      return false;
    }
  }

  /// Save image to device photo gallery
  Future<void> _saveImageToGallery(String imagePath) async {
    // Check permission first
    final hasPermission = await _checkPhotoLibraryPermission();
    if (!hasPermission) {
      emit(state.copyWith(
        isSavingToGallery: false,
        gallerySaveSuccess: false,
        gallerySaveError: 'Photo library permission denied. Please enable it in Settings.',
      ));
      return;
    }

    try {
      emit(state.copyWith(
        isSavingToGallery: true,
        gallerySaveSuccess: null,
        gallerySaveError: null,
      ));

      print('📷 Saving image to gallery: $imagePath');
      
      // Read image file as bytes
      final File imageFile = File(imagePath);
      if (!await imageFile.exists()) {
        throw Exception('Image file not found: $imagePath');
      }

      final Uint8List imageBytes = await imageFile.readAsBytes();
      
      // Generate filename with timestamp
      final String fileName = 'IMG_${DateTime.now().millisecondsSinceEpoch}${path.extension(imagePath)}';
      
      // Save to gallery using photo_manager
      final AssetEntity? savedAsset = await PhotoManager.editor.saveImage(
        imageBytes,
        title: path.basenameWithoutExtension(fileName),
        filename: fileName,
      );

      if (savedAsset != null) {
        print('📷 ✅ Image saved to gallery successfully: ${savedAsset.id}');
        emit(state.copyWith(
          isSavingToGallery: false,
          gallerySaveSuccess: true,
          gallerySaveError: null,
        ));
      } else {
        throw Exception('Failed to save image: savedAsset is null');
      }
    } catch (e, stackTrace) {
      print('📷 ❌ Error saving image to gallery: $e');
      print('📷 Stack trace: $stackTrace');
      emit(state.copyWith(
        isSavingToGallery: false,
        gallerySaveSuccess: false,
        gallerySaveError: 'Failed to save to gallery: $e',
      ));
    }
  }

  /// Reset gallery save status to prevent duplicate notifications
  void resetGallerySaveStatus() {
    emit(state.copyWith(
      gallerySaveSuccess: null,
      gallerySaveError: null,
    ));
  }

  Future<void> toggleRecording() async {
    CameraController? activeController;

    // Determine which controller to use based on mode
    if (state.cameraMode == CameraMode.dual) {
      // In dual mode, use rear camera (main camera) for recording
      if (state.rearController == null || !state.rearController!.value.isInitialized) {
        emit(state.copyWith(
          errorMessage: 'Rear camera not initialized',
        ));
        return;
      }
      activeController = state.rearController;
    } else {
      // Single camera mode
      if (state.controller == null || !state.controller!.value.isInitialized) {
        emit(state.copyWith(
          errorMessage: 'Camera not initialized',
        ));
        return;
      }
      activeController = state.controller;
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
        await activeController!.startVideoRecording();
        _recordingSeconds = 0;
        _startRecordingTimer();

        emit(state.copyWith(
          recordingState: RecordingState.recording,
          recordingDuration: 0,
          errorMessage: null,
        ));
      } else {
        // Stop recording
        final XFile videoFile = await activeController!.stopVideoRecording();
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

  Future<void> _startFrontCameraFrameCapture(CameraController controller) async {
    if (!controller.value.isInitialized) {
      print('📷 Front camera not initialized, cannot start frame capture');
      return;
    }

    if (_isCapturingFrontFrames) {
      print('📷 Front camera frame capture already running');
      return;
    }

    print('📷 Starting front camera frame capture...');
    print('📷 Controller description: ${controller.description.name}');
    print('📷 Controller lens direction: ${controller.description.lensDirection}');
    _stopFrontCameraFrameCapture(); // Stop any existing stream

    // iOS limitation: In dual camera mode, startImageStream may return rear camera frames
    // even when called on front controller. This is a known iOS AVCaptureSession limitation.
    // However, we'll try it anyway - sometimes it works depending on initialization order.
    
    try {
      _isCapturingFrontFrames = true;
      print('📷 Attempting to start image stream on front camera...');
      print('📷 Note: iOS may return rear camera frames due to system limitations');
      
      await controller.startImageStream((CameraImage image) {
        // Log frame info to help debug
        print('📷 Frame received: ${image.width}x${image.height}, format: ${image.format.group}');
        print('📷 Expected from: ${controller.description.name} (${controller.description.lensDirection})');
        
        // Process the frame - even if it's from rear camera, we'll display it
        // The user can verify if it's actually front or rear camera
        _processCameraImage(image);
      });
      
      print('📷 ✅ Front camera image stream started');
      print('📷 ⚠️  If frames show rear camera view, this is an iOS limitation');
    } catch (e) {
      print('📷 ❌ Error starting front camera image stream: $e');
      _isCapturingFrontFrames = false;
      
      // Emit null to show no frame data available
      emit(state.copyWith(
        frontCameraFrame: null,
        frontCameraFrameWidth: null,
        frontCameraFrameHeight: null,
      ));
    }
  }

  Future<void> _startFrontCameraFrameCaptureViaPlatform() async {
    if (_isCapturingFrontFrames) {
      print('📷 Front camera frame capture already running');
      return;
    }

    print('📷 Starting front camera frame capture via platform channel (iOS)...');
    _stopFrontCameraFrameCapture(); // Stop any existing stream

    try {
      // Start native iOS frame capture
      final result = await _methodChannel.invokeMethod<bool>('startFrontCameraFrameCapture');
      if (result != true) {
        print('📷 ❌ Failed to start front camera frame capture via platform');
        return;
      }

      _isCapturingFrontFrames = true;
      print('📷 ✅ Native front camera frame capture started');

      // Listen to frame data stream
      _frontCameraFrameSubscription = _eventChannel.receiveBroadcastStream().listen(
        (dynamic event) {
          try {
            if (event is Map) {
              final typedData = event['data'];
              Uint8List? data;
              if (typedData is Uint8List) {
                data = typedData;
              } else if (typedData is List<int>) {
                data = Uint8List.fromList(typedData);
              }
              
              final width = event['width'] as int?;
              final height = event['height'] as int?;

              if (data != null && width != null && height != null) {
                // Throttle frame updates
                final now = DateTime.now();
                if (_lastFrameEmitTime != null &&
                    now.difference(_lastFrameEmitTime!) < _frameEmitInterval) {
                  return;
                }

                _lastFrameEmitTime = now;
                print('📷 Received frame from platform: ${width}x${height}, ${data.length} bytes');

                emit(state.copyWith(
                  frontCameraFrame: data,
                  frontCameraFrameWidth: width,
                  frontCameraFrameHeight: height,
                ));
              } else {
                print('📷 ⚠️ Invalid frame data format: data=${data != null}, width=$width, height=$height');
              }
            } else {
              print('📷 ⚠️ Unexpected event type: ${event.runtimeType}');
            }
          } catch (e) {
            print('📷 ❌ Error processing frame data: $e');
          }
        },
        onError: (error) {
          print('📷 ❌ Error receiving front camera frames: $error');
        },
      );
    } catch (e) {
      print('📷 ❌ Error starting front camera frame capture via platform: $e');
      _isCapturingFrontFrames = false;
    }
  }

  void _stopFrontCameraFrameCapture() {
    if (_isCapturingFrontFrames) {
      print('📷 Stopping front camera frame capture...');
      try {
        // Stop platform channel stream
        _frontCameraFrameSubscription?.cancel();
        _frontCameraFrameSubscription = null;

        // Stop snapshot timer if running
        _frontCameraSnapshotTimer?.cancel();
        _frontCameraSnapshotTimer = null;
        
        // Stop native iOS frame capture
        if (Platform.isIOS) {
          _methodChannel.invokeMethod('stopFrontCameraFrameCapture');
        }
        
        // Try to stop on front controller if available
        if (state.frontController != null) {
          try {
            state.frontController!.stopImageStream();
            print('📷 Stopped stream on front controller: ${state.frontController!.description.name}');
          } catch (e) {
            print('📷 Note: stopImageStream error (may not be running): $e');
          }
        }
        _isCapturingFrontFrames = false;
        emit(state.copyWith(
          frontCameraFrame: null,
          frontCameraFrameWidth: null,
          frontCameraFrameHeight: null,
        ));
      } catch (e) {
        print('📷 ❌ Error stopping front camera frame capture: $e');
        _isCapturingFrontFrames = false;
      }
    }
  }

  void _processCameraImage(CameraImage image) {
    // Convert CameraImage to a displayable format
    // For simplicity, we'll use the Y plane (luminance) and convert to grayscale
    // In a production app, you might want to convert to RGB or use a proper image format
    
    try {
      // Throttle frame updates to avoid overwhelming the UI
      final now = DateTime.now();
      if (_lastFrameEmitTime != null && 
          now.difference(_lastFrameEmitTime!) < _frameEmitInterval) {
        // Skip this frame if too soon since last emit
        return;
      }
      
      if (image.planes.isEmpty) {
        print('📷 ❌ No planes in camera image');
        return;
      }
      
      // For BGRA8888 format, we can use the plane data directly
      final plane = image.planes[0];
      final bytes = plane.bytes;
      
      // Create a Uint8List from the bytes
      final frameData = Uint8List.fromList(bytes);
      
      // Update last emit time
      _lastFrameEmitTime = now;
      
      print('📷 Emitting frame data: ${frameData.length} bytes, ${image.width}x${image.height} (throttled to ~10 FPS)');
      
      // Emit the frame data with dimensions
      emit(state.copyWith(
        frontCameraFrame: frameData,
        frontCameraFrameWidth: image.width,
        frontCameraFrameHeight: image.height,
      ));
      
    } catch (e, stackTrace) {
      print('📷 ❌ Error processing camera image: $e');
      print('📷 Stack trace: $stackTrace');
    }
  }

  // Note: Navigation should be handled in the UI layer, not in the cubit
  // This method is kept for compatibility but navigation should be done in the page

  @override
  Future<void> close() {
    _stopRecordingTimer();
    _frontCameraSnapshotTimer?.cancel();
    _frontCameraFrameSubscription?.cancel();
    _stopFrontCameraFrameCapture();
    // Dispose all controllers
    state.controller?.dispose();
    state.frontController?.dispose();
    state.rearController?.dispose();
    return super.close();
  }
}
