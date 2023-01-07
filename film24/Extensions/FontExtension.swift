//
//  FontExtension.swift
//  film24
//
//  Created by Igor Ryazancev on 05.01.2023.
//
import SwiftUI

extension Font {
    enum BarlowFont {
        case light
        case regular
        case medium
        case bold
        
        var value: String {
            switch self {
            case .light:
                return "Barlow-Light"
            case .regular:
                return "Barlow-Regular"
            case .medium:
                return "Barlow-Medium"
            case .bold:
                return "Barlow-Bold"
            }
        }
    }
    
    static func barlow(_ type: BarlowFont, size: CGFloat = 17) -> Font {
        return .custom(type.value, size: size)
    }
    
}
