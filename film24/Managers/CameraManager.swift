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
    var slowModeValue: CGFloat = 0 {
        didSet {
//            DispatchQueue.main.async { [weak self] in
//                guard let `self` = self else { return }
//                self.setFrameRate(self.slowModeValue != 0 ? 60 : 30) {
//                    self.zoom(self.defaultZoomFactor)
//                }
//            }
            
        }
    }
    private(set) var device: AVCaptureDevice?
    private var videoConnection: AVCaptureConnection?
    private let sessionQueue = DispatchQueue(label: "com.sessionQ")
    private let videoOutput = AVCaptureVideoDataOutput()
    private var videoFileOutput: AVCaptureMovieFileOutput?
    private var audioDevice: AVCaptureDevice?
    private var audioInput: AVCaptureDeviceInput?
    private var status = Status.unconfigured
    private var defaultZoomFactor = 1.0
    
    /// Recorder
    private static let deviceRgbColorSpace = CGColorSpaceCreateDeviceRGB()
    private static let tempVideoFilename = "recording"
    private static let tempVideoFileExtention = "mov"
    
    let colorSpace: CGColorSpace = CGColorSpace.init(name: CGColorSpace.sRGB) ?? CGColorSpaceCreateDeviceRGB()
    var LUT: CIFilter?
    
    private var ciContext: CIContext!
    private var videoWritingStarted = false
    private var videoWritingStartTime = CMTime()
    private(set) var assetWriter: AVAssetWriter?
    private var assetWriterAudioInput: AVAssetWriterInput?
    private var assetWriterVideoInput: AVAssetWriterInput?
    private var assetWriterInputPixelBufferAdaptor: AVAssetWriterInputPixelBufferAdaptor?

    private var currentAudioSampleBufferFormatDescription: CMFormatDescription?
    private var currentVideoDimensions: CMVideoDimensions?
    private var currentVideoTime = CMTime()
    
    private let frameRateCalculator = FrameRateCalculator()
    private var timer: Timer?
    private let timerUpdateInterval = 0.25

    private var temporaryVideoFileURL: URL {
        return URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent(CameraManager.tempVideoFilename)
            .appendingPathExtension(CameraManager.tempVideoFileExtention)
    }
    
    private var origVideoURL: URL? = nil
    
    var recordingSeconds: Int {
        guard assetWriter != nil else { return 0 }
        let diff = currentVideoTime - videoWritingStartTime
        let seconds = CMTimeGetSeconds(diff)
        guard !(seconds.isNaN || seconds.isInfinite) else { return 0 }
        return Int(seconds)
    }

    ///
    
    var recordedAction: ((URL, URL?)->())? = nil
    
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
        
        let deviceTypes: [AVCaptureDevice.DeviceType]
        deviceTypes = [.builtInTripleCamera, .builtInDualWideCamera, .builtInDualCamera, .builtInWideAngleCamera]
        
        let discoverySession = AVCaptureDevice.DiscoverySession(
            deviceTypes: deviceTypes,
            mediaType: .video,
            position: cameraPosition
        )
        
        device = discoverySession.devices.first
        
        if cameraPosition == .back && device?.deviceType == .builtInTripleCamera ||
            cameraPosition == .back && device?.deviceType == .builtInDualWideCamera {
            defaultZoomFactor = 2
        } else {
            defaultZoomFactor = 1
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
        
        self.zoom(self.defaultZoomFactor)
//        setFrameRate(30) { [weak self] in
//            guard let `self` = self else { return }
//            self.zoom(self.defaultZoomFactor)
//        }
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
        } else if camera.isFocusModeSupported(.locked) {
            try! camera.lockForConfiguration()
            camera.focusMode = .locked
            camera.unlockForConfiguration()
        } else if camera.isFocusModeSupported(.autoFocus) {
            try! camera.lockForConfiguration()
            camera.focusMode = .autoFocus
            camera.unlockForConfiguration()
        }
    }
    
    func cinematic(_ cinematicMode: LocalSettings.Stabilisation) {
        guard videoConnection?.isVideoStabilizationSupported == true else { return }
        
        switch cinematicMode {
        case .off:
            videoConnection?.preferredVideoStabilizationMode = .off
        case .standard:
            videoConnection?.preferredVideoStabilizationMode = .standard
        case .cinematic:
            videoConnection?.preferredVideoStabilizationMode = .cinematic
        }
    }
    
    func exposure(_ value: CGFloat) {
        guard let camera = device else { return }
        
        
        let minBias = camera.minExposureTargetBias
        let maxBias = camera.maxExposureTargetBias
        
        let newBias = max(minBias, min(Float(value*1.5), maxBias))
        
        do{
            try camera.lockForConfiguration()
            camera.setExposureTargetBias(newBias)
            camera.unlockForConfiguration()
        }
        catch{
            print("ERROR: \(String(describing: error.localizedDescription))")
        }
    }
    
    func focus(_ point: CGPoint, vSize: CGSize) {
        guard let camera = device else { return }
        guard cameraPosition == .back else { return }
        
        let focus_x = (vSize.width-point.x) / vSize.width
        let focus_y = (point.y) / vSize.height
        
        let points = CGPoint(x: focus_y, y: focus_x)
        
        do{
            try camera.lockForConfiguration()
            if camera.isFocusModeSupported(.autoFocus) {
                camera.focusPointOfInterest = points
                camera.focusMode = .autoFocus
                
            } else if camera.isFocusModeSupported(.continuousAutoFocus) {
                camera.focusPointOfInterest = points
                camera.focusMode = .continuousAutoFocus
                
            }

            if (camera.isExposureModeSupported(.autoExpose) && camera.isExposurePointOfInterestSupported) {
                camera.exposurePointOfInterest = points
                camera.exposureMode = .autoExpose
                
            }
            //camera.setFocusModeLocked(lensPosition: <#T##Float#>)
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
            
            if camera.deviceType == .builtInTripleCamera  {
                minZoomFactor = 0.5
            } else if camera.deviceType == .builtInDualWideCamera ||
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
    
    func recordOrigVideo() {
        guard session.isRunning else {
            return
        }
        origVideoURL = nil
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let fileUrl = paths[0].appendingPathComponent("output.mp4")
        try? FileManager.default.removeItem(at: fileUrl)
        origVideoURL = fileUrl
        videoFileOutput?.startRecording(to: fileUrl, recordingDelegate: self)
    }
    
    func stopOrigRecording() {
        guard session.isRunning else {
            return
        }
        self.videoFileOutput?.stopRecording()
    }
    
    func setFrameRate(_ rate: Double, completion: @escaping ()->  Void) {
        if let device {
            guard rate == 60 else {
                do {
                    try device.lockForConfiguration()
                    device.activeVideoMinFrameDuration = CMTime(value: 1, timescale: 30)
                    device.activeVideoMaxFrameDuration = CMTime(value: 1, timescale: 30)
                    device.unlockForConfiguration()
                    completion()
                }
                catch {
                    print(error)
                    completion()
                }
                return
            }
            
            Task {
                for vFormat in device.formats {
                    let ranges = vFormat.videoSupportedFrameRateRanges as [AVFrameRateRange]
                    let frameRates = ranges[0]
                    
                    if frameRates.maxFrameRate == rate {
                        do {
                            try device.lockForConfiguration()
                            device.activeFormat = vFormat as AVCaptureDevice.Format
                            device.activeVideoMinFrameDuration = frameRates.minFrameDuration
                            device.activeVideoMaxFrameDuration = frameRates.maxFrameDuration
                            device.unlockForConfiguration()
                        }
                        catch {
                            print(error)
                        }
                    }
                }
                completion()
            }
        }
    }
    
}

//MARK: - Private methods
private extension CameraManager {
    
    func primaryVideoDevice(forPosition position: AVCaptureDevice.Position) -> AVCaptureDevice? {
        
        let hasUltraWideCamera: Bool = true
        
        if hasUltraWideCamera && position == .back {
            defaultZoomFactor = 2.0
            let deviceTypes: [AVCaptureDevice.DeviceType] = [.builtInUltraWideCamera, .builtInTripleCamera, .builtInDualWideCamera]
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
            origVideoURL = outputFileURL
        }
    }
}

//Recorder
extension CameraManager {
    
    private func makeAssetWriter() -> AVAssetWriter? {
        do {
            return try AVAssetWriter(url: temporaryVideoFileURL, fileType: .mov)
        } catch {
            return nil
        }
    }

    private func makeAssetWriterVideoInput() -> AVAssetWriterInput {
        let settings: [String: Any] = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: currentVideoDimensions?.width ?? 0,
            AVVideoHeightKey: currentVideoDimensions?.height ?? 0,
        ]
        
        let input = AVAssetWriterInput(mediaType: .video, outputSettings: settings)
        input.expectsMediaDataInRealTime = true
        return input
    }

    // create a pixel buffer adaptor for the asset writer; we need to obtain pixel buffers for rendering later from its pixel buffer pool
    private func makeAssetWriterInputPixelBufferAdaptor(with input: AVAssetWriterInput) -> AVAssetWriterInputPixelBufferAdaptor {
        let attributes: [String: Any] = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
            kCVPixelBufferWidthKey as String: currentVideoDimensions?.width ?? 0,
            kCVPixelBufferHeightKey as String: currentVideoDimensions?.height ?? 0,
            kCVPixelFormatOpenGLESCompatibility as String: kCFBooleanTrue!,
        ]
        return AVAssetWriterInputPixelBufferAdaptor(
            assetWriterInput: input,
            sourcePixelBufferAttributes: attributes
        )
    }

    private func makeAudioCompressionSettings() -> [String: Any]? {
        guard let currentAudioSampleBufferFormatDescription = self.currentAudioSampleBufferFormatDescription else {
            return nil
        }

        let channelLayoutData: Data
        var layoutSize: size_t = 0
        if let channelLayout = CMAudioFormatDescriptionGetChannelLayout(currentAudioSampleBufferFormatDescription, sizeOut: &layoutSize) {
            channelLayoutData = Data(bytes: channelLayout, count: layoutSize)
        } else {
            channelLayoutData = Data()
        }

        guard let basicDescription = CMAudioFormatDescriptionGetStreamBasicDescription(currentAudioSampleBufferFormatDescription) else {
            return nil
        }

        // record the audio at AAC format, bitrate 64000, sample rate and channel number using the basic description from the audio samples
        return [
            AVFormatIDKey: kAudioFormatMPEG4AAC,
            AVNumberOfChannelsKey: basicDescription.pointee.mChannelsPerFrame,
            AVSampleRateKey: basicDescription.pointee.mSampleRate,
            AVEncoderBitRateKey: 64000,
            AVChannelLayoutKey: channelLayoutData,
        ]
    }
    
    private func getRenderedOutputPixcelBuffer(adaptor: AVAssetWriterInputPixelBufferAdaptor?) -> CVPixelBuffer? {
        guard let pixelBufferPool = adaptor?.pixelBufferPool else {
            NSLog("Cannot get pixel buffer pool")
            return nil
        }

        var pixelBuffer: CVPixelBuffer?
        CVPixelBufferPoolCreatePixelBuffer(nil, pixelBufferPool, &pixelBuffer)
        guard let renderedOutputPixelBuffer = pixelBuffer else {
            NSLog("Cannot obtain a pixel buffer from the buffer pool")
            return nil
        }

        return renderedOutputPixelBuffer
    }
    
    func recordVideo(_ context: CIContext, filterName: String) {
        if !filterName.isEmpty {
            recordOrigVideo()
        }
        self.ciContext = context
        self.LUT = filterName.isEmpty ? nil : LUTsHelper.applyLUTsFilter(lutImage: filterName, dimension: 64, colorSpace: CameraManager.deviceRgbColorSpace)
        sessionQueue.async { [unowned self] in
            self.removeTemporaryVideoFileIfAny()

            guard let newAssetWriter = self.makeAssetWriter() else { return }

            let newAssetWriterVideoInput = self.makeAssetWriterVideoInput()
            let canAddInput = newAssetWriter.canAdd(newAssetWriterVideoInput)
            if canAddInput {
                newAssetWriter.add(newAssetWriterVideoInput)
            } else {
                self.assetWriterVideoInput = nil
                return
            }

            let newAssetWriterInputPixelBufferAdaptor = self.makeAssetWriterInputPixelBufferAdaptor(with: newAssetWriterVideoInput)

//            guard let audioCompressionSettings = self.makeAudioCompressionSettings() else { return }
//            let canApplayOutputSettings = newAssetWriter.canApply(outputSettings: audioCompressionSettings, forMediaType: .audio)
//            if canApplayOutputSettings {
//                let assetWriterAudioInput = AVAssetWriterInput(mediaType: .audio, outputSettings: audioCompressionSettings)
//                assetWriterAudioInput.expectsMediaDataInRealTime = true
//                self.assetWriterAudioInput = assetWriterAudioInput
//
//                let canAddInput = newAssetWriter.canAdd(assetWriterAudioInput)
//                if canAddInput {
//                    newAssetWriter.add(assetWriterAudioInput)
//                } else {
////                    DispatchQueue.main.async {
////                        self.delegate?.recorderDidFail(with: RecorderError.couldNotAddAssetWriterAudioInput)
////                    }
//                    self.assetWriterAudioInput = nil
//                    return
//                }
//            } else {
////                DispatchQueue.main.async {
////                    self.delegate?.recorderDidFail(with: RecorderError.couldNotApplyAudioOutputSettings)
////                }
//                return
//            }

            self.videoWritingStarted = false
            self.assetWriter = newAssetWriter
            self.assetWriterVideoInput = newAssetWriterVideoInput
            self.assetWriterInputPixelBufferAdaptor = newAssetWriterInputPixelBufferAdaptor
        }
    }

    private func abortRecording() {
        guard let writer = assetWriter else { return }

        writer.cancelWriting()
        assetWriterVideoInput = nil
        assetWriterAudioInput = nil
        assetWriter = nil

        // remove the temp file
        let fileURL = writer.outputURL
        try? FileManager.default.removeItem(at: fileURL)
    }

    func stopRecording() {
        guard let writer = assetWriter else { return }
        stopOrigRecording()
        
        assetWriterVideoInput = nil
        assetWriterAudioInput = nil
        assetWriterInputPixelBufferAdaptor = nil
        assetWriter = nil
        
        sessionQueue.async { [unowned self] in
            writer.endSession(atSourceTime: self.currentVideoTime)
            writer.finishWriting { [self] in
                switch writer.status {
                case .failed:
                    print("failed")
                case .completed:
                    if slowModeValue == 0 {
                        self.recordedAction?(writer.outputURL, self.origVideoURL)
                    } else {
                        slowMotion(pathUrl: writer.outputURL)
                    }
                    
                default:
                    break
                }
            }
        }
    }
    
    func slowMotion(pathUrl: URL) {
        let videoAsset = AVURLAsset.init(url: pathUrl, options: nil)
        let currentAsset = AVAsset.init(url: pathUrl)

        let vdoTrack = currentAsset.tracks(withMediaType: .video)[0]
        let mixComposition = AVMutableComposition()

        let compositionVideoTrack = mixComposition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)

        let videoInsertError: Error? = nil
        var videoInsertResult = false
        do {
            try compositionVideoTrack?.insertTimeRange(
                CMTimeRangeMake(start: .zero, duration: videoAsset.duration),
                of: videoAsset.tracks(withMediaType: .video)[0],
                at: .zero)
            videoInsertResult = true
        } catch let _ {
        }

        if !videoInsertResult || videoInsertError != nil {
            //handle error
            return
        }


        var duration: CMTime = .zero
        duration = CMTimeAdd(duration, currentAsset.duration)
        
        
        //MARK: You see this constant (videoScaleFactor) this helps in achieving the slow motion that you wanted. This increases the time scale of the video that makes slow motion
        // just increase the videoScaleFactor value in order to play video in higher frames rates(more slowly)
        let videoScaleFactor = slowModeValue
        let videoDuration = videoAsset.duration
        
        let toDuration = CGFloat(videoDuration.value) * videoScaleFactor
        
        compositionVideoTrack?.scaleTimeRange(
            CMTimeRangeMake(start: .zero, duration: videoDuration),
            toDuration: CMTimeMake(value: Int64(toDuration), timescale: videoDuration.timescale))
        compositionVideoTrack?.preferredTransform = vdoTrack.preferredTransform
        
        let dirPaths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).map(\.path)
        let docsDir = dirPaths[0]
        let outputFilePath = URL(fileURLWithPath: docsDir).appendingPathComponent("slowMotion\(UUID().uuidString).mp4").path
        
        if FileManager.default.fileExists(atPath: outputFilePath) {
            do {
                try FileManager.default.removeItem(atPath: outputFilePath)
            } catch {
            }
        }
        let filePath = URL(fileURLWithPath: outputFilePath)
        
        let assetExport = AVAssetExportSession(
            asset: mixComposition,
            presetName: AVAssetExportPresetHighestQuality)
        assetExport?.outputURL = filePath
        assetExport?.outputFileType = .mp4
        
        assetExport?.exportAsynchronously(completionHandler: {
            switch assetExport?.status {
            case .failed:
                print("asset output media url = \(String(describing: assetExport?.outputURL))")
                print("Export session faiied with error: \(String(describing: assetExport?.error))")
                DispatchQueue.main.async(execute: {
                    // completion(nil);
                })
            case .completed:
                print("Successful")
                let outputURL = assetExport!.outputURL
                DispatchQueue.main.async(execute: {
                    self.recordedAction?(outputURL!, self.origVideoURL)
                    self.slowModeValue = 0.0
                })
            case .none:
                break
            case .unknown:
                break
            case .waiting:
                break
            case .exporting:
                break
            case .cancelled:
                break
            case .some(_):
                break
            }
        })
    }
    
    func handleAudioSampleBuffer(buffer: CMSampleBuffer) {
        guard let formatDesc = CMSampleBufferGetFormatDescription(buffer) else { return }
        currentAudioSampleBufferFormatDescription = formatDesc

        // write the audio data if it's from the audio connection
        if assetWriter == nil { return }
        guard let input = assetWriterAudioInput else { return }
        if input.isReadyForMoreMediaData {
            let success = input.append(buffer)
            if !success {
                abortRecording()
            }
        }
    }
   
    func handleVideoSampleBuffer(buffer: CMSampleBuffer) {
        let timestamp = CMSampleBufferGetPresentationTimeStamp(buffer)
        frameRateCalculator.calculateFramerate(at: timestamp)

        // update the video dimensions information
        guard let formatDesc = CMSampleBufferGetFormatDescription(buffer) else { return }
        currentVideoDimensions = CMVideoFormatDescriptionGetDimensions(formatDesc)

        guard let imageBuffer = CMSampleBufferGetImageBuffer(buffer) else { return }
        var sourceImage: CIImage = CIImage(cvPixelBuffer: imageBuffer)
        sourceImage = sourceImage.transformed(by: sourceImage.orientationTransform(for: .upMirrored))
        
        guard let writer = assetWriter, let pixelBufferAdaptor = assetWriterInputPixelBufferAdaptor else {
            return
        }

        // if we need to write video and haven't started yet, start writing
        if !videoWritingStarted {
            videoWritingStarted = true
            let success = writer.startWriting()
            if !success {
                abortRecording()
                return
            }

            writer.startSession(atSourceTime: timestamp)
            videoWritingStartTime = timestamp
        }

        guard let renderedOutputPixelBuffer = getRenderedOutputPixcelBuffer(adaptor: pixelBufferAdaptor) else { return }

        self.LUT?.setValue(sourceImage, forKey: "inputImage")
        
        if let filteredImage = self.LUT?.outputImage  {
            ciContext.render(filteredImage, to: renderedOutputPixelBuffer, bounds: filteredImage.extent, colorSpace: CameraManager.deviceRgbColorSpace)
        } else {
            ciContext.render(sourceImage, to: renderedOutputPixelBuffer, bounds: sourceImage.extent, colorSpace: CameraManager.deviceRgbColorSpace)
        }

        // pass option nil to enable color matching at the output, otherwise the color will be off
        currentVideoTime = timestamp

        // write the video data
        guard let input = assetWriterVideoInput else { return }
        if input.isReadyForMoreMediaData {
            let success = pixelBufferAdaptor.append(renderedOutputPixelBuffer, withPresentationTime: timestamp)
            if !success {}
        }
    }

    private func removeTemporaryVideoFileIfAny() {
        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: temporaryVideoFileURL.path) {
            try? fileManager.removeItem(at: temporaryVideoFileURL)
        }
    }
}
