//
//  EditVideoView.swift
//  film24
//
//  Created by Igor Ryazancev on 07.01.2023.
//

import SwiftUI
import AVKit

struct VideoPreviewView: UIViewRepresentable {
  
    
    var url: URL
    @Binding var player: AVPlayer
    @Binding var progressTime: String
   
    func updateUIView(_ uiView: EditPlayerUIView, context: Context) {
        if uiView.player.currentItem?.url != url {
            uiView.updatePlayerItem(with: url)
            
        } else {
           // uiView.player.play()
        }
//        if updated {
//            uiView.player.play()
//        }
    }

    func makeUIView(context: Context) -> EditPlayerUIView {
        let playerView = EditPlayerUIView(url: url, player: player)
        playerView.isUserInteractionEnabled = true
        addObservers()
        return playerView
    }
    
    private func addObservers() {
        self.player.addPeriodicTimeObserver(forInterval: CMTimeMakeWithSeconds(1, preferredTimescale: 1), queue: DispatchQueue.main, using: { (time) in
            if self.player.currentItem?.status == .readyToPlay {
                let currentTime = CMTimeGetSeconds(self.player.currentTime())
                
                let secs = Int(currentTime)
                self.progressTime = NSString(format: "%02d:%02d", secs/60, secs%60) as String//"\(secs/60):\(secs%60)"
                
            }
        })
    }
    
}

class EditPlayerUIView: UIView {
    let player: AVPlayer
    private let playerLayer = AVPlayerLayer()
    private var playWhenLoad: Bool
    private var loaded = false
    
    deinit {
        print("🚀 PlayerUIView deinited")
    }

    init(url: URL, player: AVPlayer, playWhenLoad: Bool = true) {
        self.player = player
        self.playWhenLoad = playWhenLoad
        
        super.init(frame: .zero)

        setupPlayer(with: url)
    }
    
    public func updatePlayerItem(with url: URL) {
        let asset = AVURLAsset(url: url)
        let item = AVPlayerItem(asset: asset)
        player.replaceCurrentItem(with: item)
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
        
        layer.insertSublayer(playerLayer, at: 0)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        playerLayer.frame = frame
    }
}

