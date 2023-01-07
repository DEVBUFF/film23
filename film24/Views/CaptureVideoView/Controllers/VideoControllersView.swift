//
//  VideoControllersView.swift
//  film24
//
//  Created by Igor Ryazancev on 05.01.2023.
//

import SwiftUI

struct VideoControllersView: View {
    
    @State private var autoFocusEnabled = true
    @State private var cinematicEnabled = false
    @State private var hasNotch = UIDevice.current.hasNotch
    
    var cinematicAction: (Bool)->()
    var autoFocusAction: (Bool)->()
    
    var body: some View {
        ZStack() {
            VisualEffectView(effect: UIBlurEffect(style: .dark))
                .cornerRadius(20, corners: [.topLeft, .topRight])
                .cornerRadius(hasNotch ? 46 : 0, corners: [.bottomLeft, .bottomRight])
                .padding(2)
            
            HStack {
                VStack(spacing: 20) {
                    Text("SLOWLY")
                        .foregroundColor(.white.opacity(0.3))
                        .font(.barlow(.medium, size: 11))
                    Button {
                        
                    } label: {
                        Text("OFF")
                            .foregroundColor(.white)
                            .font(.barlow(.medium, size: 12))
                            .background(
                                Capsule()
                                    .foregroundColor(.black)
                                    .padding(.vertical, -7.5)
                                    .padding(.horizontal, -10)
                            )
                        
                    }
                    
                }
                Spacer()
                Spacer()
                VStack(spacing: 20) {
                    Text("STABILIZATION")
                        .foregroundColor(.white.opacity(0.3))
                        .font(.barlow(.medium, size: 11))
                    Button {
                        cinematicEnabled.toggle()
                        cinematicAction(cinematicEnabled)
                    } label: {
                        Text("CINEMATIC")
                            .foregroundColor(.white)
                            .font(.barlow(.medium, size: 12))
                            .background(
                                Capsule()
                                    .foregroundColor(cinematicEnabled ? .second : .black)
                                    .padding(.vertical, -7.5)
                                    .padding(.horizontal, -10)
                            )
                    }
                    
                }
                Spacer()
                VStack(spacing: 20) {
                    Text("AUTO FOCUS")
                        .foregroundColor(.white.opacity(0.3))
                        .font(.barlow(.medium, size: 11))
                    Button {
                        autoFocusEnabled.toggle()
                        autoFocusAction(autoFocusEnabled)
                    } label: {
                        Text(autoFocusEnabled ? "ON" : "OFF")
                            .foregroundColor(.white)
                            .font(.barlow(.medium, size: 12))
                            .background(
                                Capsule()
                                    .foregroundColor(.black)
                                    .padding(.vertical, -7.5)
                                    .padding(.horizontal, -10)
                            )
                        
                    }
                    
                }
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 20)
        }
        .frame(height: 120)
        .ignoresSafeArea(.all)
    }
}
