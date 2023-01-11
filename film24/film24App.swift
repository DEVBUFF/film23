//
//  film24App.swift
//  film24
//
//  Created by Igor Ryazancev on 03.01.2023.
//

import SwiftUI

@main
struct film24App: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    @State var videoShow = false
    
    var body: some Scene {
        WindowGroup {
            if videoShow {
                CaptureVideoView()
            } else {
                PaywallView {
                    videoShow = true
                }
            }
        }
    }
}
