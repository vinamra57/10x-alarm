import Foundation
import SwiftData

@Model
final class UserSettings {
    /// Weekly minimum commitment (4-7 days)
    var weeklyMinimum: Int

    /// Whether onboarding has been completed
    var onboardingCompleted: Bool

    /// When the user first set up the app
    var createdAt: Date

    /// Last time settings were modified
    var updatedAt: Date

    init(
        weeklyMinimum: Int = 4,
        onboardingCompleted: Bool = false,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.weeklyMinimum = max(4, min(7, weeklyMinimum))
        self.onboardingCompleted = onboardingCompleted
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    /// Update weekly minimum with validation
    func updateWeeklyMinimum(_ value: Int) {
        weeklyMinimum = max(4, min(7, value))
        updatedAt = .now
    }
}
