//
//  FiltersView.swift
//  film24
//
//  Created by Igor Ryazancev on 09.01.2023.
//

import SwiftUI

struct FiltersView: View {
    @Environment(\.presentationMode) var presentationMode

    @StateObject private var model = FiltersViewModel()
    
    @State private var gridItems = [
        GridItem(),
        GridItem(),
        GridItem()
    ]
    
    var selectedAction: (FilterModel)->()
    
    var body: some View {
        ZStack {
            Color.black
                .edgesIgnoringSafeArea(.all)
            
            VStack {
                closeView
                filtersScrollView
                    .padding(.horizontal, 32)
                Spacer()
            }
            
            
        }
    }
    
    @ViewBuilder
    private var closeView: some View {
        ZStack {
            HStack {
                Spacer()
                Button {
                    presentationMode.wrappedValue.dismiss()
                } label: {
                    Image("close")
                }
                .frame(width: 44, height: 44)
            }
            
            Text("FILTERS")
                .foregroundColor(.white)
                .font(.barlow(.medium, size: 16))
        }
        
        .padding(.top, 25)
    }
    
    @ViewBuilder
    private var filtersScrollView: some View {
        GeometryReader { _ in
            ScrollView(showsIndicators: false) {
                VStack(spacing: 32) {
                    ForEach(model.sections, id: \.self) { section in
                        VStack(spacing: 24) {
                            HStack {
                                Text(section.title.uppercased())
                                    .foregroundColor(.white)
                                    .font(.barlow(.medium, size: 12))
                                Spacer()
                            }
                            if section.filters.isEmpty {
                                infoView
                            } else {
                                LazyVGrid(columns: gridItems, spacing: 9) {
                                    ForEach(Array(section.filters.enumerated()), id: \.offset) { index, filter in
                                        
                                        ZStack(alignment: .top) {
                                            Image(filter.imageName ?? "")
                                                .resizable()
                                                .onTapGesture {
                                                    selectedAction(filter)
                                                    presentationMode.wrappedValue.dismiss()
                                                }
                                            
                                            VStack {
                                                Spacer()
                                                ZStack {
                                                    Rectangle()
                                                        .frame(height: 24)
                                                        .foregroundColor(.second)
                                                        .cornerRadius(8, corners: [.bottomLeft, .bottomRight])
                                                    
                                                    Text(filter.name.uppercased())
                                                        .foregroundColor(.black)
                                                        .font(.barlow(.medium, size: 10))
                                                }
                                                
                                                
                                            }
                                            
                                            if filter.isFavorite {
                                                HStack {
                                                    Spacer()
                                                    
                                                    Image("favorite")
                                                }
                                                .padding(.top, 4)
                                                .padding(.trailing, 4)
                                            }
                                        }
                                        
                                        .contextMenu {
                                            Button {
                                                if filter.isFavorite {
                                                    settings.favoriteFilters.removeAll(where: { $0 == filter.name })
                                                    DispatchQueue.main.asyncAfter(deadline: .now()+1) {
                                                        model.updateFavorites()
                                                    }
                                                    
                                                } else if !settings.favoriteFilters.contains(filter.name) {
                                                    
                                                    settings.favoriteFilters.append(filter.name)
                                                    DispatchQueue.main.asyncAfter(deadline: .now()+1) {
                                                        model.updateFavorites()
                                                    }
                                                }
                                                
                                            } label: {
                                                Label(filter.isFavorite ? "Remove from Favorite" : "Add to Favorite", systemImage: filter.isFavorite ? "trash" : "star")
                                            }
                                            
                                            Button {
                                                print("Enable geolocation")
                                            } label: {
                                                Label("Close", systemImage: "")
                                            }
                                        }
                                        
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private var infoView: some View {
        ZStack {
            Rectangle()
                .foregroundColor(.clear)
                .cornerRadius(8)
                .frame(height: 74)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
            Text("To add a filter to your favorites,\nlong press on the filter".uppercased())
                .multilineTextAlignment(.center)
                .foregroundColor(.white.opacity(0.5))
                .font(.barlow(.regular, size: 12))
            
        }
    }
}

struct FiltersView_Previews: PreviewProvider {
    static var previews: some View {
        FiltersView { _ in }
    }
}
