import Foundation
import SwiftData
import SwiftUI

/// App theme preference
enum AppTheme: Int, Codable, CaseIterable {
    case system = 0
    case light = 1
    case dark = 2

    var displayName: String {
        switch self {
        case .system: return "System"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

@Model
final class UserSettings {
    /// Weekly minimum commitment (4-7 days)
    var weeklyMinimum: Int

    /// Whether onboarding has been completed
    var onboardingCompleted: Bool

    /// App theme preference (0 = system, 1 = light, 2 = dark)
    var appThemeRawValue: Int

    /// When the user first set up the app
    var createdAt: Date

    /// Last time settings were modified
    var updatedAt: Date

    var appTheme: AppTheme {
        get { AppTheme(rawValue: appThemeRawValue) ?? .system }
        set { appThemeRawValue = newValue.rawValue }
    }

    init(
        weeklyMinimum: Int = 4,
        onboardingCompleted: Bool = false,
        appTheme: AppTheme = .system,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.weeklyMinimum = max(4, min(7, weeklyMinimum))
        self.onboardingCompleted = onboardingCompleted
        self.appThemeRawValue = appTheme.rawValue
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    /// Update weekly minimum with validation
    func updateWeeklyMinimum(_ value: Int) {
        weeklyMinimum = max(4, min(7, value))
        updatedAt = .now
    }

    /// Update app theme
    func updateTheme(_ theme: AppTheme) {
        appTheme = theme
        updatedAt = .now
    }
}
