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
    
    @Published var videoUrl: URL
    @Published var origUrl: URL?
    
    init(url: URL, origUrl: URL?) {
        self.videoUrl = url
        self.origUrl = origUrl
    }
    
    func saveVideoToPhotos(url: URL?, shouldSaveOrig: Bool = true, completion: @escaping ()->Void) {
        guard let url = url else { return }
        let save = {
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
