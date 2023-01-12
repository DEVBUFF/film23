//
//  FrameView.swift
//  film24
//
//  Created by Igor Ryazancev on 05.01.2023.
//

import SwiftUI

struct FrameView: View {
    
    var image: CGImage?
    @Binding var bottomPadding: CGFloat
    @State private var showTapView = false
    @State private var location: CGPoint = .zero
    var touchAction: (CGPoint, CGSize)->()
    private let label = Text("Camera feed")
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                if let image = image {
                    Image(image, scale: 1.0, orientation: .upMirrored, label: label)
                        .resizable()
                        .scaledToFill()
                        .frame(
                            width: geometry.size.width,
                            height: geometry.size.height-bottomPadding,
                            alignment: .center)
                        .clipped()
                        .cornerRadius(bottomPadding == 0 ? 0 : 30, corners: [.bottomRight, .bottomLeft])
                        .onTouch(type: .started) { location in
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            withAnimation {
                                showTapView = true
                            }
                            self.location = location
                            touchAction(location, geometry.size)
                            
                            DispatchQueue.main.asyncAfter(deadline: .now()+1.5) {
                                withAnimation {
                                    showTapView = false
                                }
                            }
                        }
                    
                    
                } else {
                    Color.black
                }
                
                if showTapView {
                    Rectangle()
                        .frame(width: 80, height: 80)
                        .foregroundColor(.clear)
                        .overlay(
                            Rectangle()
                                .stroke(Color.second, lineWidth: 0.5)
                        )
                        .position(location)
                }
            }
        }.edgesIgnoringSafeArea(.all)
    }
}

