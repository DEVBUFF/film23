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
    
    @Published var filters: [FilterModel] = [
        FilterModel(name: "original", lutName: ""),
        FilterModel(name: "demo", lutName: "demo.png"),
        FilterModel(name: "demo2", lutName: "demo.png"),
        FilterModel(name: "demo3", lutName: "demo.png"),
        FilterModel(name: "demo4", lutName: "demo.png"),
    ]
    
    
    var lutFilter: CIFilter?
    
    var selectedFilter: FilterModel? {
        didSet {
            guard let selectedFilter = selectedFilter else { return }
            let colorSpace: CGColorSpace = CGColorSpace.init(name: CGColorSpace.sRGB) ?? CGColorSpaceCreateDeviceRGB()
            lutFilter = LUTsHelper.applyLUTsFilter(lutImage: selectedFilter.name, dimension: 64, colorSpace: colorSpace)
        }
    }
    
    private let context = CIContext()
    
    private let cameraManager = CameraManager.shared
    private let frameManager = FrameManager.shared
        
    init() {
        setupSubscriptions()
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
    
    func cinematic(isOn: Bool) {
        cameraManager.cinematic(isOn: isOn)
    }
    
    func exposureChanged(_ value: CGFloat) {
        cameraManager.exposure(value)
    }
    
    func focus(_ point: CGPoint) {
        cameraManager.focus(point)
    }
    
    func zoom(_ scale: CGFloat) {
        cameraManager.zoom(scale)
    }
    
    func startRecord() {
        cameraManager.recordVideo()
    }
    
    func stopRecord(completion: @escaping (URL)->Void) {
        cameraManager.stopRecording()
        cameraManager.recordedAction = completion
    }
    
}

