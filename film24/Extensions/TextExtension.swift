//
//  TextExtension.swift
//  film24
//
//  Created by Igor Ryazancev on 07.01.2023.
//

import SwiftUI

extension Text {
    public func foregroundLinearGradient(
        colors: [Color],
        startPoint: UnitPoint,
        endPoint: UnitPoint) -> some View
    {
        self.overlay(
            LinearGradient(
                colors: colors,
                startPoint: startPoint,
                endPoint: endPoint
            )
            .mask(
                self

            )
        )
    }
}
