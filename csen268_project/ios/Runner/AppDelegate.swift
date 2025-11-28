import Flutter
import UIKit
import AVFoundation

@main
@objc class AppDelegate: FlutterAppDelegate {
  private var frontCameraMethodChannel: FlutterMethodChannel?
  private var frontCameraEventChannel: FlutterEventChannel?
  private var frontCameraEventSink: FlutterEventSink?
  private var frontCameraSession: AVCaptureSession?
  private var frontCameraOutput: AVCaptureVideoDataOutput?
  private var frontCameraDevice: AVCaptureDevice?
  private var streamHandler: FrontCameraStreamHandler?
  
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let controller = window?.rootViewController as! FlutterViewController
    
    // Setup method channel for controlling front camera
    frontCameraMethodChannel = FlutterMethodChannel(
      name: "com.csen268_project/front_camera",
      binaryMessenger: controller.binaryMessenger
    )
    
    frontCameraMethodChannel?.setMethodCallHandler { [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) in
      guard let self = self else { return }
      
      switch call.method {
      case "startFrontCameraFrameCapture":
        self.startFrontCameraFrameCapture(result: result)
      case "stopFrontCameraFrameCapture":
        self.stopFrontCameraFrameCapture(result: result)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
    
    // Setup event channel for streaming frame data
    streamHandler = FrontCameraStreamHandler()
    streamHandler?.onSinkSet = { [weak self] sink in
      self?.frontCameraEventSink = sink
    }
    
    frontCameraEventChannel = FlutterEventChannel(
      name: "com.csen268_project/front_camera_frames",
      binaryMessenger: controller.binaryMessenger
    )
    
    frontCameraEventChannel?.setStreamHandler(streamHandler)
    
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  private func startFrontCameraFrameCapture(result: @escaping FlutterResult) {
    // Check camera permission
    AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
      guard let self = self, granted else {
        result(FlutterError(code: "PERMISSION_DENIED", message: "Camera permission denied", details: nil))
        return
      }
      
      DispatchQueue.main.async {
        do {
          // Find front camera
          guard let frontCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) else {
            result(FlutterError(code: "NO_CAMERA", message: "Front camera not found", details: nil))
            return
          }
          
          self.frontCameraDevice = frontCamera
          
          // Create capture session
          let session = AVCaptureSession()
          session.sessionPreset = .medium
          
          // Create input
          let input = try AVCaptureDeviceInput(device: frontCamera)
          guard session.canAddInput(input) else {
            result(FlutterError(code: "CANNOT_ADD_INPUT", message: "Cannot add camera input", details: nil))
            return
          }
          session.addInput(input)
          
          // Create output
          let output = AVCaptureVideoDataOutput()
          output.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
          ]
          output.setSampleBufferDelegate(self, queue: DispatchQueue(label: "frontCameraQueue"))
          
          guard session.canAddOutput(output) else {
            result(FlutterError(code: "CANNOT_ADD_OUTPUT", message: "Cannot add camera output", details: nil))
            return
          }
          session.addOutput(output)
          
          self.frontCameraSession = session
          self.frontCameraOutput = output
          
          // Start session
          session.startRunning()
          
          result(true)
        } catch {
          result(FlutterError(code: "ERROR", message: error.localizedDescription, details: nil))
        }
      }
    }
  }
  
  private func stopFrontCameraFrameCapture(result: @escaping FlutterResult) {
    frontCameraSession?.stopRunning()
    frontCameraSession = nil
    frontCameraOutput = nil
    frontCameraDevice = nil
    frontCameraEventSink = nil
    result(true)
  }
}

// Event channel stream handler
class FrontCameraStreamHandler: NSObject, FlutterStreamHandler {
  var onSinkSet: ((FlutterEventSink?) -> Void)?
  
  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    onSinkSet?(events)
    return nil
  }
  
  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    onSinkSet?(nil)
    return nil
  }
}

extension AppDelegate: AVCaptureVideoDataOutputSampleBufferDelegate {
  func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
    guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
    
    CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
    defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly) }
    
    let width = CVPixelBufferGetWidth(pixelBuffer)
    let height = CVPixelBufferGetHeight(pixelBuffer)
    let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)
    
    guard let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer) else { return }
    
    let data = Data(bytes: baseAddress, count: height * bytesPerRow)
    
    // Send frame data to Flutter via event channel
    // Throttle to avoid overwhelming the channel
    DispatchQueue.main.async { [weak self] in
      guard let sink = self?.frontCameraEventSink else { return }
      let typedData = FlutterStandardTypedData(bytes: data)
      sink([
        "data": typedData,
        "width": width,
        "height": height
      ] as [String: Any])
    }
  }
}
