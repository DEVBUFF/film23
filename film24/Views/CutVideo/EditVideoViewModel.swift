//
//  EditVideoViewModel.swift
//  film24
//
//  Created by Igor Ryazancev on 07.01.2023.
//

import Foundation
import Combine
import Photos
import UIKit

final class EditVideoViewModel: ObservableObject {
    
    @Published var videoModels: [VideoModel] = []
    @Published var videoUrl: URL
    @Published var origUrl: URL?
    @Published var filters: [FilterModel] = [
        FilterModel(name: "original", lutName: "")
    ]
    @Published var loading = false
    
    private let localFilesService = LocalFilesService()
    
    var lutFilter: CIFilter?
    
    var selectedFilter: FilterModel? {
        didSet {
            guard let selectedFilter = selectedFilter else { return }
            let colorSpace: CGColorSpace = CGColorSpace.init(name: CGColorSpace.sRGB) ?? CGColorSpaceCreateDeviceRGB()
            lutFilter = LUTsHelper.applyLUTsFilter(lutImage: selectedFilter.lutName, dimension: 64, colorSpace: colorSpace)
        }
    }
    
    init(videoModels: [VideoModel], url: URL, origUrl: URL?) {
        self.videoModels = videoModels
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
    
    func updateVideo(with videoModel: VideoModel) {
        if let asset = videoModel.player.currentItem?.asset {
            let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let savedoutputURL = documentsDirectory.appendingPathComponent("Filterd\(UUID().uuidString).mov")
            
            let export = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetHighestQuality)
            export!.outputFileType = AVFileType.mov
            export!.outputURL = savedoutputURL
            export!.timeRange = asset.fullRange
            export!.videoComposition = videoModel.player.currentItem?.videoComposition
            
            export?.exportAsynchronously(completionHandler: { [weak self] in
                guard let self else { return }
                if export!.status.rawValue == 4 {
                    print("Export failed -> Reason: \(String(describing: export?.error!.localizedDescription)))")
                    print(export?.error ?? "")
                    return
                }
                
                if let ind = self.videoModels.firstIndex(where: { $0.id == videoModel.id }) {
                    DispatchQueue.main.async {
                        self.videoModels.remove(at: ind)
                        self.videoModels.insert(
                            VideoModel(
                                videoUrl: savedoutputURL,
                                player: AVPlayer(playerItem: AVPlayerItem(asset: asset)),
                                filter: videoModel.filter,
                                ciFilter: videoModel.ciFilter,
                                hideCrop: videoModel.hideCrop,
                                isHidden: videoModel.isHidden
                            ),
                            at: ind
                        )
                    }
                }
            })
        }
    }
    
    func saveVideoToPhotos(url: URL?, shouldSaveOrig: Bool = true, player: AVPlayer? = nil, completion: @escaping ()->Void) {
        guard let url = url else { return }
        loading = true
        guard videoModels.count < 2 else {
            mergeVideos(completion: completion)
            return
        }
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
                            self.loading = false
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
                        self.loading = false
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

//MARK: - Export
extension EditVideoViewModel {
    
    func orientationFromTransform(_ transform: CGAffineTransform) -> (orientation: UIImage.Orientation, isPortrait: Bool) {
        var assetOrientation = UIImage.Orientation.up
        var isPortrait = false
        if transform.a == 0 && transform.b == 1.0 && transform.c == -1.0 && transform.d == 0 {
            assetOrientation = .right
            isPortrait = true
        } else if transform.a == 0 && transform.b == -1.0 && transform.c == 1.0 && transform.d == 0 {
            assetOrientation = .left
            isPortrait = true
        } else if transform.a == 1.0 && transform.b == 0 && transform.c == 0 && transform.d == 1.0 {
            assetOrientation = .up
        } else if transform.a == -1.0 && transform.b == 0 && transform.c == 0 && transform.d == -1.0 {
            assetOrientation = .down
        }
        return (assetOrientation, isPortrait)
    }
    
    func mergeVideos(completion: @escaping ()->Void) {
        let movie = AVMutableComposition()
        let videoTrack = movie.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)
        let audioTrack = movie.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)
        
        var firstTransform: CGAffineTransform?
        videoModels.reversed().forEach { vModel in
            if let asset = vModel.player.currentItem?.asset {
                
                let newAudioTrack = asset.tracks(withMediaType: .audio).first! //2
                let newVideoTrack = asset.tracks(withMediaType: .video).first!
                let newRange = CMTimeRangeMake(start: CMTime.zero, duration: asset.duration) //3
                
                if firstTransform == nil {
                    firstTransform = newVideoTrack.preferredTransform
                }
                
                if let firstTransform {
                    videoTrack?.preferredTransform = firstTransform
                }
                
                do {
                    print("2356y")
                    try videoTrack?.insertTimeRange(newRange, of: newVideoTrack, at: CMTime.zero) //4
                    try audioTrack?.insertTimeRange(newRange, of: newAudioTrack, at: CMTime.zero)
                    
                    
                    
                } catch {
                    print(error.localizedDescription)
                }
            }
        }
        
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let savedoutputURL = documentsDirectory.appendingPathComponent("Merged\(UUID().uuidString).mov")
        
        
        let exporter = AVAssetExportSession(asset: movie,
                                            presetName: AVAssetExportPresetHighestQuality) //1
        //configure exporter
        exporter?.outputURL = savedoutputURL //2
        exporter?.outputFileType = .mov
        //export!
        exporter?.exportAsynchronously(completionHandler: { [weak exporter] in
            DispatchQueue.main.async {
                if let error = exporter?.error { //3
                    print("failed \(error.localizedDescription)")
                } else {
                    print("movie has been exported to \(savedoutputURL)")
                    PHPhotoLibrary.shared().performChanges({ PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: savedoutputURL) }, completionHandler: { _, _ in
                        let fileManager = FileManager.default
                        if fileManager.fileExists(atPath: savedoutputURL.path) {
                            try? fileManager.removeItem(at: savedoutputURL)
                        }
                        self.loading = false
                        completion()
                    })
                }
            }
        })
        
        
    }
    
}
