//
//  CaptureVideoView.swift
//  film24
//
//  Created by Igor Ryazancev on 05.01.2023.
//

import UIKit
import SwiftUI

struct CaptureVideoView: View {
    @StateObject private var model = CaptureVideoViewModel()
    @State private var selectedFilterIndex = 0
    @State private var isRecording = false
    @State private var frameBottomPadding: CGFloat = 0.0
    @State private var editViewShowed = false
    @State private var videoUrl: URL?
    @State private var origVideoUrl: URL?
    @State private var hasNotch = UIDevice.current.hasNotch
        
    @State private var settingsShowed = false
    @State private var filtersShowed = false
    
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
                            .onTapGesture {
                                filtersShowed = true
                            }
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
                            model.stopRecord { url, origUrl in
                                videoUrl = url
                                origVideoUrl = origUrl
                                editViewShowed = true
                            }
                        }
                    }
                    
                    if !isRecording {
                        VideoControllersView { slowModeValue in
                            model.setSlowMode(slowModeValue)
                        } cinematicAction: { cinematicEnabled in
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
                } else {
                    VStack {
                        Text(model.recordingTime)
                            .foregroundColor(.white)
                            .font(.barlow(.regular, size: 14))
                            .background(
                                Capsule()
                                    .foregroundColor(.black.opacity(0.7))
                                    .padding(.vertical, -8)
                                    .padding(.horizontal, -10)
                            )
                        Spacer()
                    }
                        .padding(.top, 56)
                }
                
                if !isRecording {
                    VStack {
                        HStack {
                            Spacer()
                            moreButtonView
                        }
                        .padding(.horizontal, 10)
                        Spacer()
                    }
                    .padding(.top, 10)
                }
                
            }
            .fullScreenCover(isPresented: $settingsShowed) {
                SettingsView()
            }
            
            .fullScreenCover(isPresented: $filtersShowed) {
                FiltersView { selectedFilter in
                    if let index = model.filters.firstIndex(where: { $0.name == selectedFilter.name }) {
                        selectedFilterIndex = index
                        model.setSelectedFilter(with: index)
                    }
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
                EditVideoView(model: EditVideoViewModel(url: videoUrl!, origUrl: origVideoUrl), showed: $editViewShowed)
                    .transition(.opacity)
                    .edgesIgnoringSafeArea(.all)
            }            
        }
        .edgesIgnoringSafeArea(.all)
        .statusBarHidden()
    }
    
    @ViewBuilder
    private var moreButtonView: some View {
        Button {
            settingsShowed = true
        } label: {
            EmptyView()
        }
        .buttonStyle(
            StateableButton(change: { state in
                ZStack {
                    VisualEffectView(effect: UIBlurEffect(style: .dark))
                        .frame(width: 50, height: 60)
                        .cornerRadius(36, corners: [.topRight])
                        .cornerRadius(6, corners: [.topLeft, .bottomLeft, .bottomRight])
                    
                    Text("MO\nRE")
                        .font(.barlow(.regular, size: 12))
                        .foregroundColor(.white)
                }
                .scaleEffect(state ? 0.99 : 1)
            })
            
        )
    }
}
