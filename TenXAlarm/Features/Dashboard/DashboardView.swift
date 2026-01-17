import SwiftUI
import SwiftData

/// Main dashboard view shown after onboarding
struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var streakData: [StreakData]
    @Query(sort: \DaySchedule.dayOfWeek) private var daySchedules: [DaySchedule]
    @Query(sort: \Verification.date, order: .reverse) private var verifications: [Verification]

    @State private var showingSettings = false
    @State private var showingVerification = false

    private var currentStreak: Int {
        streakData.first?.currentStreak ?? 0
    }

    private var longestStreak: Int {
        streakData.first?.longestStreak ?? 0
    }

    private var hasVerifiedToday: Bool {
        streakData.first?.hasVerifiedToday ?? false
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Streak card
                    StreakCard(
                        currentStreak: currentStreak,
                        longestStreak: longestStreak,
                        hasVerifiedToday: hasVerifiedToday
                    )

                    // Week progress
                    WeekProgressCard(
                        daySchedules: daySchedules,
                        verifications: weekVerifications
                    )

                    // Next alarm
                    NextAlarmCard(daySchedules: daySchedules)

                    // Quick verify button (for non-alarm days)
                    if !hasVerifiedToday && !isTodayAlarmDay {
                        BonusBrushCard(onVerify: { showingVerification = true })
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("10x Alarm")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                }
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
            .fullScreenCover(isPresented: $showingVerification) {
                CameraVerificationView(isAlarmTriggered: false)
            }
        }
    }

    private var weekVerifications: [Verification] {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: .now)
        components.weekday = 2 // Monday
        guard let startOfWeek = calendar.date(from: components) else { return [] }

        return verifications.filter { $0.date >= startOfWeek }
    }

    private var isTodayAlarmDay: Bool {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: .now)
        let dayOfWeek = weekday == 1 ? 7 : weekday - 1
        return daySchedules.first { $0.dayOfWeek == dayOfWeek }?.isAlarmEnabled ?? false
    }
}

// MARK: - Streak Card

struct StreakCard: View {
    let currentStreak: Int
    let longestStreak: Int
    let hasVerifiedToday: Bool

    var body: some View {
        VStack(spacing: 16) {
            // Main streak display
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Current Streak")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text("\(currentStreak)")
                            .font(.system(size: 56, weight: .bold, design: .rounded))

                        Text(currentStreak == 1 ? "day" : "days")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                // Flame icon
                Image(systemName: currentStreak > 0 ? "flame.fill" : "flame")
                    .font(.system(size: 48))
                    .foregroundStyle(currentStreak > 0 ? .orange : .gray)
            }

            Divider()

            // Stats row
            HStack {
                StatItem(
                    label: "Best",
                    value: "\(longestStreak)",
                    icon: "trophy.fill"
                )

                Spacer()

                StatItem(
                    label: "Today",
                    value: hasVerifiedToday ? "Done" : "Pending",
                    icon: hasVerifiedToday ? "checkmark.circle.fill" : "circle"
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct StatItem: View {
    let label: String
    let value: String
    let icon: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(.accent)

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(value)
                    .font(.headline)
            }
        }
    }
}

// MARK: - Week Progress Card

struct WeekProgressCard: View {
    let daySchedules: [DaySchedule]
    let verifications: [Verification]

    private let days = ["M", "T", "W", "T", "F", "S", "S"]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("This Week")
                .font(.headline)

            HStack(spacing: 0) {
                ForEach(1...7, id: \.self) { day in
                    let schedule = daySchedules.first { $0.dayOfWeek == day }
                    let isEnabled = schedule?.isAlarmEnabled ?? false
                    let isVerified = hasVerification(for: day)
                    let isToday = isCurrentDay(day)

                    VStack(spacing: 8) {
                        Text(days[day - 1])
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        DayIndicator(
                            isEnabled: isEnabled,
                            isVerified: isVerified,
                            isToday: isToday
                        )
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func hasVerification(for dayOfWeek: Int) -> Bool {
        let calendar = Calendar.current

        // Get the date for this day of the current week
        var components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: .now)
        components.weekday = dayOfWeek == 7 ? 1 : dayOfWeek + 1

        guard let dayDate = calendar.date(from: components) else { return false }

        return verifications.contains { verification in
            calendar.isDate(verification.date, inSameDayAs: dayDate) &&
            verification.result == .pass
        }
    }

    private func isCurrentDay(_ dayOfWeek: Int) -> Bool {
        let calendar = Calendar.current
        let currentWeekday = calendar.component(.weekday, from: .now)
        let currentDayOfWeek = currentWeekday == 1 ? 7 : currentWeekday - 1
        return dayOfWeek == currentDayOfWeek
    }
}

struct DayIndicator: View {
    let isEnabled: Bool
    let isVerified: Bool
    let isToday: Bool

    var body: some View {
        ZStack {
            Circle()
                .fill(backgroundColor)
                .frame(width: 36, height: 36)

            if isVerified {
                Image(systemName: "checkmark")
                    .font(.caption.bold())
                    .foregroundStyle(.white)
            } else if !isEnabled {
                Text("-")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .overlay {
            if isToday {
                Circle()
                    .stroke(Color.accentColor, lineWidth: 2)
                    .frame(width: 40, height: 40)
            }
        }
    }

    private var backgroundColor: Color {
        if isVerified {
            return .green
        } else if isEnabled {
            return Color(.systemGray5)
        } else {
            return Color(.systemGray6)
        }
    }
}

// MARK: - Next Alarm Card

struct NextAlarmCard: View {
    let daySchedules: [DaySchedule]

    var body: some View {
        HStack {
            Image(systemName: "alarm.fill")
                .font(.title2)
                .foregroundStyle(.accent)

            VStack(alignment: .leading, spacing: 4) {
                Text("Next Alarm")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(nextAlarmString)
                    .font(.headline)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var nextAlarmString: String {
        // Find next enabled alarm
        let calendar = Calendar.current
        let now = Date.now
        let currentWeekday = calendar.component(.weekday, from: now)
        let currentDayOfWeek = currentWeekday == 1 ? 7 : currentWeekday - 1

        let formatter = DateFormatter()
        formatter.timeStyle = .short

        // Check today first
        if let todaySchedule = daySchedules.first(where: { $0.dayOfWeek == currentDayOfWeek }),
           todaySchedule.isAlarmEnabled,
           let alarmTime = todaySchedule.alarmTime {
            let todayAlarm = calendar.date(
                bySettingHour: calendar.component(.hour, from: alarmTime),
                minute: calendar.component(.minute, from: alarmTime),
                second: 0,
                of: now
            )!

            if todayAlarm > now {
                return "Today \(formatter.string(from: alarmTime))"
            }
        }

        // Check future days
        for offset in 1...7 {
            let futureDayOfWeek = ((currentDayOfWeek - 1 + offset) % 7) + 1

            if let schedule = daySchedules.first(where: { $0.dayOfWeek == futureDayOfWeek }),
               schedule.isAlarmEnabled,
               let alarmTime = schedule.alarmTime {
                if offset == 1 {
                    return "Tomorrow \(formatter.string(from: alarmTime))"
                } else {
                    return "\(schedule.shortDayName) \(formatter.string(from: alarmTime))"
                }
            }
        }

        return "No alarms set"
    }
}

// MARK: - Bonus Brush Card

struct BonusBrushCard: View {
    let onVerify: () -> Void

    var body: some View {
        Button(action: onVerify) {
            HStack {
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.accent)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Bonus Brush")
                        .font(.headline)

                    Text("Verify now to extend your streak")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundStyle(.secondary)
            }
            .padding()
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    DashboardView()
        .modelContainer(for: [StreakData.self, DaySchedule.self, Verification.self], inMemory: true)
}
