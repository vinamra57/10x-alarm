import WidgetKit
import SwiftUI
import SwiftData

// MARK: - Widget Entry

struct StreakEntry: TimelineEntry {
    let date: Date
    let currentStreak: Int
    let longestStreak: Int
    let hasVerifiedToday: Bool
    let nextAlarmString: String?
    let weekProgress: [Bool] // 7 days, true = verified
}

// MARK: - Timeline Provider

struct StreakTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> StreakEntry {
        StreakEntry(
            date: .now,
            currentStreak: 12,
            longestStreak: 30,
            hasVerifiedToday: true,
            nextAlarmString: "Tomorrow 7:00 AM",
            weekProgress: [true, true, true, false, false, false, false]
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (StreakEntry) -> Void) {
        let entry = placeholder(in: context)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<StreakEntry>) -> Void) {
        // Fetch data from shared container
        let entry = fetchCurrentData()

        // Update every hour or when app requests
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: .now)!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))

        completion(timeline)
    }

    private func fetchCurrentData() -> StreakEntry {
        // In production, this would read from the shared App Group container
        // For now, return placeholder data
        return StreakEntry(
            date: .now,
            currentStreak: 0,
            longestStreak: 0,
            hasVerifiedToday: false,
            nextAlarmString: nil,
            weekProgress: Array(repeating: false, count: 7)
        )
    }
}

// MARK: - Small Widget View

struct SmallStreakWidgetView: View {
    let entry: StreakEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Streak
            HStack(spacing: 4) {
                Image(systemName: entry.currentStreak > 0 ? "flame.fill" : "flame")
                    .foregroundStyle(entry.currentStreak > 0 ? .orange : .gray)

                Text("\(entry.currentStreak)")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
            }

            Text(entry.currentStreak == 1 ? "day streak" : "day streak")
                .font(.caption)
                .foregroundStyle(.secondary)

            Spacer()

            // Next alarm
            if let nextAlarm = entry.nextAlarmString {
                HStack(spacing: 4) {
                    Image(systemName: "alarm")
                        .font(.caption2)
                        .foregroundStyle(.secondary)

                    Text(nextAlarm)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
    }
}

// MARK: - Medium Widget View

struct MediumStreakWidgetView: View {
    let entry: StreakEntry

    private let days = ["M", "T", "W", "T", "F", "S", "S"]

    var body: some View {
        HStack(spacing: 16) {
            // Left side - Streak
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Image(systemName: entry.currentStreak > 0 ? "flame.fill" : "flame")
                        .font(.title2)
                        .foregroundStyle(entry.currentStreak > 0 ? .orange : .gray)

                    Text("\(entry.currentStreak)")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                }

                Text("day streak")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                if let nextAlarm = entry.nextAlarmString {
                    Label(nextAlarm, systemImage: "alarm")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            Divider()

            // Right side - Week progress
            VStack(alignment: .leading, spacing: 8) {
                Text("This Week")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                HStack(spacing: 4) {
                    ForEach(0..<7, id: \.self) { index in
                        VStack(spacing: 4) {
                            Text(days[index])
                                .font(.system(size: 10))
                                .foregroundStyle(.secondary)

                            Circle()
                                .fill(entry.weekProgress[index] ? Color.green : Color(.systemGray5))
                                .frame(width: 20, height: 20)
                                .overlay {
                                    if entry.weekProgress[index] {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundStyle(.white)
                                    }
                                }
                        }
                    }
                }

                Spacer()
            }
        }
        .padding()
    }
}

// MARK: - Widget Configuration

struct StreakWidget: Widget {
    let kind: String = "StreakWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: StreakTimelineProvider()) { entry in
            StreakWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Streak")
        .description("Track your brushing streak")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct StreakWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    let entry: StreakEntry

    var body: some View {
        switch family {
        case .systemSmall:
            SmallStreakWidgetView(entry: entry)
        case .systemMedium:
            MediumStreakWidgetView(entry: entry)
        default:
            SmallStreakWidgetView(entry: entry)
        }
    }
}

// MARK: - Widget Bundle

@main
struct TenXAlarmWidgetBundle: WidgetBundle {
    var body: some Widget {
        StreakWidget()
    }
}

// MARK: - Previews

#Preview("Small", as: .systemSmall) {
    StreakWidget()
} timeline: {
    StreakEntry(
        date: .now,
        currentStreak: 12,
        longestStreak: 30,
        hasVerifiedToday: true,
        nextAlarmString: "Tomorrow 7:00 AM",
        weekProgress: [true, true, true, false, false, false, false]
    )
}

#Preview("Medium", as: .systemMedium) {
    StreakWidget()
} timeline: {
    StreakEntry(
        date: .now,
        currentStreak: 12,
        longestStreak: 30,
        hasVerifiedToday: true,
        nextAlarmString: "Tomorrow 7:00 AM",
        weekProgress: [true, true, true, false, false, false, false]
    )
}
