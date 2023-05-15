//
//  CaptureVideoViewModel.swift
//  film24
//
//  Created by Igor Ryazancev on 05.01.2023.
//

import CoreImage

class CaptureVideoViewModel: ObservableObject {
    @Published var error: Error?
    @Published var frame: CGImage?
    @Published var recordingTime: String = "00:00"
    
    private let localFilesService = LocalFilesService()
    
    @Published var filters: [FilterModel] = [
        FilterModel(name: "original", lutName: "")
    ]
    
    var lutFilter: CIFilter?
    
    var selectedFilter: FilterModel? {
        didSet {
            guard let selectedFilter = selectedFilter else { return }
            let colorSpace: CGColorSpace = CGColorSpace.init(name: CGColorSpace.sRGB) ?? CGColorSpaceCreateDeviceRGB()
            lutFilter = LUTsHelper.applyLUTsFilter(lutImage: selectedFilter.lutName, dimension: 64, colorSpace: colorSpace)
        }
    }
    
    private let context = CIContext()
    private let cameraManager = CameraManager.shared
    private let frameManager = FrameManager.shared
    
    private var timer: Timer?
        
    init() {
        setupSubscriptions()
        loadSections()
    }
    
    func loadSections() {
        if let json = localFilesService.readLocalJSONFile(forName: "filters_sections") {
            let sections: [FiltersSectionModel] = localFilesService.parse(jsonData: json) ?? []
            var locFilters: [FilterModel] = []
            sections.forEach({ locFilters.append(contentsOf: $0.filters) })
            filters.append(contentsOf: locFilters)
        }
    }
    
    func setupSubscriptions() {
        // swiftlint:disable:next array_init
        cameraManager.$error
            .receive(on: RunLoop.main)
            .map { $0 }
            .assign(to: &$error)
        
        frameManager.$current
            .receive(on: RunLoop.main)
            .compactMap { [weak self] buffer in
                guard let `self` = self else { return nil }
                guard let image = CGImage.create(from: buffer) else {
                    return nil
                }
                
                var ciImage = CIImage(cgImage: image)
                
                if let selectedFilter = self.selectedFilter, !selectedFilter.name.isEmpty {
                    self.lutFilter?.setValue(ciImage, forKey: "inputImage")
                    let lutOutputImage = self.lutFilter?.outputImage
                    
                    if let output = lutOutputImage {
                        ciImage = output
                    }
                }
                
                return self.context.createCGImage(ciImage, from: ciImage.extent)
            }
            .assign(to: &$frame)
    }
    
    func startUpdateRecordTime() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: { [weak self] _ in
            guard let `self` = self else { return }
            self.msFrom(seconds: self.cameraManager.recordingSeconds) { minutes, seconds in
                let minutes = self.getStringFrom(seconds: minutes)
                let seconds = self.getStringFrom(seconds: seconds)
                self.recordingTime = "\(minutes):\(seconds)"
            }
        })
    }
    
    func stopUpdateRecordTime() {
        timer?.invalidate()
        timer = nil
    }
    
    func msFrom(seconds: Int, completion: @escaping (_ minutes: Int, _ seconds: Int)->()) {
        completion((seconds % 3600) / 60, (seconds % 3600) % 60)
    }

    func getStringFrom(seconds: Int) -> String {
        return seconds < 10 ? "0\(seconds)" : "\(seconds)"
    }
}

//MARK: - Public methods
extension CaptureVideoViewModel {
    
    func setSelectedFilter(with index: Int) {
        let newFilter = filters[index]
        
        guard selectedFilter != newFilter else { return }
        
        selectedFilter = newFilter
    }
    
    func changeCameraPosition() {
        cameraManager.cameraPosition = cameraManager.cameraPosition == .front ? .back : .front
        cameraManager.reloadCaptureSession()
    }
    
    func autoFocus(isOn: Bool) {
        cameraManager.autoFocus(isOn: isOn)
    }
    
    func cinematic(_ cinematicMode: LocalSettings.Stabilisation) {
        cameraManager.cinematic(cinematicMode)
    }
    
    func exposureChanged(_ value: CGFloat) {
        cameraManager.exposure(value)
    }
    
    func focus(_ point: CGPoint, vSize: CGSize) {
        cameraManager.focus(point, vSize: vSize)
    }
    
    func zoom(_ scale: CGFloat) {
        cameraManager.zoom(scale)
    }
    
    func setSlowMode(_ value: CGFloat) {
        cameraManager.slowModeValue = value
    }
    
    func startRecord() {
        cameraManager.recordVideo(
            context,
            filterName: selectedFilter?.lutName ?? ""
        )
        startUpdateRecordTime()
    }
    
    func stopRecord(completion: @escaping (URL, URL?)->Void) {
        recordingTime = "00:00"
        cameraManager.stopRecording()
        cameraManager.recordedAction = completion
        stopUpdateRecordTime()
       // cameraManager.slowModeValue = 0
    }
    
}

