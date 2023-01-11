//
//  CMTimeExtension.swift
//  film24
//
//  Created by Igor Ryazancev on 08.01.2023.
//

import UIKit
import AVKit

extension CMTime {
    var displayString: String {
        let offset = TimeInterval(seconds)
        let numberOfNanosecondsFloat = (offset - TimeInterval(Int(offset))) * 1000.0
        let nanoseconds = Int(numberOfNanosecondsFloat)
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .positional
        formatter.zeroFormattingBehavior = .pad
        formatter.allowedUnits = [.minute, .second]
        return String(format: "%@", formatter.string(from: offset) ?? "00:00", nanoseconds)
    }
}
