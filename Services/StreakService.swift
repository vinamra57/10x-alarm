import Foundation
import SwiftData

/// Service for managing streak logic
///
/// Streak Rules:
/// - Alarm day verified → Streak +1
/// - Rest day (no alarm) → Streak resets to 0
/// - Only 7-day/week users can achieve infinite streaks
@Observable
final class StreakService {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Streak Data Access

    /// Get or create the singleton StreakData
    func getStreakData() throws -> StreakData {
        let descriptor = FetchDescriptor<StreakData>()
        let results = try modelContext.fetch(descriptor)

        if let existing = results.first {
            return existing
        }

        // Create new streak data
        let streakData = StreakData()
        modelContext.insert(streakData)
        try modelContext.save()
        return streakData
    }

    // MARK: - Streak Operations

    /// Record a successful verification and update streak
    func recordVerification(wasAlarmDay: Bool) throws {
        let streakData = try getStreakData()

        // Check if we need to reset streak first (rest day occurred)
        try checkForMissedDays(streakData: streakData)

        // Increment streak
        streakData.incrementStreak()

        // Record the verification
        let verification = Verification(
            wasAlarmDay: wasAlarmDay,
            result: .pass
        )
        modelContext.insert(verification)

        try modelContext.save()
    }

    /// Check if any rest days have occurred since last verification
    /// If so, reset the streak
    func checkForMissedDays(streakData: StreakData) throws {
        guard let lastVerification = streakData.lastVerificationDate else {
            // No previous verification, nothing to check
            return
        }

        let schedules = try getDaySchedules()
        let calendar = Calendar.current

        // Get all dates between last verification and today
        var checkDate = calendar.date(byAdding: .day, value: 1, to: lastVerification)!
        let today = calendar.startOfDay(for: .now)

        while calendar.startOfDay(for: checkDate) < today {
            let weekday = calendar.component(.weekday, from: checkDate)
            // Convert from Calendar weekday (1=Sun) to our format (1=Mon)
            let dayOfWeek = weekday == 1 ? 7 : weekday - 1

            // Check if this was an alarm day
            let isAlarmDay = schedules.first { $0.dayOfWeek == dayOfWeek }?.isAlarmEnabled ?? false

            if !isAlarmDay {
                // Rest day occurred - reset streak
                streakData.resetStreak()
                try modelContext.save()
                return
            }

            checkDate = calendar.date(byAdding: .day, value: 1, to: checkDate)!
        }

        // Also check if TODAY is a rest day and it's past the alarm time
        let todayWeekday = calendar.component(.weekday, from: today)
        let todayDayOfWeek = todayWeekday == 1 ? 7 : todayWeekday - 1
        let todaySchedule = schedules.first { $0.dayOfWeek == todayDayOfWeek }

        if todaySchedule?.isAlarmEnabled == false {
            // Today is a rest day - reset streak
            streakData.resetStreak()
            try modelContext.save()
        }
    }

    /// Check the current streak status without modification
    func getCurrentStreak() throws -> Int {
        let streakData = try getStreakData()
        try checkForMissedDays(streakData: streakData)
        return streakData.currentStreak
    }

    /// Get longest streak ever
    func getLongestStreak() throws -> Int {
        let streakData = try getStreakData()
        return streakData.longestStreak
    }

    /// Check if user has verified today
    func hasVerifiedToday() throws -> Bool {
        let streakData = try getStreakData()
        return streakData.hasVerifiedToday
    }

    // MARK: - Day Schedule Access

    private func getDaySchedules() throws -> [DaySchedule] {
        let descriptor = FetchDescriptor<DaySchedule>(
            sortBy: [SortDescriptor(\.dayOfWeek)]
        )
        return try modelContext.fetch(descriptor)
    }

    /// Get the number of enabled alarm days this week
    func getEnabledAlarmDaysCount() throws -> Int {
        let schedules = try getDaySchedules()
        return schedules.filter { $0.isAlarmEnabled }.count
    }

    /// Check if a specific day is an alarm day
    func isAlarmDay(_ dayOfWeek: Int) throws -> Bool {
        let schedules = try getDaySchedules()
        return schedules.first { $0.dayOfWeek == dayOfWeek }?.isAlarmEnabled ?? false
    }

    /// Check if today is an alarm day
    func isTodayAlarmDay() throws -> Bool {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: .now)
        // Convert from Calendar weekday (1=Sun) to our format (1=Mon)
        let dayOfWeek = weekday == 1 ? 7 : weekday - 1
        return try isAlarmDay(dayOfWeek)
    }

    // MARK: - Verification History

    /// Get verification history for the current week
    func getWeekVerifications() throws -> [Verification] {
        let calendar = Calendar.current

        // Get start of current week (Monday)
        var components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: .now)
        components.weekday = 2 // Monday
        let startOfWeek = calendar.date(from: components)!

        let descriptor = FetchDescriptor<Verification>(
            predicate: #Predicate { $0.date >= startOfWeek },
            sortBy: [SortDescriptor(\.date)]
        )

        return try modelContext.fetch(descriptor)
    }

    /// Get total verification count
    func getTotalVerifications() throws -> Int {
        let streakData = try getStreakData()
        return streakData.totalVerifications
    }
}
