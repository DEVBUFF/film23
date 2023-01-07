//
//  FiltersControllerView.swift
//  film24
//
//  Created by Igor Ryazancev on 06.01.2023.
//

import SwiftUI

struct FiltersControllerView: View {
    
    @State var filters: [FilterModel]
    @Binding var selectedIndex: Int
    
    var body: some View {
        ZStack {
            Carousel(spacing: 25, trailingSpace: 170, index: $selectedIndex, items: filters) { filter in
                Text(filter.name.uppercased())
                    .font(.barlow(.medium, size: 14))
            }
            .disabled(true)
        }
        .mask(
            LinearGradient(gradient: Gradient(colors: [.black, .black, .black, .clear]), startPoint: .leading, endPoint: .trailing)
        )
        .mask(
            LinearGradient(gradient: Gradient(colors: [.black, .black, .black, .clear]), startPoint: .trailing, endPoint: .leading)
        )
        .frame(width: 230)
    }
}
