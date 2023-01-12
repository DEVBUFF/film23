//
//  VideoControllersView.swift
//  film24
//
//  Created by Igor Ryazancev on 05.01.2023.
//

import SwiftUI

struct VideoControllersView: View {
    
    enum SlowMode {
        case off
        case twenty
        case fifty
        
        var name: String {
            switch self {
            case .off:
                return "OFF"
            case .twenty:
                return "NORMAL"
            case .fifty:
                return "DRAMA"
            }
        }
        
        var value: CGFloat {
            switch self {
            case .off:
                return 0
            case .twenty:
                return 1.4
            case .fifty:
                return 2
            }
        }
    }
    
    enum CinematicMode {
        case off
        case standard
        case cinematic
        
        var name: String {
            switch self {
            case .off:
                return "OFF"
            case .standard:
                return "STANDARD"
            case .cinematic:
                return "CINEMATIC"
            }
        }
    }
    
    @State private var autoFocusEnabled = true
    @State private var cinematicMode: CinematicMode = .standard
    @State private var hasNotch = (UIApplication.shared.windows.first?.safeAreaInsets.bottom ?? 0) > 0
    @State private var slowMode: SlowMode = .off
    
    var slowModeAction: (CGFloat)->()
    var cinematicAction: (CinematicMode)->()
    var autoFocusAction: (Bool)->()
    
    var body: some View {
        ZStack(alignment: .top) {
            VisualEffectView(effect: UIBlurEffect(style: .dark))
                .cornerRadius(10, corners: [.topLeft, .topRight])
                .cornerRadius(hasNotch ? 46 : 0, corners: [.bottomLeft, .bottomRight])
                .padding(2)
            
            HStack {
                VStack(spacing: 5) {
                    Text("SLOWLY")
                        .foregroundColor(.white.opacity(0.3))
                        .font(.barlow(.medium, size: 11))
                    Button {
                        changeSlowMode()
                        slowModeAction(slowMode.value)
                    } label: {
                        EmptyView()
                    }
                    .buttonStyle(
                        StateableButton(change: { _ in
                            Text(slowMode.name)
                                .foregroundColor(slowMode == .off ? .white : .black)
                                .font(.barlow(.medium, size: 12))
                                .background(
                                    Capsule()
                                        .foregroundColor(slowMode == .off ? .black : .second)
                                        .padding(.horizontal, -10)
                                        .frame(height: 24)
                                )
                        })
                    )
                    .frame(width: 70, height: 40)
                    
                }
                Spacer()
                
                VStack(spacing: 5) {
                    Text("AUTO FOCUS")
                        .foregroundColor(.white.opacity(0.3))
                        .font(.barlow(.medium, size: 11))
                    Button {
                        autoFocusEnabled.toggle()
                        autoFocusAction(autoFocusEnabled)
                    } label: {
                        EmptyView()
                    }
                    .buttonStyle(
                        StateableButton(change: { _ in
                            Text(autoFocusEnabled ? "ON" : "OFF")
                                .foregroundColor(autoFocusEnabled ? .black : .white)
                                .font(.barlow(.medium, size: 12))
                                .background(
                                    Capsule()
                                        .foregroundColor(autoFocusEnabled ? .second : .black)
                                        .frame(height: 24)
                                        .padding(.horizontal, -10)
                                )
                        })
                    )
                    .frame(width: 70, height: 40)
                    
                }
            }
            .padding(.horizontal, 40)
            .padding(.top, 20)
            
            VStack(spacing: 5) {
                Text("STABILIZATION")
                    .foregroundColor(.white.opacity(0.3))
                    .font(.barlow(.medium, size: 11))
                Button {
                    setCinematicMode()
                    cinematicAction(cinematicMode)
                } label: {
                    EmptyView()
                }
                .buttonStyle(
                    StateableButton(change: { _ in
                        Text(cinematicMode.name)
                            .foregroundColor(cinematicMode == .off ? .white : .black)
                            .font(.barlow(.medium, size: 12))
                            .background(
                                Capsule()
                                    .foregroundColor(cinematicMode == .off ? .black : .second)
                                    .frame(height: 24)
                                    .padding(.horizontal, -10)
                            )
                    })
                )
                .frame(width: 100, height: 40)
                
            }
            .padding(.top, 20)
        }
        .frame(height: 100)
        .ignoresSafeArea(.all)
    }
    
    func changeSlowMode() {
        switch slowMode {
        case .off:
            slowMode = .twenty
        case .twenty:
            slowMode = .fifty
        case .fifty:
            slowMode = .off
        }
    }
    
    func setCinematicMode() {
        switch cinematicMode {
        case .off:
            cinematicMode = .standard
        case .standard:
            cinematicMode = .cinematic
        case .cinematic:
            cinematicMode = .off
        }
    }
    
}
