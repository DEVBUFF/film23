//
//  CameraControllersView.swift
//  film24
//
//  Created by Igor Ryazancev on 05.01.2023.
//

import SwiftUI
import AVFoundation

struct CameraControllersView: View {
    
    enum CameraZoomFactor {
        case min
        case mid
        case max
        
        var name: String {
            switch self {
            case .min:
                return "0.5X"
            case .mid:
                return "1X"
            case .max:
                return "2X"
            }
        }
        
        var value: CGFloat {
            switch self {
            case .min:
                return 1
            case .mid:
                return 2
            case .max:
                return 4
            }
        }
    }
    
    @State private var zoomFactor: CameraZoomFactor = .mid
    @State private var isRecording = false
    @State private var isBackCameraPosition = true
    @State private var appear = false
    
    var isTripleCamera: Bool {
        return AVCaptureDevice.default(.builtInTripleCamera, for: .video, position: .back) != nil
    }
    
    var changedPosition: ()->()
    var zoomAction: (CGFloat)->()
    var recordAction: (Bool)->()
    
    var body: some View {
        ZStack {
            HStack(spacing: 40) {
                if !isRecording {
                    Button {
                        isBackCameraPosition.toggle()
                        zoomFactor = .mid
                        changedPosition()
                    } label: {
                        EmptyView()
                    }
                    .buttonStyle(
                        StateableButton { state in
                            ZStack {
                                VisualEffectView(effect: UIBlurEffect(style: .dark))
                                    .frame(width: 48, height: 48)
                                    .cornerRadius(24)
                                Image("rotate")
                            }
                            .scaleEffect(state ? 0.99 : 1)
                        }
                    )
                }
                
                Button {
                    isRecording.toggle()
                    recordAction(isRecording)
                } label: {
                    if isRecording {
                        ZStack {
                            Image("stop")
                                .resizable()
                                .frame(width: 88, height: 88)
                                .rotationEffect(Angle(degrees: appear ? 360 : 0))
                                .onAppear(perform: {
                                    withAnimation(Animation.linear(duration: 15).repeatForever(autoreverses: false)) {
                                        appear.toggle()
                                    }
                                })
                                
                            Circle()
                                .frame(width: 68, height: 68)
                                .background(Circle().fill(Color.main))
                            Rectangle()
                                .frame(width: 20, height: 20)
                                .foregroundColor(.white)
                                .cornerRadius(4)
                        }
                        
                        .padding(.bottom, -15)
                    } else {
                        Circle()
                            .stroke(.white, lineWidth: 3)
                            .frame(width: 88, height: 88)
                            .background(Circle().fill(Color.main))
                    }
                }
                
                
                if !isRecording {
                    Button {
                        setZoomFactor()
                        zoomAction(isBackCameraPosition && isTripleCamera ? zoomFactor.value : zoomFactor == .min ? zoomFactor.value-0.5 :  zoomFactor.value-1)
                    } label: {
                        EmptyView()
                    }
                    .buttonStyle(
                        StateableButton { state in
                            ZStack {
                                VisualEffectView(effect: UIBlurEffect(style: .dark))
                                    .frame(width: 48, height: 48)
                                    .cornerRadius(24)
                                Text(zoomFactor.name)
                                    .font(.barlow(.medium, size: 13))
                                    .foregroundColor(.white)
                            }
                            .scaleEffect(state ? 0.99 : 1)
                        }
                    )
                }
                
            }
        }
    }
    
    private func setZoomFactor() {
        switch zoomFactor {
        case .min:
            zoomFactor = .mid
        case .mid:
            zoomFactor = isBackCameraPosition && isTripleCamera ? .max : .min
        case .max:
            zoomFactor = isBackCameraPosition && isTripleCamera ? .min : .mid
        }
    }
}
