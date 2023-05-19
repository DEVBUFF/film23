//
//  EditVideoView.swift
//  film24
//
//  Created by Igor Ryazancev on 06.01.2023.
//

import SwiftUI
import AVKit

struct VideoModel: Identifiable, Hashable {
    let id = UUID().uuidString
    
    var videoTrimmerView: VideoTrimmerView
    var videoUrl: URL?
    var player: AVPlayer
    var filter: FilterModel?
    var ciFilter: CIFilter?
}

struct EditVideoView: View {
    
    @ObservedObject var model: EditVideoViewModel
    @Binding var showed: Bool
    @State private var player: AVPlayer
    @State private var progressTime: String = "00:00"
    @State private var fromGallery = false
    @State private var selectedFilterIndex = 0
    @State private var showImagePicker = false
    @State private var videoModelIndex = 0
    
    init(model: EditVideoViewModel, showed: Binding<Bool>, fromGallery: Bool = false) {
        let player = AVPlayer(url: model.videoUrl)
        self._model = ObservedObject(wrappedValue: model)
        self._showed = showed
        self._player = State(initialValue: player)
        self._fromGallery = State(initialValue: fromGallery)
        if fromGallery {
            self.model.videoModels = [VideoModel(
                videoTrimmerView: VideoTrimmerView(
                    videoUrl: model.videoUrl,
                    player: player,
                    progressTime: .constant("0"),
                    playerDidFinish: nil
                ),
                videoUrl: model.videoUrl,
                player: player,
                filter: nil,
                ciFilter: nil)]
        }
    }
    
    var body: some View {
        ZStack {
            Color.black
            
            ZStack(alignment: .bottom) {
                if let url = model.videoModels[videoModelIndex].videoUrl {
                    VideoPreviewView(url: url, player: $model.videoModels[videoModelIndex].player)
                        .edgesIgnoringSafeArea(.all)
                }
                                
                LinearGradient(colors: [.black, .clear], startPoint: .bottom, endPoint: .top)
                    .frame(height: 130)
            }
            .padding(.bottom, 110)
            
            VStack(spacing: 27) {
                Spacer()
                
                ScrollView(.horizontal) {
                    HStack(spacing: 0) {
                        ForEach(Array(model.videoModels.enumerated()), id: \.offset) { index, m in
                            if let url = m.videoUrl {
                                VideoTrimmerView(
                                    videoUrl: url,
                                    player: m.player,
                                    progressTime: $progressTime
                                ) {
                                    playNextPlayer()
                                }
                                .frame(height: 60)
                                .frame(maxWidth: 130)
                                .frame(minWidth: 130)
                            }
                        }
                        
                        plusButtonView
                        Spacer()
                    }
                    .padding(.horizontal, 25)
                }
                
                VStack(spacing: 8) {
                    Button {
                        model.saveVideoToPhotos(url: model.videoUrl, player: fromGallery ? player : nil) {
                            showed = false
                        }
                    } label: {
                        Text("SAVE")
                            .font(.barlow(.regular, size: 28))
                            .foregroundLinearGradient(
                                colors: [.main, .second],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                    }
                    
                    Text("AND SHARE")
                        .font(.barlow(.regular, size: 12))
                        .foregroundColor(.white.opacity(0.3))
                }
            }
            .padding(.bottom, 45)
            
            VStack {
                HStack {
                    Spacer()
                    Button {
                        showed = false
                    } label: {
                        Image("close")
                    }
                    .frame(width: 44, height: 44)
                }
                .padding(.horizontal, 10)
                
                Spacer()
            }
            .padding(.top, 50)
            
            VStack(spacing: 16) {
                Text(progressTime)
                    .foregroundColor(.black)
                    .font(.barlow(.regular, size: 14))
                    .background(
                        Capsule()
                            .foregroundColor(.white)
                            .padding(.vertical, -8)
                            .padding(.horizontal, -10)
                    )
                
                if fromGallery && model.videoModels.count < 2 {
                    FiltersControllerView(filters: model.filters, selectedIndex: $selectedFilterIndex)
                        .onTapGesture {
                            //filtersShowed = true
                        }
                }
                Spacer()
            }
                .padding(.top, 56)
        }
        .sheet(isPresented: $showImagePicker, content: {
            ImagePickerView(showPicker: $showImagePicker, selectionLimit: 1) { url in
                guard let url else { return }
                let player = AVPlayer(url: url)
                self.model.videoModels.append(
                    VideoModel(
                        videoTrimmerView: VideoTrimmerView(
                            videoUrl: url,
                            player: player,
                            progressTime: .constant("0"),
                            playerDidFinish: nil
                        ),
                        videoUrl: url,
                        player: player,
                        filter: nil,
                        ciFilter: nil
                    )
                )
            }
        })
        .gesture(DragGesture(minimumDistance: 60, coordinateSpace: .global)
            .onEnded { value in
                let horizontalAmount = value.translation.width
                let verticalAmount = value.translation.height
                
                if abs(horizontalAmount) > abs(verticalAmount) {
                    if horizontalAmount > 0 {
                        selectedFilterIndex = selectedFilterIndex > 0 ? selectedFilterIndex-1 : 0
                    } else {
                        selectedFilterIndex = selectedFilterIndex < model.filters.count-1 ? selectedFilterIndex+1 : selectedFilterIndex
                    }
                    model.setSelectedFilter(with: selectedFilterIndex)
                    updatePlayerFilter()
                }
            })
    }
    
    func share() {
        let activityController = UIActivityViewController(activityItems: [model.videoUrl], applicationActivities: nil)
        
        UIApplication.shared.windows.first?.rootViewController!.present(activityController, animated: true, completion: nil)
    }
    
    @ViewBuilder
    private var plusButtonView: some View {
        Button {
            showImagePicker = true
            model.videoModels[videoModelIndex].player.pause()
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 17)
                    .frame(width: 34, height: 60)
                    .foregroundColor(.main)
                Image("plus")
            }
        }
    }
    
    private func updatePlayerFilter() {
        guard let filter = model.lutFilter else {
            
            return
        }
        guard let asset = player.currentItem?.asset else { return }
        
        let composition = AVVideoComposition(asset: asset, applyingCIFiltersWithHandler: { request in

            let source = request.sourceImage.clampedToExtent()
            filter.setValue(source, forKey: kCIInputImageKey)

            // Crop the invert output to the bounds of the original image
            let output = filter.outputImage!.cropped(to: request.sourceImage.extent)

            // Provide the filter output to the composition
            request.finish(with: output, context: nil)
        })
        
        player.currentItem?.videoComposition = composition
    }
    
    private func playVideos() {
        
    }
    
    private func playNextPlayer() {
        videoModelIndex += 1
        if videoModelIndex > model.videoModels.count-1 {
            videoModelIndex = 0
            model.videoModels[videoModelIndex].player.seek(to: CMTime(seconds: 0, preferredTimescale: 1))
            model.videoModels[videoModelIndex].player.play()
        } else {
            model.videoModels[videoModelIndex].player.seek(to: CMTime(seconds: 0, preferredTimescale: 1))
            model.videoModels[videoModelIndex].player.play()
           //
        }
        //model.objectWillChange.send()
        print(videoModelIndex)
    }
}

