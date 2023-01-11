//
//  FilterModel.swift
//  film24
//
//  Created by Igor Ryazancev on 06.01.2023.
//

import Foundation

struct FilterModel: Identifiable, Hashable, Codable {
    var id = UUID().uuidString
    
    let name: String
    let lutName: String
    var imageName: String?
    
    var isFavorite: Bool = false
    
    enum CodingKeys: String, CodingKey {
        case name
        case lutName = "lut_name"
        case imageName = "image_name"
    }
}
