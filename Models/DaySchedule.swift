import Foundation
import SwiftData

@Model
final class DaySchedule {
    /// Day of week (1 = Monday, 7 = Sunday)
    var dayOfWeek: Int

    /// Whether alarm is enabled for this day
    var isAlarmEnabled: Bool

    /// Alarm time (stored as Date but only time component matters)
    /// Max 10:00 AM local time enforced
    var alarmTime: Date?

    init(dayOfWeek: Int, isAlarmEnabled: Bool = false, alarmTime: Date? = nil) {
        self.dayOfWeek = dayOfWeek
        self.isAlarmEnabled = isAlarmEnabled
        self.alarmTime = alarmTime.map { Self.clampToMaxTime($0) }
    }

    /// Maximum allowed alarm time (10:00 AM)
    static let maxAlarmHour = 10
    static let maxAlarmMinute = 0

    /// Clamp time to max 10:00 AM
    static func clampToMaxTime(_ date: Date) -> Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: date)

        guard let hour = components.hour, let minute = components.minute else {
            return date
        }

        // If time is after 10:00 AM, clamp to 10:00 AM
        if hour > maxAlarmHour || (hour == maxAlarmHour && minute > maxAlarmMinute) {
            var newComponents = DateComponents()
            newComponents.hour = maxAlarmHour
            newComponents.minute = maxAlarmMinute
            return calendar.date(from: newComponents) ?? date
        }

        return date
    }

    /// Update alarm time with validation
    func setAlarmTime(_ time: Date) {
        alarmTime = Self.clampToMaxTime(time)
    }

    /// Get day name
    var dayName: String {
        switch dayOfWeek {
        case 1: return "Monday"
        case 2: return "Tuesday"
        case 3: return "Wednesday"
        case 4: return "Thursday"
        case 5: return "Friday"
        case 6: return "Saturday"
        case 7: return "Sunday"
        default: return "Unknown"
        }
    }

    /// Get short day name
    var shortDayName: String {
        switch dayOfWeek {
        case 1: return "Mon"
        case 2: return "Tue"
        case 3: return "Wed"
        case 4: return "Thu"
        case 5: return "Fri"
        case 6: return "Sat"
        case 7: return "Sun"
        default: return "?"
        }
    }

    /// Get single letter day name
    var letterDayName: String {
        switch dayOfWeek {
        case 1: return "M"
        case 2: return "T"
        case 3: return "W"
        case 4: return "T"
        case 5: return "F"
        case 6: return "S"
        case 7: return "S"
        default: return "?"
        }
    }

    /// Formatted alarm time string
    var formattedTime: String? {
        guard let time = alarmTime else { return nil }
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: time)
    }
}
