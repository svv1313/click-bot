//
//  ClickerSettings.swift
//  ClickerApp
//
//  Settings model with UserDefaults persistence
//

import Foundation
import SwiftUI

class ClickerSettings: ObservableObject {
    // UserDefaults keys
    private enum Keys {
        static let minInterval = "minInterval"
        static let maxInterval = "maxInterval"
        static let restrictToFrontmostApp = "restrictToFrontmostApp"
        static let allowedBundleID = "allowedBundleID"
        static let pauseAfterUserInputSeconds = "pauseAfterUserInputSeconds"
    }
    
    // Default values
    private let defaultMinInterval: Int = 80
    private let defaultMaxInterval: Int = 120
    private let defaultPauseAfterUserInputSeconds: Double = 1.5
    
    // Published properties that persist to UserDefaults
    @Published var minInterval: Int {
        didSet {
            UserDefaults.standard.set(minInterval, forKey: Keys.minInterval)
        }
    }
    
    @Published var maxInterval: Int {
        didSet {
            UserDefaults.standard.set(maxInterval, forKey: Keys.maxInterval)
        }
    }
    
    @Published var restrictToFrontmostApp: Bool {
        didSet {
            UserDefaults.standard.set(restrictToFrontmostApp, forKey: Keys.restrictToFrontmostApp)
        }
    }
    
    @Published var allowedBundleID: String {
        didSet {
            UserDefaults.standard.set(allowedBundleID, forKey: Keys.allowedBundleID)
        }
    }
    
    @Published var pauseAfterUserInputSeconds: Double {
        didSet {
            UserDefaults.standard.set(pauseAfterUserInputSeconds, forKey: Keys.pauseAfterUserInputSeconds)
        }
    }
    
    init() {
        // Load from UserDefaults or use defaults
        self.minInterval = UserDefaults.standard.object(forKey: Keys.minInterval) as? Int ?? defaultMinInterval
        self.maxInterval = UserDefaults.standard.object(forKey: Keys.maxInterval) as? Int ?? defaultMaxInterval
        self.restrictToFrontmostApp = UserDefaults.standard.bool(forKey: Keys.restrictToFrontmostApp)
        self.allowedBundleID = UserDefaults.standard.string(forKey: Keys.allowedBundleID) ?? ""
        self.pauseAfterUserInputSeconds = UserDefaults.standard.object(forKey: Keys.pauseAfterUserInputSeconds) as? Double ?? defaultPauseAfterUserInputSeconds
        
        // Validate intervals
        if minInterval < 1 { minInterval = defaultMinInterval }
        if maxInterval < minInterval { maxInterval = minInterval }
    }
    
    // Validation helper
    func validateIntervals() {
        if minInterval < 1 {
            minInterval = defaultMinInterval
        }
        if maxInterval < minInterval {
            maxInterval = minInterval
        }
    }
}
