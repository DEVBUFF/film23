//
//  EditVideoViewModel.swift
//  film24
//
//  Created by Igor Ryazancev on 07.01.2023.
//

import Foundation
import Combine

final class EditVideoViewModel: ObservableObject {
    
    @Published var videoUrl: URL
    
    init(url: URL) {
        self.videoUrl = url
    }
    
}
