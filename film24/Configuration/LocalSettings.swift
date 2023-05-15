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
        static let kIsFirstLaunch = "kIsFirstLaunch"
        static let kOnboardShowed = "kOnboardShowed"
        static let kSaveOriginal = "kSaveOriginal"
        static let kFavoriteFilters = "kFavoritesFilters"
        static let kStabilization = "kStabilization"
        static let kSlowly = "kSlowly"
        static let kAutoFocus = "kAutoFocus"
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
    
    var isFirstLaunch: Bool {
        get {
            return LocalSettings.value(for: LocalSettings.Keys.kIsFirstLaunch) ?? true
        }
        set {
            LocalSettings.set(value: newValue, for: LocalSettings.Keys.kIsFirstLaunch)
        }
    }
    
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
    
    var stabilization: Stabilisation {
        get {
            return Stabilisation(rawValue: LocalSettings.value(for: LocalSettings.Keys.kStabilization) ?? "off") ?? .off
        }
        set {
            LocalSettings.set(value: newValue.rawValue, for: LocalSettings.Keys.kStabilization)
        }
    }
    
    var autoFocus: Bool {
        get {
            return LocalSettings.value(for: LocalSettings.Keys.kSaveOriginal) ?? false
        }
        set {
            LocalSettings.set(value: newValue, for: LocalSettings.Keys.kSaveOriginal)
        }
    }
    
    var slowly: Slowly {
        get {
            return Slowly(rawValue: LocalSettings.value(for: LocalSettings.Keys.kSlowly) ?? "off") ?? .off
        }
        set {
            LocalSettings.set(value: newValue.rawValue, for: LocalSettings.Keys.kSlowly)
        }
    }
    
}

extension LocalSettings {
    
    enum Stabilisation: String {
        case off = "off"
        case standard = "standard"
        case cinematic = "cinematic"
    }
    
    enum Slowly: String {
        case off = "off"
        case normal = "normal"
        case drama = "drama"
    }
    
}
