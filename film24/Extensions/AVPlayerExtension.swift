//
//  AVPlayerExtension.swift
//  film24
//
//  Created by Igor Ryazancev on 07.01.2023.
//

import AVKit

extension AVPlayer {
    var isPlaying: Bool {
        return rate != 0 && error == nil
    }
}

extension AVPlayerItem {
    var url: URL? {
        return (asset as? AVURLAsset)?.url
    }
}
