//
//  UIDeviceExtension.swift
//  film24
//
//  Created by Igor Ryazancev on 06.01.2023.
//

import UIKit

extension UIDevice {
    var hasNotch: Bool {
        guard let window = UIApplication.shared.windows.filter({$0.isKeyWindow}).first else { return false }
        if UIDevice.current.orientation.isPortrait {
            return window.safeAreaInsets.top >= 44
        } else {
            return window.safeAreaInsets.left > 0 || window.safeAreaInsets.right > 0
        }
    }
}
