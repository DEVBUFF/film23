//
//  FiltersViewModel.swift
//  film24
//
//  Created by Igor Ryazancev on 09.01.2023.
//

import Foundation
import Combine

final class FiltersViewModel: ObservableObject {
    
    @Published var sections: [FiltersSectionModel] = []
    
    private let localFilesService = LocalFilesService()
    
    init() {
        loadSections()
        updateFavorites()
    }
    
}

//MARK: - Public methods
extension FiltersViewModel {
    
    func updateFavorites() {
        sections[0].filters = []
        settings.favoriteFilters.forEach { filterName in
            sections[0].filters.append(
                FilterModel(
                    name: filterName,
                    lutName: "",
                    imageName: "filter_demo",
                    isFavorite: true
                )
            )
        }
    }
    
}

//MARK: - Private methods
private extension FiltersViewModel {
    
    func loadSections() {
        if let json = localFilesService.readLocalJSONFile(forName: "filters_sections") {
            sections = localFilesService.parse(jsonData: json) ?? []
            sections.insert(FiltersSectionModel(title: "favorites", filters: []), at: 0)
        }
    }
    
}
