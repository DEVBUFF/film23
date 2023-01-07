//
//  VideoView.swift
//  film24
//
//  Created by Igor Ryazancev on 05.01.2023.
//

import SwiftUI
import AVKit

struct VideoView: UIViewRepresentable {
    
    var url: URL
    var loop: Bool = true
    var updated: Bool = false
    
    func updateUIView(_ uiView: PlayerUIView, context: Context) {
        if uiView.player.currentItem?.url != url {
            uiView.updatePlayerItem(with: url)
        } else {
            uiView.player.play()
        }
        if updated {
            uiView.player.play()
        }
    }

    func makeUIView(context: Context) -> PlayerUIView {
        let playerView = PlayerUIView(url: url, loop: loop)
        playerView.isUserInteractionEnabled = true
        return playerView
    }
}

class PlayerUIView: UIView {
    let player = AVPlayer()
    private let playerLayer = AVPlayerLayer()
    private var loop: Bool = true
    private var playWhenLoad: Bool
    private var loaded = false
    
    deinit {
        print("🚀 PlayerUIView deinited")
        removeAllObservers()
    }

    init(url: URL, loop: Bool, playWhenLoad: Bool = true) {
        self.loop = loop
        self.playWhenLoad = playWhenLoad
        
        super.init(frame: .zero)

        setupPlayer(with: url)
    }
    
    public func updatePlayerItem(with url: URL) {
        let asset = AVURLAsset(url: url)
        let item = AVPlayerItem(asset: asset)
        removeAllObservers()
        player.replaceCurrentItem(with: item)
        addObservers()
    }
    
    private func setupPlayer(with url: URL) {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback)
        } catch(let error) {
            print(error.localizedDescription)
        }
        let asset = AVURLAsset(url: url)
        let item = AVPlayerItem(asset: asset)
        player.replaceCurrentItem(with: item)
        player.actionAtItemEnd = .none
        player.seek(to: CMTime(seconds: 0, preferredTimescale: 1))
        if playWhenLoad {
            player.play()
        }

        playerLayer.player = player
        playerLayer.videoGravity = .resizeAspectFill
        
        addObservers()
        layer.insertSublayer(playerLayer, at: 0)
    }
    
    private func addObservers() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(playerItemDidReachEnd(notification:)),
                                               name: .AVPlayerItemDidPlayToEndTime,
                                               object: player.currentItem)
    }
    
    func removeAllObservers() {
        NotificationCenter.default.removeObserver(self)
        player.currentItem?.removeObserver(self, forKeyPath: "status")
    }

    @objc func playerItemDidReachEnd(notification: Notification) {
        if let playerItem = notification.object as? AVPlayerItem {
            if loop {
                playerItem.seek(to: .zero, completionHandler: nil)
            }
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        
        playerLayer.frame = frame
    }
}
