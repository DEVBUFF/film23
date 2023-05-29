//
//  EditVideoView.swift
//  film24
//
//  Created by Igor Ryazancev on 06.01.2023.
//

import SwiftUI
import AVKit

struct VideoModel: Identifiable, Hashable {
    static func == (lhs: VideoModel, rhs: VideoModel) -> Bool {
        lhs.id == rhs.id
    }
    
    let id = UUID().uuidString
    
    var videoUrl: URL
    var player: AVPlayer
    var filter: String?
    var ciFilter: CIFilter?
    var hideCrop: Bool = false
    var isHidden = false
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
    @State private var singleEditMode = false
    
    let pub = NotificationCenter.default
        .publisher(for: .AVPlayerItemDidPlayToEndTime)
    
    init(model: EditVideoViewModel, showed: Binding<Bool>, fromGallery: Bool = false) {
        let player = AVPlayer(url: model.videoUrl)
        self._model = ObservedObject(wrappedValue: model)
        self._showed = showed
        self._player = State(initialValue: AVPlayer())
        self._fromGallery = State(initialValue: fromGallery)
        
        if fromGallery {
            self.model.videoModels = [VideoModel(
                videoUrl: model.videoUrl,
                player: player,
                filter: nil,
                ciFilter: nil)]
        }
    }
    
    var body: some View {
        if fromGallery {
            
        } else {
            
        }
        ZStack {
            Color.black
            ZStack {
                ZStack(alignment: .bottom) {
                    if videoModelIndex < model.videoModels.count {
                        VideoPreviewView(
                            url: model.videoModels[videoModelIndex].videoUrl,
                            player: $model.videoModels[videoModelIndex].player,
                            progressTime: fromGallery ? $progressTime : .constant("")
                        )
                        .id(model.videoModels[videoModelIndex].id)
                        .edgesIgnoringSafeArea(.all)
                    }
                    
                    LinearGradient(colors: [.black, .clear], startPoint: .bottom, endPoint: .top)
                        .frame(height: 130)
                }
                .padding(.bottom, 110)
                
                VStack(spacing: 27) {
                    Spacer()
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(alignment: .bottom, spacing: 3) {
                            ForEach(Array(model.videoModels.enumerated()), id: \.offset) { index, m in
                                if !m.isHidden {
                                    ZStack(alignment: .bottom) {
                                        if model.videoModels.count > 1 && !singleEditMode {
                                            ZStack(alignment: .top) {
                                                RoundedRectangle(cornerRadius: 16)
                                                    .foregroundColor(m.filter == nil ? .second : .filterEdit)
                                                    .frame(width: 112)
                                                    .frame(height: 86)
                                                
                                                HStack {
                                                    Text(m.filter == nil ? "ORIGINAL" : "\(m.filter ?? "")")
                                                        .font(.system(size: 10, weight: .medium))
                                                        .foregroundColor(.black)
                                                    Spacer()
                                                }
                                                .padding(.top, 8)
                                                .padding(.leading, 16)
                                            }
                                        }
                                        
                                        VideoTrimmerView(
                                            trimmerIndex: index,
                                            videoModel: $model.videoModels[index],
                                            progressTime: fromGallery ? .constant("") : $progressTime
                                        ) { i in
                                            playVideo(with: i)
                                        }
                                        .id(m.id)
                                        .frame(height: 60)
                                        .frame(width: model.videoModels.count > 1 && !singleEditMode ? 130 : singleEditMode ? UIScreen.main.bounds.width-64 : UIScreen.main.bounds.width-106)
                                        .if(model.videoModels.count > 1) { v in
                                            v.onTapGesture {
                                                singleEditMode = true
                                                model.videoModels.enumerated().forEach { i, videoModel in
                                                    if videoModel.id != m.id {
                                                        model.videoModels[i].isHidden = true
                                                    } else {
                                                        videoModelIndex = i
                                                        model.videoModels[i].hideCrop = false
                                                    }
                                                }
                                                if let filterIndex = model.filters.firstIndex(where: { $0.name == model.videoModels[videoModelIndex].filter }) {
                                                    selectedFilterIndex = filterIndex
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                            if !singleEditMode && fromGallery {
                                plusButtonView
                            }
                            
                            Spacer()
                        }
                        .padding(.horizontal, 25)
                    }
                    
                    VStack(spacing: 8) {
                        Button {
                            if singleEditMode {
                                singleEditMode = false
                                model.videoModels.enumerated().forEach { i, _ in
                                    model.videoModels[i].isHidden = false
                                    model.videoModels[i].hideCrop = true
                                }
                                selectedFilterIndex = 0
                                model.updateVideo(with: model.videoModels[videoModelIndex])
                            } else {
                                model.saveVideoToPhotos(url: model.videoUrl, player: fromGallery ? player : nil) {
                                    showed = false
                                }
                            }
                        } label: {
                            Text(singleEditMode ? "DONE" : "SAVE")
                                .font(.barlow(.regular, size: 28))
                                .foregroundLinearGradient(
                                    colors: [.main, .second],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                        }
                        
                        Text(singleEditMode ? "EDITING" : "AND SHARE")
                            .font(.barlow(.regular, size: 12))
                            .foregroundColor(.white.opacity(0.3))
                    }
                }
                .padding(.bottom, 45)
                
                VStack(spacing: 16) {
                    HStack {
                        if singleEditMode {
                            Button {
                                let tempIndex = videoModelIndex
                                videoModelIndex = videoModelIndex > 0 ? videoModelIndex-1 : 0
                                model.videoModels.enumerated().forEach { i, _ in
                                    model.videoModels[i].isHidden = false
                                    model.videoModels[i].hideCrop = true
                                }
                                
                                model.videoModels.remove(at: tempIndex)
                                singleEditMode = false
                                selectedFilterIndex = 0
                                
                                
                            } label: {
                                Image("delete")
                            }
                            .frame(width: 44, height: 44)
                            
                        } else {
                            Spacer()
                                .frame(width: 44)
                        }
                        
                        Spacer()
                        
                        Text(progressTime)
                            .foregroundColor(.black)
                            .font(.barlow(.regular, size: 14))
                            .background(
                                Capsule()
                                    .foregroundColor(.white)
                                    .padding(.vertical, -8)
                                    .padding(.horizontal, -10)
                            )
                        
                        Spacer()
                        
                        Button {
                            if singleEditMode {
                                singleEditMode = false
                                model.videoModels.enumerated().forEach { i, _ in
                                    model.videoModels[i].isHidden = false
                                    model.videoModels[i].hideCrop = true
                                }
                                selectedFilterIndex = 0
                            } else {
                                showed = false
                            }
                        } label: {
                            Image("close")
                        }
                        .frame(width: 44, height: 44)
                    }
                    .padding(.horizontal, 10)
                    
                    
                    if singleEditMode || (fromGallery && model.videoModels.count < 2) {
                        FiltersControllerView(filters: model.filters, selectedIndex: $selectedFilterIndex)
                            .onTapGesture {
                                //filtersShowed = true
                            }
                    }
                    Spacer()
                }
                .padding(.top, 56)
            }
            .blur(radius: model.loading ? 10 : 0)
            
            if model.loading {
                ZStack(alignment: .center) {
                    Rectangle()
                        .foregroundColor(.black.opacity(0.2))
                    
                    LoadingView()
                }
            }
        }
        .sheet(isPresented: $showImagePicker, content: {
            ImagePickerView(showPicker: $showImagePicker, loading: $model.loading, selectionLimit: 1) { url in
                guard let url else { return }
                let player = AVPlayer(url: url)
                self.model.videoModels.append(
                    VideoModel(
                        videoUrl: url,
                        player: player,
                        filter: nil,
                        ciFilter: nil
                    )
                )
                self.model.videoModels[videoModelIndex].player.play()
                self.model.videoModels.enumerated().forEach({ model.videoModels[$0.offset].hideCrop = true })
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
        .onReceive(pub) { (output) in            
            playNextPlayer()
        }
        
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
            model.videoModels[videoModelIndex].player.currentItem?.videoComposition = nil
            model.videoModels[videoModelIndex].filter = nil
            return
        }
        guard let asset = model.videoModels[videoModelIndex].player.currentItem?.asset else { return }
        
        let composition = AVVideoComposition(asset: asset, applyingCIFiltersWithHandler: { request in

            let source = request.sourceImage.clampedToExtent()
            filter.setValue(source, forKey: kCIInputImageKey)

            // Crop the invert output to the bounds of the original image
            let output = filter.outputImage!.cropped(to: request.sourceImage.extent)

            // Provide the filter output to the composition
            request.finish(with: output, context: nil)
        })
        
        model.videoModels[videoModelIndex].player.currentItem?.videoComposition = composition
        model.videoModels[videoModelIndex].filter = model.selectedFilter?.name
    }
    
    private func playVideo(with index: Int) {
        model.videoModels.enumerated().forEach({
            if index != $0.offset {
                model.videoModels[$0.offset].player.pause()
                model.videoModels[$0.offset].player.seek(to: CMTime(seconds: 0, preferredTimescale: 1))
            }
        })
        videoModelIndex = index
    }
    
    private func playNextPlayer() {
        model.videoModels.enumerated().forEach({
            model.videoModels[$0.offset].player.pause()
            model.videoModels[$0.offset].player.seek(to: CMTime(seconds: 0, preferredTimescale: 1))
        })
        if !singleEditMode {
            videoModelIndex += 1
            
            if videoModelIndex > model.videoModels.count-1 {
                videoModelIndex = 0
            }
            model.videoModels[videoModelIndex].player.play()
        } else {
            model.videoModels[videoModelIndex].player.play()
        }
    }
}

