//
//  EditVideoView.swift
//  film24
//
//  Created by Igor Ryazancev on 06.01.2023.
//

import SwiftUI
import AVKit

struct EditVideoView: View {
    
    @StateObject var model: EditVideoViewModel
    @Binding var showed: Bool
    @State private var player: AVPlayer
    @State private var progressTime: String = "00:00"
    
    init(model: EditVideoViewModel, showed: Binding<Bool>) {
        self._model = StateObject(wrappedValue: model)
        self._showed = showed
        self._player = State(initialValue: AVPlayer(url: model.videoUrl))
    }
    
    var body: some View {
        ZStack {
            Color.black
            
            ZStack(alignment: .bottom) {
                VideoPreviewView(url: model.videoUrl, player: player)
                    .edgesIgnoringSafeArea(.all)
                
                LinearGradient(colors: [.black, .clear], startPoint: .bottom, endPoint: .top)
                    .frame(height: 130)
            }
            .padding(.bottom, 110)
            
            VStack(spacing: 27) {
                Spacer()
                
                VideoTrimmerView(
                    videoUrl: model.videoUrl,
                    player: player,
                    progressTime: $progressTime
                )
                .frame(height: 60)
                .padding(.horizontal, 25)
                
                VStack(spacing: 8) {
                    Button {
                        model.saveVideoToPhotos(url: model.videoUrl) {
                            showed = false
                        }
                    } label: {
                        Text("SAVE")
                            .font(.barlow(.regular, size: 28))
                            .foregroundLinearGradient(
                                colors: [.main, .second],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                    }
                    
                    Text("AND SHARE")
                        .font(.barlow(.regular, size: 12))
                        .foregroundColor(.white.opacity(0.3))
                }
            }
            .padding(.bottom, 45)
            
            VStack {
                HStack {
                    Spacer()
                    Button {
                        showed = false
                    } label: {
                        Image("close")
                    }
                    .frame(width: 44, height: 44)
                }
                .padding(.horizontal, 10)
                
                Spacer()
            }
            .padding(.top, 50)
            
            VStack {
                Text(progressTime)
                    .foregroundColor(.black)
                    .font(.barlow(.regular, size: 14))
                    .background(
                        Capsule()
                            .foregroundColor(.white)
                            .padding(.vertical, -8)
                            .padding(.horizontal, -10)
                    )
                Spacer()
            }
                .padding(.top, 56)
        }
    }
    
    func share() {
        let activityController = UIActivityViewController(activityItems: [model.videoUrl], applicationActivities: nil)
        
        UIApplication.shared.windows.first?.rootViewController!.present(activityController, animated: true, completion: nil)
    }
}

