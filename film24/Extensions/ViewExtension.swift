//
//  ViewExtension.swift
//  film24
//
//  Created by Igor Ryazancev on 06.01.2023.
//

import SwiftUI

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape( RoundedCorner(radius: radius, corners: corners) )
    }    
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}

extension View {
    func onClickGesture(
        count: Int,
        coordinateSpace: CoordinateSpace = .local,
        perform action: @escaping (CGPoint) -> Void
    ) -> some View {
        gesture(ClickGesture(count: count, coordinateSpace: coordinateSpace)
            .onEnded(perform: action)
        )
    }
    
    func onClickGesture(
        count: Int,
        perform action: @escaping (CGPoint) -> Void
    ) -> some View {
        onClickGesture(count: count, coordinateSpace: .local, perform: action)
    }
    
    func onClickGesture(
        perform action: @escaping (CGPoint) -> Void
    ) -> some View {
        onClickGesture(count: 1, coordinateSpace: .local, perform: action)
    }
}
