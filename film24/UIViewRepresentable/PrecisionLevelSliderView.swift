//
//  PrecisionLevelSliderView.swift
//  film24
//
//  Created by Igor Ryazancev on 12.01.2023.
//

import SwiftUI

struct PrecisionLevelSliderView: UIViewRepresentable {
    var effect: UIVisualEffect?
    func makeUIView(context: UIViewRepresentableContext<Self>) -> PrecisionLevelSlider {
        let slider = PrecisionLevelSlider()
        slider.maximumValue = 2
        
        return slider
    }
    func updateUIView(_ uiView: PrecisionLevelSlider, context: UIViewRepresentableContext<Self>) {
        
    }
}
