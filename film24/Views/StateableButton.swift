//
//  StateableButton.swift
//  film24
//
//  Created by Igor Ryazancev on 05.01.2023.
//

import SwiftUI

struct StateableButton<Content>: ButtonStyle where Content: View {
    var change: (Bool) -> Content
    
    func makeBody(configuration: Configuration) -> some View {
        return change(configuration.isPressed)
    }
}
