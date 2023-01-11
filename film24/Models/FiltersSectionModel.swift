//
//  FiltersSectionModel.swift
//  film24
//
//  Created by Igor Ryazancev on 09.01.2023.
//

import Foundation

struct FiltersSectionModel: Codable, Identifiable, Hashable {
    var id = UUID().uuidString
    
    var title: String
    var filters: [FilterModel]
    
    enum CodingKeys: String, CodingKey {
        case title
        case filters
    }
}
