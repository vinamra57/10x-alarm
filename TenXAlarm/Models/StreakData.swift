import Foundation
import SwiftData

@Model
final class StreakData {
    /// Current streak count
    var currentStreak: Int

    /// Longest streak ever achieved
    var longestStreak: Int

    /// Date of last successful verification
    var lastVerificationDate: Date?

    /// Total number of successful verifications
    var totalVerifications: Int

    /// Date when streak was last reset (for analytics)
    var lastStreakResetDate: Date?

    init(
        currentStreak: Int = 0,
        longestStreak: Int = 0,
        lastVerificationDate: Date? = nil,
        totalVerifications: Int = 0,
        lastStreakResetDate: Date? = nil
    ) {
        self.currentStreak = currentStreak
        self.longestStreak = longestStreak
        self.lastVerificationDate = lastVerificationDate
        self.totalVerifications = totalVerifications
        self.lastStreakResetDate = lastStreakResetDate
    }

    /// Increment streak after successful verification
    func incrementStreak() {
        currentStreak += 1
        totalVerifications += 1
        lastVerificationDate = .now

        if currentStreak > longestStreak {
            longestStreak = currentStreak
        }
    }

    /// Reset streak to zero
    func resetStreak() {
        currentStreak = 0
        lastStreakResetDate = .now
    }

    /// Check if verified today
    var hasVerifiedToday: Bool {
        guard let lastDate = lastVerificationDate else { return false }
        return Calendar.current.isDateInToday(lastDate)
    }

    /// Days since last verification
    var daysSinceLastVerification: Int? {
        guard let lastDate = lastVerificationDate else { return nil }
        return Calendar.current.dateComponents([.day], from: lastDate, to: .now).day
    }
}
