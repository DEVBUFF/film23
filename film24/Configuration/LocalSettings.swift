//
//  LocalSettings.swift
//  Photo Vault
//
//  Created by Igor Ryazancev on 03.11.2022.
//

import Foundation

final class LocalSettings {
    
    //MARK: - AppSettings
    private struct Keys {
        static let kOnboardShowed = "kOnboardShowed"
        static let kSaveOriginal = "kSaveOriginal"
        static let kFavoriteFilters = "kFavoritesFilters"
    }
    
    //MARK: - Private methods
    fileprivate static func set(value: Any?, for key: String) {
        UserDefaults.standard.set(value, forKey: key)
    }
    
    fileprivate static func value<T>(for key: String) -> T? {
        return UserDefaults.standard.value(forKey: key) as? T
    }
    
}

//MARK: - Public methods
extension LocalSettings {
    
    var onboardShowed: Bool {
        get {
            return LocalSettings.value(for: LocalSettings.Keys.kOnboardShowed) ?? false
        }
        set {
            LocalSettings.set(value: newValue, for: LocalSettings.Keys.kOnboardShowed)
        }
    }
    
    var shouldSaveOriginal: Bool {
        get {
            return LocalSettings.value(for: LocalSettings.Keys.kSaveOriginal) ?? true
        }
        set {
            LocalSettings.set(value: newValue, for: LocalSettings.Keys.kSaveOriginal)
        }
    }
    
    var favoriteFilters: [String] {
        get {
            return LocalSettings.value(for: LocalSettings.Keys.kFavoriteFilters) ?? []
        }
        set {
            LocalSettings.set(value: newValue, for: LocalSettings.Keys.kFavoriteFilters)
        }
    }
    
}
