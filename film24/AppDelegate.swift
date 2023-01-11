//
//  AppDelegate.swift
//  film24
//
//  Created by Igor Ryazancev on 10.01.2023.
//

import UIKit

let settings = LocalSettings()

class AppDelegate: NSObject, UIApplicationDelegate {
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        IAPManager.shared.loadProducts()
        return true
    }
    
}
