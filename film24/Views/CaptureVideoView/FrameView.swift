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
    var touchAction: (CGPoint)->()
    private let label = Text("Camera feed")
    
    var body: some View {
        ZStack {
            if let image = image {
              GeometryReader { geometry in
                Image(image, scale: 1.0, orientation: .upMirrored, label: label)
                  .resizable()
                  .scaledToFill()
                  .frame(
                    width: geometry.size.width,
                    height: geometry.size.height-bottomPadding,
                    alignment: .center)
                  .clipped()
                  .cornerRadius(bottomPadding == 0 ? 0 : 30, corners: [.bottomRight, .bottomLeft])
                  .onTouch(type: .started, perform: updateLocation)
                  
              }
            } else {
              Color.black
            }
        }
    }
    
    func updateLocation(_ location: CGPoint) {
        touchAction(location)
    }
}

