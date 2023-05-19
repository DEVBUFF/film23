//
//  EditVideoViewModel.swift
//  film24
//
//  Created by Igor Ryazancev on 07.01.2023.
//

import Foundation
import Combine
import Photos

final class EditVideoViewModel: ObservableObject {
    
    @Published var videoModels: [VideoModel] = []
    @Published var videoUrl: URL
    @Published var origUrl: URL?
    @Published var filters: [FilterModel] = [
        FilterModel(name: "original", lutName: "")
    ]
    
    private let localFilesService = LocalFilesService()
    
    var lutFilter: CIFilter?
    
    var selectedFilter: FilterModel? {
        didSet {
            guard let selectedFilter = selectedFilter else { return }
            let colorSpace: CGColorSpace = CGColorSpace.init(name: CGColorSpace.sRGB) ?? CGColorSpaceCreateDeviceRGB()
            lutFilter = LUTsHelper.applyLUTsFilter(lutImage: selectedFilter.lutName, dimension: 64, colorSpace: colorSpace)
        }
    }
    
    init(url: URL, origUrl: URL?) {
        self.videoUrl = url
        self.origUrl = origUrl
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
    
    func setSelectedFilter(with index: Int) {
        let newFilter = filters[index]
        
        guard selectedFilter != newFilter else { return }
        
        selectedFilter = newFilter
    }
    
    func saveVideoToPhotos(url: URL?, shouldSaveOrig: Bool = true, player: AVPlayer? = nil, completion: @escaping ()->Void) {
        guard let url = url else { return }
        let save = {
            if player != nil,
                let asset = player?.currentItem?.asset,
                let composition = player?.currentItem?.videoComposition {
                let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                let savedoutputURL = documentsDirectory.appendingPathComponent("Filterd\(UUID().uuidString).mov")
                
                let export = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetHighestQuality)
                    export!.outputFileType = AVFileType.mov
                    export!.outputURL = savedoutputURL
                    export!.videoComposition = composition

                    export?.exportAsynchronously(completionHandler: {

                        if export!.status.rawValue == 4 {
                            print("Export failed -> Reason: \(String(describing: export?.error!.localizedDescription)))")
                            print(export?.error ?? "")
                            return
                        }
                        
                        PHPhotoLibrary.shared().performChanges({ PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: savedoutputURL) }, completionHandler: { _, _ in
                            let fileManager = FileManager.default
                            if fileManager.fileExists(atPath: savedoutputURL.path) {
                                try? fileManager.removeItem(at: savedoutputURL)
                            }
                            
                            completion()
                        })
                    })
            } else {
                PHPhotoLibrary.shared().performChanges({ PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url) }, completionHandler: { _, _ in
                    let fileManager = FileManager.default
                    if fileManager.fileExists(atPath: url.path) {
                        try? fileManager.removeItem(at: url)
                    }
                    if settings.shouldSaveOriginal, let origUrl = self.origUrl, shouldSaveOrig {
                        self.saveVideoToPhotos(
                            url: origUrl,
                            shouldSaveOrig: false,
                            completion: completion
                        )
                    } else {
                        completion()
                    }
                })
            }
        }
        if PHPhotoLibrary.authorizationStatus() != .authorized {
            PHPhotoLibrary.requestAuthorization { status in
                if status == .authorized {
                    save()
                }
            }
        } else {
            save()
        }
    }
    
}
