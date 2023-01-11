//
//  SettingsView.swift
//  film24
//
//  Created by Igor Ryazancev on 08.01.2023.
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.presentationMode) var presentationMode
    
    @State private var showExplanation = true
    
    init() {
        self._showExplanation = State(initialValue: settings.shouldSaveOriginal)
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            Image("settings_bg")
                .resizable()
                .aspectRatio(contentMode: .fill)
            
            VStack(spacing: 55) {
                VStack(alignment: .leading, spacing: 32) {
                    HStack(spacing: 24) {
                        Image("settings_cinematic")
                        
                        Text("Shoot cinematic videos at\n24fps like Hollywood\nmovies".uppercased())
                            .foregroundColor(.white)
                            .font(.barlow(.regular, size: 12))
                        Spacer()
                    }
                    HStack(spacing: 24) {
                        Image("settings_slow")
                        
                        Text("Add drama to your videos\nwith the slow motion\nfeature".uppercased())
                            .foregroundColor(.white)
                            .font(.barlow(.regular, size: 12))
                        Spacer()
                    }
                    HStack(spacing: 24) {
                        Image("settings_stab")
                        
                        Text("Stabilization for full\nfluidity of your videos".uppercased())
                            .foregroundColor(.white)
                            .font(.barlow(.regular, size: 12))
                        Spacer()
                    }
                    
                }
                .padding(.horizontal, 32)
                .padding(.top, 89)
                
                VStack(spacing: 32) {
                    HStack {
                        Text("SAVE ORIGINAL")
                            .foregroundColor(.white)
                            .font(.barlow(.medium, size: 16))
                        
                        Toggle("", isOn: $showExplanation)
                            .onChange(of: showExplanation, perform: { newValue in
                                settings.shouldSaveOriginal = showExplanation
                            })
                            .toggleStyle(SwitchToggleStyle(tint: .main))
                        
                    }
                    if showExplanation {
                        ZStack {
                            Rectangle()
                                .foregroundColor(.clear)
                                .cornerRadius(8)
                                .frame(height: 74)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                )
                            Text("We will save 2 files to your iPhone.\nWith filter and original".uppercased())
                                .multilineTextAlignment(.center)
                                .foregroundColor(.white.opacity(0.5))
                                .font(.barlow(.regular, size: 12))
                            
                        }
                    }
                    
                    Button {
                        UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
                    } label: {
                        Text("CANCEL SUBSCRIBTION")
                            .foregroundColor(.white.opacity(0.3))
                            .font(.barlow(.regular, size: 12))
                    }

                    
                }
                .padding(.horizontal, 32)
                
            }
            
            
            VStack {
                Spacer()
                
                Button {
                    presentationMode.wrappedValue.dismiss()
                } label: {
                    Text("CLOSE")
                        .foregroundColor(.second)
                        .font(.barlow(.medium, size: 16))
                }

            }
            .padding(.bottom, 81)
        }
        .edgesIgnoringSafeArea(.all)
    }
}
