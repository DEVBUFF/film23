//
//  FilterModel.swift
//  film24
//
//  Created by Igor Ryazancev on 06.01.2023.
//

import Foundation

struct FilterModel: Identifiable, Hashable {
    var id = UUID().uuidString
    
    let name: String
    let lutName: String
}
