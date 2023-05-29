//
//  LoadingView.swift
//  film24
//
//  Created by Igor Ryazancev on 23.05.2023.
//

import SwiftUI

struct LoadingView: View {
    
    @State var foregroundColor: Color = .white
    @State var color: UIColor? = .white
    @State var style: UIActivityIndicatorView.Style = .large
    
    var body: some View {
        ZStack(alignment: .center) {
            ActivityIndicator(isAnimating: .constant(true), style: style, color: color)
                .foregroundColor(foregroundColor)
        }
        .edgesIgnoringSafeArea(.all)
    }
}

struct ActivityIndicator: UIViewRepresentable {

    @Binding var isAnimating: Bool
    let style: UIActivityIndicatorView.Style
    @State var color: UIColor? = .white

    func makeUIView(context: UIViewRepresentableContext<ActivityIndicator>) -> UIActivityIndicatorView {
        let activityView = UIActivityIndicatorView(style: style)
        activityView.color = color
        return activityView
    }

    func updateUIView(_ uiView: UIActivityIndicatorView, context: UIViewRepresentableContext<ActivityIndicator>) {
        isAnimating ? uiView.startAnimating() : uiView.stopAnimating()
    }
}

