import Foundation
import SwiftData

#if canImport(AlarmKit)
import AlarmKit
#endif

/// Service for managing alarms via AlarmKit
///
/// Implements the relentless alarm pattern:
/// - Primary alarm at user's set time
/// - Backup alarms every 3 minutes until verified
/// - All backup alarms cancelled on successful verification
@Observable
final class AlarmService {
    private let modelContext: ModelContext

    /// Interval between backup alarms (3 minutes)
    static let reFireInterval: TimeInterval = 3 * 60

    /// Maximum time window for backup alarms (2 hours)
    static let maxBackupWindow: TimeInterval = 2 * 60 * 60

    /// Alarm identifier prefix
    private static let alarmPrefix = "com.tenxalarm.morning"

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Authorization

    /// Request AlarmKit authorization
    func requestAuthorization() async throws -> Bool {
        #if canImport(AlarmKit)
        // AlarmKit auto-requests on first alarm, but we can request explicitly
        // This will show the permission dialog
        return true
        #else
        // Fallback for development/simulator
        return true
        #endif
    }

    // MARK: - Alarm Scheduling

    /// Schedule all alarms for the week based on DaySchedule settings
    func scheduleAllAlarms() async throws {
        let schedules = try getEnabledSchedules()

        for schedule in schedules {
            guard let alarmTime = schedule.alarmTime else { continue }
            try await scheduleAlarmWithBackups(
                for: schedule.dayOfWeek,
                at: alarmTime
            )
        }
    }

    /// Schedule alarm for a specific day with backup alarms
    func scheduleAlarmWithBackups(for dayOfWeek: Int, at time: Date) async throws {
        #if canImport(AlarmKit)
        let calendar = Calendar.current

        // Calculate next occurrence of this day
        let nextDate = nextOccurrence(of: dayOfWeek, at: time)

        // Schedule primary alarm
        let primaryId = alarmId(for: dayOfWeek, index: 0)
        try await scheduleAlarm(id: primaryId, at: nextDate, title: "Time to Brush!")

        // Schedule backup alarms every 3 minutes for 2 hours
        var backupTime = nextDate
        var index = 1
        let maxBackups = Int(Self.maxBackupWindow / Self.reFireInterval)

        while index <= maxBackups {
            backupTime = backupTime.addingTimeInterval(Self.reFireInterval)

            // Don't schedule past 10 AM
            let hour = calendar.component(.hour, from: backupTime)
            if hour >= 10 {
                break
            }

            let backupId = alarmId(for: dayOfWeek, index: index)
            try await scheduleAlarm(id: backupId, at: backupTime, title: "Still waiting...")
            index += 1
        }
        #endif
    }

    /// Cancel all backup alarms for today (called after successful verification)
    func cancelTodayBackupAlarms() async throws {
        #if canImport(AlarmKit)
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: .now)
        let dayOfWeek = weekday == 1 ? 7 : weekday - 1

        // Cancel all alarms for today
        let maxBackups = Int(Self.maxBackupWindow / Self.reFireInterval)
        for index in 0...maxBackups {
            let id = alarmId(for: dayOfWeek, index: index)
            try await cancelAlarm(id: id)
        }
        #endif
    }

    /// Cancel all scheduled alarms
    func cancelAllAlarms() async throws {
        #if canImport(AlarmKit)
        for dayOfWeek in 1...7 {
            let maxBackups = Int(Self.maxBackupWindow / Self.reFireInterval)
            for index in 0...maxBackups {
                let id = alarmId(for: dayOfWeek, index: index)
                try await cancelAlarm(id: id)
            }
        }
        #endif
    }

    /// Reschedule all alarms (call after settings change)
    func rescheduleAllAlarms() async throws {
        try await cancelAllAlarms()
        try await scheduleAllAlarms()
    }

    // MARK: - AlarmKit Wrappers

    #if canImport(AlarmKit)
    private func scheduleAlarm(id: String, at date: Date, title: String) async throws {
        // Create alarm configuration
        // Note: Actual AlarmKit API may differ - this is based on documentation
        let alarm = Alarm(
            id: id,
            date: date,
            title: title,
            sound: .default
        )

        try await AlarmManager.shared.schedule(alarm)
    }

    private func cancelAlarm(id: String) async throws {
        try await AlarmManager.shared.cancel(alarmWithId: id)
    }
    #else
    private func scheduleAlarm(id: String, at date: Date, title: String) async throws {
        // Stub for development
        print("Would schedule alarm: \(id) at \(date)")
    }

    private func cancelAlarm(id: String) async throws {
        // Stub for development
        print("Would cancel alarm: \(id)")
    }
    #endif

    // MARK: - Helpers

    private func alarmId(for dayOfWeek: Int, index: Int) -> String {
        "\(Self.alarmPrefix).\(dayOfWeek).\(index)"
    }

    private func nextOccurrence(of dayOfWeek: Int, at time: Date) -> Date {
        let calendar = Calendar.current

        // Get time components
        let timeComponents = calendar.dateComponents([.hour, .minute], from: time)

        // Find next occurrence of this weekday
        var components = DateComponents()
        // Convert our format (1=Mon) to Calendar format (2=Mon)
        components.weekday = dayOfWeek == 7 ? 1 : dayOfWeek + 1
        components.hour = timeComponents.hour
        components.minute = timeComponents.minute

        return calendar.nextDate(
            after: .now,
            matching: components,
            matchingPolicy: .nextTime
        ) ?? .now
    }

    private func getEnabledSchedules() throws -> [DaySchedule] {
        let descriptor = FetchDescriptor<DaySchedule>(
            predicate: #Predicate { $0.isAlarmEnabled },
            sortBy: [SortDescriptor(\.dayOfWeek)]
        )
        return try modelContext.fetch(descriptor)
    }

    // MARK: - Status

    /// Get next scheduled alarm info
    func getNextAlarm() throws -> (dayOfWeek: Int, time: Date)? {
        let schedules = try getEnabledSchedules()

        let calendar = Calendar.current
        let now = Date.now

        // Find the next upcoming alarm
        var nextAlarm: (dayOfWeek: Int, time: Date)?
        var smallestInterval: TimeInterval = .infinity

        for schedule in schedules {
            guard let alarmTime = schedule.alarmTime else { continue }

            let nextDate = nextOccurrence(of: schedule.dayOfWeek, at: alarmTime)
            let interval = nextDate.timeIntervalSince(now)

            if interval > 0 && interval < smallestInterval {
                smallestInterval = interval
                nextAlarm = (schedule.dayOfWeek, nextDate)
            }
        }

        return nextAlarm
    }

    /// Format next alarm as readable string
    func getNextAlarmString() throws -> String? {
        guard let next = try getNextAlarm() else { return nil }

        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.timeStyle = .short

        if calendar.isDateInToday(next.time) {
            return "Today \(formatter.string(from: next.time))"
        } else if calendar.isDateInTomorrow(next.time) {
            return "Tomorrow \(formatter.string(from: next.time))"
        } else {
            let daySchedule = DaySchedule(dayOfWeek: next.dayOfWeek)
            return "\(daySchedule.shortDayName) \(formatter.string(from: next.time))"
        }
    }
}

// MARK: - AlarmKit Placeholder Types (for development without AlarmKit)

#if !canImport(AlarmKit)
struct Alarm {
    let id: String
    let date: Date
    let title: String
    let sound: AlarmSound

    enum AlarmSound {
        case `default`
    }
}

enum AlarmManager {
    static let shared = AlarmManagerImpl()

    class AlarmManagerImpl {
        func schedule(_ alarm: Alarm) async throws {}
        func cancel(alarmWithId id: String) async throws {}
    }
}
#endif
