//
//  CameraManager.swift
//  film24
//
//  Created by Igor Ryazancev on 05.01.2023.
//

import SwiftUI
import AVFoundation

class CameraManager: NSObject, ObservableObject {
    enum Status {
        case unconfigured
        case configured
        case unauthorized
        case failed
    }
    
    static let shared = CameraManager()
    
    @Published var error: CameraError?
    
    let session = AVCaptureSession()
    
    var cameraPosition: AVCaptureDevice.Position = .back
    private(set) var device: AVCaptureDevice?
    private var videoConnection: AVCaptureConnection?
    private let sessionQueue = DispatchQueue(label: "com.sessionQ")
    private let videoOutput = AVCaptureVideoDataOutput()
    private var videoFileOutput: AVCaptureMovieFileOutput?
    private var audioDevice: AVCaptureDevice?
    private var audioInput: AVCaptureDeviceInput?
    private var status = Status.unconfigured
    private var defaultZoomFactor = 1.0
    
    
    
    
    var recordedAction: ((URL)->())? = nil
    
    private override init() {
        super.init()
        
        configure()
    }
    
    private func set(error: CameraError?) {
        DispatchQueue.main.async {
            self.error = error
        }
    }
    
    private func checkPermissions() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .notDetermined:
            sessionQueue.suspend()
            AVCaptureDevice.requestAccess(for: .video) { authorized in
                if !authorized {
                    self.status = .unauthorized
                    self.set(error: .deniedAuthorization)
                }
                self.sessionQueue.resume()
            }
        case .restricted:
            status = .unauthorized
            set(error: .restrictedAuthorization)
        case .denied:
            status = .unauthorized
            set(error: .deniedAuthorization)
        case .authorized:
            break
        @unknown default:
            status = .unauthorized
            set(error: .unknownAuthorization)
        }
    }
    
    private func configureCaptureSession() {
        guard status == .unconfigured else {
            return
        }
        
        session.beginConfiguration()
        
        defer {
            session.commitConfiguration()
        }
        
        device = primaryVideoDevice(forPosition: cameraPosition)
        
        if device == nil {
            device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: cameraPosition)
        }
        
        guard let camera = device else {
            set(error: .cameraUnavailable)
            status = .failed
            return
        }
        
        do {
            let cameraInput = try AVCaptureDeviceInput(device: camera)
            if session.canAddInput(cameraInput) {
                session.addInput(cameraInput)
            } else {
                set(error: .cannotAddInput)
                status = .failed
                return
            }
        } catch {
            set(error: .createCaptureInput(error))
            status = .failed
            return
        }
        
        if session.canAddOutput(videoOutput) {
            session.addOutput(videoOutput)
            
            videoOutput.videoSettings =
            [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
            
            videoConnection = videoOutput.connection(with: .video)
            videoConnection?.videoOrientation = .portrait
            videoConnection?.isVideoMirrored = cameraPosition == .back
            
            
        } else {
            set(error: .cannotAddOutput)
            status = .failed
            return
        }
        
        // Add audio input
        if let audioDevice = self.audioDevice {
            do {
                self.audioInput = try AVCaptureDeviceInput(device: audioDevice)
                if session.canAddInput(self.audioInput!) {
                    session.addInput(self.audioInput!)
                } else {
                    status = .failed
                }
            } catch {
                status = .failed
                return
            }
        }
        
        self.videoFileOutput = AVCaptureMovieFileOutput()
        if session.canAddOutput(self.videoFileOutput!) {
            session.addOutput(self.videoFileOutput!)
        }
        
        status = .configured
        
        zoom(defaultZoomFactor)
    }
    
    private func configure() {
        checkPermissions()
        
        sessionQueue.async {
            self.configureCaptureSession()
            self.session.startRunning()
        }
    }
    
    func set(
        _ delegate: AVCaptureVideoDataOutputSampleBufferDelegate,
        queue: DispatchQueue
    ) {
        sessionQueue.async {
            self.videoOutput.setSampleBufferDelegate(delegate, queue: queue)
        }
    }
    
    func reloadCaptureSession() {
        session.stopRunning()
        session.inputs.forEach({ session.removeInput($0) })
        session.outputs.forEach({ session.removeOutput($0) })
        status = .unconfigured
        configure()
    }
    
    func autoFocus(isOn: Bool) {
        guard let camera = device else { return }
        
        if isOn && camera.isFocusModeSupported(.continuousAutoFocus) {
            try! camera.lockForConfiguration()
            camera.focusMode = .continuousAutoFocus
            camera.unlockForConfiguration()
        } else {
            try! camera.lockForConfiguration()
            camera.focusMode = .locked
            camera.unlockForConfiguration()
        }
    }
    
    func cinematic(isOn: Bool) {
        if videoConnection?.isVideoStabilizationSupported == true {
            videoConnection?.preferredVideoStabilizationMode = isOn ? .cinematic : .standard
        }
    }
    
    func exposure(_ value: CGFloat) {
        guard let camera = device else { return }
        
        let newExposureTargetOffset = Float(value)
                print("Offset is : \(newExposureTargetOffset)")

                let currentISO = device?.iso
                var biasISO = 0

                //Assume 0,01 as our limit to correct the ISO
                if newExposureTargetOffset > 0.01 { //decrease ISO
                    biasISO = -50
                } else if newExposureTargetOffset < -0.01 { //increase ISO
                    biasISO = 50
                }

        if biasISO != Int(0) {
            //Normalize ISO level for the current device
            var newISO = currentISO! + Float(biasISO)
            newISO = newISO > (device?.activeFormat.maxISO)! ? (device?.activeFormat.maxISO)! : newISO
            newISO = newISO < (device?.activeFormat.minISO)! ? (device?.activeFormat.minISO)! : newISO
            
            print(newISO)
            if camera.isExposureModeSupported(.custom) {
                do{
                    try camera.lockForConfiguration()
                    camera.setExposureModeCustom(duration: AVCaptureDevice.currentExposureDuration, iso: newISO)
                    camera.unlockForConfiguration()
                }
                catch{
                    print("ERROR: \(String(describing: error.localizedDescription))")
                }
            }
        }
    }
    
    func focus(_ point: CGPoint) {
        guard let camera = device else { return }
        
        let focus_x = point.x / UIScreen.main.bounds.width
        let focus_y = point.y / UIScreen.main.bounds.height
        
        let points = CGPoint(x: focus_x, y: focus_y)
        do{
            try camera.lockForConfiguration()
            camera.focusMode = .autoFocus
            camera.focusPointOfInterest = points
            if (camera.isExposureModeSupported(.autoExpose) && camera.isExposurePointOfInterestSupported) {
                camera.exposureMode = .autoExpose
                camera.exposurePointOfInterest = points
            }
            camera.unlockForConfiguration()
        }
        catch{
            print("ERROR: \(String(describing: error.localizedDescription))")
        }
    }
    
    func zoom(_ scale: CGFloat) {
        guard let camera = device else { return }
        
        do {
            try camera.lockForConfiguration()
            
            var minZoomFactor: CGFloat = camera.minAvailableVideoZoomFactor
            let maxZoomFactor: CGFloat = camera.maxAvailableVideoZoomFactor
            
            if camera.deviceType == .builtInDualWideCamera ||
                camera.deviceType == .builtInTripleCamera ||
                camera.deviceType == .builtInUltraWideCamera {
                minZoomFactor = 1
            }
            let zoomScale = max(minZoomFactor, min(scale, maxZoomFactor))
            camera.videoZoomFactor = zoomScale
            camera.unlockForConfiguration()
        }
        catch{
            print("ERROR: \(String(describing: error.localizedDescription))")
        }
    }
    
    func recordVideo() {
        guard session.isRunning else {
            return
        }
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let fileUrl = paths[0].appendingPathComponent("output.mp4")
        try? FileManager.default.removeItem(at: fileUrl)
        videoFileOutput?.startRecording(to: fileUrl, recordingDelegate: self)
    }
    
    func stopRecording() {
        guard session.isRunning else {
            return
        }
        self.videoFileOutput?.stopRecording()
    }
    
}

//MARK: - Private methods
private extension CameraManager {
    
    func primaryVideoDevice(forPosition position: AVCaptureDevice.Position) -> AVCaptureDevice? {
        
        let hasUltraWideCamera: Bool = true
        
        if hasUltraWideCamera && position == .back {
            defaultZoomFactor = 2.0
            let deviceTypes: [AVCaptureDevice.DeviceType] = [AVCaptureDevice.DeviceType.builtInDualWideCamera]
            let discoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: deviceTypes, mediaType: AVMediaType.video, position: position)
            return discoverySession.devices.first
        }
        
        var deviceTypes = [AVCaptureDevice.DeviceType.builtInWideAngleCamera]
        deviceTypes.append(.builtInDualCamera)
        
        let discoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: deviceTypes, mediaType: AVMediaType.video, position: position)
        for device in discoverySession.devices {
            if (device.deviceType == AVCaptureDevice.DeviceType.builtInDualCamera) {
                return device
            }
        }
        defaultZoomFactor = 1.0
        return discoverySession.devices.first
        
    }
    
}

//MARK: - AVCaptureFileOutputRecordingDelegate
extension CameraManager: AVCaptureFileOutputRecordingDelegate {
    
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        if error == nil {
            recordedAction?(outputFileURL)
        }
        print("ddddd")
    }
}
