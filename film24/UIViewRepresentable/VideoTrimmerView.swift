//
//  VideoTrimmerView.swift
//  film24
//
//  Created by Igor Ryazancev on 07.01.2023.
//

import SwiftUI
import AVKit

struct VideoTrimmerView: UIViewRepresentable {
    
    let videoTrimmer = VideoTrimmer()
    private var asset: AVAsset!
    
    var trimmerIndex: Int
    @Binding var videoModel: VideoModel
    @Binding var progressTime: String
    var didBeginScrubbing: ((Int)->())?
    
    init(
        trimmerIndex: Int,
        videoModel:  Binding<VideoModel>,
        progressTime: Binding<String>,
        didBeginScrubbing: ((Int)->())? = nil
    ) {
        self.trimmerIndex = trimmerIndex
        self._videoModel = videoModel
        self._progressTime = progressTime
        self.didBeginScrubbing = didBeginScrubbing
        
        self.asset = AVURLAsset(url: videoModel.videoUrl.wrappedValue, options: [AVURLAssetPreferPreciseDurationAndTimingKey: true])
    }
    
    func makeUIView(context: UIViewRepresentableContext<Self>) -> VideoTrimmer {
        videoTrimmer.minimumDuration = CMTime(seconds: 1, preferredTimescale: 600)
        videoTrimmer.asset = asset
        
        videoTrimmer
            .addTarget(
                context.coordinator,
                action: #selector(Coordinator.didBeginTrimming(_:)),
                for: VideoTrimmer.didBeginTrimming
            )
        videoTrimmer
            .addTarget(
                context.coordinator,
                action: #selector(Coordinator.didEndTrimming(_:)),
                for: VideoTrimmer.didEndTrimming
            )
        videoTrimmer
            .addTarget(
                context.coordinator,
                action: #selector(Coordinator.selectedRangeDidChanged(_:)),
                for: VideoTrimmer.selectedRangeChanged
            )
        videoTrimmer
            .addTarget(
                context.coordinator,
                action: #selector(Coordinator.didBeginScrubbing(_:)),
                for: VideoTrimmer.didBeginScrubbing
            )
        videoTrimmer
            .addTarget(
                context.coordinator,
                action: #selector(Coordinator.didEndScrubbing(_:)),
                for: VideoTrimmer.didEndScrubbing
            )
        videoTrimmer
            .addTarget(
                context.coordinator,
                action: #selector(Coordinator.progressDidChanged(_:)),
                for: VideoTrimmer.progressChanged
            )
        
        videoModel.player.addPeriodicTimeObserver(forInterval: CMTime(value: 1, timescale: 30), queue: .main) { time in
            let finalTime = videoTrimmer.trimmingState == .none ? CMTimeAdd(time, videoTrimmer.selectedRange.start) : time
            videoTrimmer.progress = finalTime
        }
        updateProgress()
        
        return videoTrimmer
    }
    
    func updateUIView(_ uiView: VideoTrimmer, context: UIViewRepresentableContext<Self>) {
        uiView.hideThumbView(videoModel.hideCrop)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func updateProgress() {
        DispatchQueue.main.async {
            let time = videoTrimmer.selectedRange.end - videoTrimmer.selectedRange.start
            progressTime = time.displayString
        }
    }
    
    class Coordinator: NSObject {
        var parent: VideoTrimmerView
        private var wasPlaying = false
        
        init(_ parent: VideoTrimmerView) {
            self.parent = parent
        }
        
        private func updatePlayerAsset() {
            let outputRange = parent.videoTrimmer.trimmingState == .none ? parent.videoTrimmer.selectedRange : parent.asset.fullRange
            let trimmedAsset = parent.asset.trimmedComposition(outputRange)
            if trimmedAsset != parent.videoModel.player.currentItem?.asset {
                parent.videoModel.player.replaceCurrentItem(with: AVPlayerItem(asset: trimmedAsset))
            }
        }
        
        @objc func didBeginTrimming(_ sender: VideoTrimmer) {
            parent.updateProgress()
            
            wasPlaying = (parent.videoModel.player.timeControlStatus != .paused)
            parent.videoModel.player.pause()
    
            updatePlayerAsset()
        }

        @objc func didEndTrimming(_ sender: VideoTrimmer) {
            parent.updateProgress()
            
            if wasPlaying == true {
                parent.videoModel.player.play()
            }
    
            updatePlayerAsset()
        }

        @objc func selectedRangeDidChanged(_ sender: VideoTrimmer) {
            parent.updateProgress()
        }

        @objc func didBeginScrubbing(_ sender: VideoTrimmer) {
            parent.updateProgress()
            
            wasPlaying = (parent.videoModel.player.timeControlStatus != .paused)
            parent.videoModel.player.pause()
            parent.didBeginScrubbing?(parent.trimmerIndex)
        }

        @objc func didEndScrubbing(_ sender: VideoTrimmer) {
            parent.updateProgress()
            
            if wasPlaying == true {
                parent.videoModel.player.play()
            }
        }

        @objc func progressDidChanged(_ sender: VideoTrimmer) {
            parent.updateProgress()
            
            let time = CMTimeSubtract(parent.videoTrimmer.progress, parent.videoTrimmer.selectedRange.start)
            parent.videoModel.player.seek(to: time, toleranceBefore: .zero, toleranceAfter: .zero)
        }
        
    }
    
   

}
