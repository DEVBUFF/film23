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
                return "20%"
            case .fifty:
                return "55%"
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
    
    @State private var autoFocusEnabled = true
    @State private var cinematicEnabled = false
    @State private var hasNotch = UIDevice.current.hasNotch
    @State private var slowMode: SlowMode = .off
    
    var slowModeAction: (CGFloat)->()
    var cinematicAction: (Bool)->()
    var autoFocusAction: (Bool)->()
    
    var body: some View {
        ZStack() {
            VisualEffectView(effect: UIBlurEffect(style: .dark))
                .cornerRadius(20, corners: [.topLeft, .topRight])
                .cornerRadius(hasNotch ? 46 : 0, corners: [.bottomLeft, .bottomRight])
                .padding(2)
            
            HStack {
                VStack(spacing: 12) {
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
                                .foregroundColor(.white)
                                .font(.barlow(.medium, size: 12))
                                .background(
                                    Capsule()
                                        .foregroundColor(.black)
                                        .padding(.vertical, -7.5)
                                        .padding(.horizontal, -10)
                                )
                        })
                    )
                    .frame(width: 30, height: 30)
                    
                }
                Spacer()
                
                VStack(spacing: 12) {
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
                                .foregroundColor(.white)
                                .font(.barlow(.medium, size: 12))
                                .background(
                                    Capsule()
                                        .foregroundColor(.black)
                                        .padding(.vertical, -7.5)
                                        .padding(.horizontal, -10)
                                )
                        })
                    )
                    .frame(width: 30, height: 30)
                    
                }
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 20)
            
            VStack(spacing: 12) {
                Text("STABILIZATION")
                    .foregroundColor(.white.opacity(0.3))
                    .font(.barlow(.medium, size: 11))
                Button {
                    cinematicEnabled.toggle()
                    cinematicAction(cinematicEnabled)
                } label: {
                    EmptyView()
                }
                .buttonStyle(
                    StateableButton(change: { _ in
                        Text("CINEMATIC")
                            .foregroundColor(.white)
                            .font(.barlow(.medium, size: 12))
                            .background(
                                Capsule()
                                    .foregroundColor(cinematicEnabled ? .second : .black)
                                    .padding(.vertical, -7.5)
                                    .padding(.horizontal, -10)
                            )
                    })
                )
                .frame(width: 100, height: 30)
                
            }
            .padding(.bottom, 20)
        }
        .frame(height: 120)
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
    
}
