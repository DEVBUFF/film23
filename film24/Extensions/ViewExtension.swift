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

extension View {
    public func slidingRulerStyle<S>(_ style: S) -> some View where S: SlidingRulerStyle {
        environment(\.slidingRulerStyle, .init(style: style))
    }

    public func slidingRulerCellOverflow(_ overflow: Int) -> some View {
        environment(\.slidingRulerCellOverflow, overflow)
    }
}

extension View {
    func frame(size: CGSize?, alignment: Alignment = .center) -> some View {
        self.frame(width: size?.width, height: size?.height, alignment: alignment)
    }

    func onPreferenceChange<K: PreferenceKey>(_ key: K.Type,
                                              storeValueIn storage: Binding<K.Value>,
                                              action: (() -> ())? = nil ) -> some View where K.Value: Equatable {
        onPreferenceChange(key, perform: {
            storage.wrappedValue = $0
            action?()
        })
    }

    func propagateHeight<K: PreferenceKey>(_ key: K.Type, transform: @escaping (K.Value) -> K.Value = { $0 }) -> some View where K.Value == CGFloat? {
        overlay(
            GeometryReader { proxy in
                Color.clear
                    .preference(key: key, value: transform(proxy.size.height))
            }
        )
    }

    func propagateWidth<K: PreferenceKey>(_ key: K.Type, transform: @escaping (K.Value) -> K.Value = { $0 }) -> some View where K.Value == CGFloat? {
        overlay(
            GeometryReader { proxy in
                Color.clear
                    .preference(key: key, value: transform(proxy.size.width))
            }
        )
    }
}
