//
//  ExposureControllerView.swift
//  film24
//
//  Created by Igor Ryazancev on 06.01.2023.
//

import SwiftUI

struct ExposureControllerView: View {
    
    @State private var value: CGFloat = 0.0
    
    private var formatter: NumberFormatter {
        let f = NumberFormatter()
        f.numberStyle = .percent
        f.maximumFractionDigits = 0
        return f
    }
    
    var valueChangedAction: (CGFloat)->()
    
    var body: some View {
        VStack(alignment: .trailing) {
            Image("exposure")
            
//            Image("union")
//                .frame(height: 225)
//                .gesture(
//                    DragGesture()
//                        .onChanged({ v in
//                            var loc = v.startLocation.y - v.location.y
//
//                            if loc > 225 {
//                                loc = 225
//                            } else if loc < -225 {
//                                loc = -225
//                            }
//
//                            let val = ((loc/100) / (225/100)*100)/50
//
//                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
//
//                            value = CGFloat(val)
//
//                            valueChangedAction(value)
//                        })
//                        .onEnded({ _ in print("End")})
//                )
            
            ZStack {
                Rectangle()
                    .foregroundColor(.clear)
                    .frame(height: 225)
                    .frame(width: 20)
                SlidingRuler(value: $value,
                             in: -2...2,
                             step: 1,
                             snap: .fraction,
                             tick: .fraction,
                             onEditingChanged: { _ in
                    valueChangedAction(value)
                })
                
                
                .rotationEffect(Angle(degrees: 90))
                .frame(width: 225)
                .frame(height: 20)
                .padding(.trailing, -100)
            }
            .mask(
                LinearGradient(gradient: Gradient(colors: [.black, .black, .black, .clear]), startPoint: .bottom, endPoint: .top)
            )
            .mask(
                LinearGradient(gradient: Gradient(colors: [.black, .black, .black, .clear]), startPoint: .top, endPoint: .bottom)
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
