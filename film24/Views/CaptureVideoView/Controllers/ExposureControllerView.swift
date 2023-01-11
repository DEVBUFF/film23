//
//  ExposureControllerView.swift
//  film24
//
//  Created by Igor Ryazancev on 06.01.2023.
//

import SwiftUI

struct ExposureControllerView: View {
    
    @State private var value: CGFloat = 0.0
    
    var valueChangedAction: (CGFloat)->()
    
    var body: some View {
        VStack {
            Image("exposure")
            
            Image("union")
                .frame(height: 225)
                .gesture(
                    DragGesture()
                        .onChanged({ v in
                            var loc = v.startLocation.y - v.location.y
                            
                            if loc > 225 {
                                loc = 225
                            } else if loc < -225 {
                                loc = -225
                            }
                            
                            let val = ((loc/100) / (225/100)*100)/50
                            
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            
                            value = CGFloat(val)
                            
                            valueChangedAction(value)
                        })
                        .onEnded({ _ in print("End")})
                )
            
            Text(String(format: "%.1f", -value))
                .font(.barlow(.medium, size: 12))
                .foregroundColor(.white)
            
            Rectangle()
                .foregroundColor(.clear)
                .frame(width: 20, height: 150)
        }
    }
}
