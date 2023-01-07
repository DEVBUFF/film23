//
//  CaptureVideoView.swift
//  film24
//
//  Created by Igor Ryazancev on 05.01.2023.
//

import SwiftUI

struct CaptureVideoView: View {
    @StateObject private var model = CaptureVideoViewModel()
    @State private var selectedFilterIndex = 0
    @State private var isRecording = false
    @State private var frameBottomPadding: CGFloat = 0.0
    @State private var editViewShowed = false
    @State private var videoUrl: URL?
    
    var body: some View {
        ZStack {
            ZStack {
                FrameView(image: model.frame, bottomPadding: $frameBottomPadding) { location in
                    model.focus(location)
                }
                .edgesIgnoringSafeArea(.all)
                
                VStack(alignment: .center, spacing: 24) {
                    if !isRecording {
                        FiltersControllerView(filters: model.filters, selectedIndex: $selectedFilterIndex)
                            .padding(.top, 70)
                    }
                    
                    Spacer()
                    
                    CameraControllersView {
                        model.changeCameraPosition()
                    } zoomAction: { value in
                        model.zoom(value)
                    } recordAction: { isRecording in
                        withAnimation {
                            frameBottomPadding = isRecording ? 90 : 0
                            self.isRecording = isRecording
                        }
                        if isRecording {
                            model.startRecord()
                        } else {
                            model.stopRecord { url in
                                videoUrl = url
                                editViewShowed = true
                            }
                        }
                    }
                    
                    if !isRecording {
                        VideoControllersView { cinematicEnabled in
                            model.cinematic(isOn: cinematicEnabled)
                        } autoFocusAction: { autoFocusEnabled in
                            model.autoFocus(isOn: autoFocusEnabled)
                        }
                    } else {
                        Rectangle()
                            .foregroundColor(.clear)
                            .frame(height: frameBottomPadding+30)
                    }
                }
                .ignoresSafeArea(.all)
                
                if !isRecording {
                    HStack {
                        Spacer()
                        ExposureControllerView { exposure in
                            model.exposureChanged(exposure)
                        }
                    }
                    .padding(.horizontal, 20)
                }
            }
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
                    }
                })
            
            if editViewShowed && videoUrl != nil {
                EditVideoView(model: EditVideoViewModel(url: videoUrl!), showed: $editViewShowed)
                    .transition(.opacity)
                    .edgesIgnoringSafeArea(.all)
            }
            
        }
        .statusBarHidden()
    }
}
