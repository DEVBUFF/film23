//
//  PaywallView.swift
//  film24
//
//  Created by Igor Ryazancev on 05.01.2023.
//

import SwiftUI
import AVKit

struct PaywallView: View {
    
    @StateObject private var model = PaywallViewModel()
    @State private var selectedIndex = 0
    
    var action: ()->()
    
    var body: some View {
        ZStack(alignment: .top) {
            pagerVideos
            topTitle
            
            VStack {
                Spacer()
                
                VStack(alignment: .leading, spacing: 50) {
                    VStack(alignment: .leading, spacing: 33) {
                        Text("Shoot every video like a movie")
                            .foregroundColor(.white)
                            .font(.barlow(.light, size: 34))
                            .id(selectedIndex)
                        
                        PageControler(index: $selectedIndex,
                                      maxIndex: 2)
                    }
                    
                    VStack(alignment: .leading, spacing: 24) {
                        Button {
                            action()
                        } label: {
                            EmptyView()
                        }
                        .buttonStyle(
                            StateableButton(change: { state in
                                ZStack {
                                    Image("start_free")
                                        .frame(height: 61)
                                    
                                    Text("START FREE")
                                        .foregroundColor(.white)
                                        .font(.barlow(.regular, size: 18))
                                }
                                .scaleEffect(state ? 0.99 : 1)
                            })
                        )
                        
                        
                        VStack(alignment: .leading, spacing: 36) {
                            HStack {
                                Text("30 DAYS FREE")
                                    .font(.barlow(.medium, size: 14))
                                    .foregroundColor(.second)

                                Spacer()

                                Text("AFTER $4,99 $1,99/MO")
                                    .font(.barlow(.regular, size: 14))
                                    .foregroundColor(.white)
                            }
                            
                            HStack {
                                Text("PRIVACY POLICY & TERMS")
                                    .font(.barlow(.regular, size: 12))
                                    .foregroundColor(.onboardButtons)

                                Spacer()

                                Text("RESTORE")
                                    .font(.barlow(.regular, size: 12))
                                    .foregroundColor(.onboardButtons)
                            }
                        }
                        
                    }
                    

                }
            }
            .padding(.horizontal, 40)
            
            VStack {
                HStack {
                    Spacer()
                    
                    Button {
                        action()
                    } label: {
                        Image("close")
                    }
                    .frame(width: 44, height: 44)
                }
                Spacer()
            }
        }
        
    }
    
    @ViewBuilder
    private var linearGradient: some View {
        LinearGradient(
            gradient: Gradient(
            colors: [.clear, .clear, .black]
            ),
                       startPoint: .top,
                       endPoint: .bottom
        )
    }
    
    @ViewBuilder
    private var pagerVideos: some View {
        ZStack {
            PagerView(pageCount: 3, currentIndex: $selectedIndex) {
                ZStack {
                    VideoView(url: Bundle.main.url(forResource: "1", withExtension: "mp4")!)
                    linearGradient
                }
                ZStack {
                    VideoView(url: Bundle.main.url(forResource: "1", withExtension: "mp4")!)
                    linearGradient
                }
                ZStack {
                    VideoView(url: Bundle.main.url(forResource: "1", withExtension: "mp4")!)
                    linearGradient
                }
            }
        }
        .ignoresSafeArea(edges: .all)
    }
    
    @ViewBuilder
    private var topTitle: some View {
        HStack {
            Circle()
                .stroke(.white, lineWidth: 1.5)
                .background(Circle().fill(Color.main))
                .frame(width: 18, height: 18)
                
            Text("24FILM")
                .foregroundColor(.white)
                .font(.barlow(.medium, size: 15))
        }
        .padding(.top, 25)
    }
    
    struct PageControler: View {
        @Binding var index: Int
        let maxIndex: Int

        var body: some View {
            HStack(spacing: 8) {
                ForEach(0...maxIndex, id: \.self) { index in
                    Rectangle()
                        .fill(index == self.index ? Color.white : Color.white.opacity(0.2))
                        .frame(width: 24, height: 4)
                        .cornerRadius(2)
                }
            }
            
        }
    }
}

#if DEBUG
struct PaywallView_Previews: PreviewProvider {
    static var previews: some View {
        PaywallView {}
    }
}
#endif
