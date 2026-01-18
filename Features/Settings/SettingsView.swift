import SwiftUI
import SwiftData

/// Settings screen for managing alarms and preferences
struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var settings: [UserSettings]
    @Query(sort: \DaySchedule.dayOfWeek) private var daySchedules: [DaySchedule]
    @Query private var streakData: [StreakData]

    @Binding var currentTheme: AppTheme
    @State private var showingResetConfirmation = false

    private var themeManager = ThemeManager.shared

    init(currentTheme: Binding<AppTheme>) {
        self._currentTheme = currentTheme
    }

    private var userSettings: UserSettings? {
        settings.first
    }

    var body: some View {
        NavigationStack {
            List {
                // Alarm settings
                Section {
                    NavigationLink {
                        AlarmScheduleSettingsView()
                    } label: {
                        HStack {
                            Label("Alarm Schedule", systemImage: "alarm")

                            Spacer()

                            Text("\(enabledDaysCount) days")
                                .foregroundStyle(.secondary)
                        }
                    }

                    NavigationLink {
                        WeeklyMinimumSettingsView()
                    } label: {
                        HStack {
                            Label("Weekly Minimum", systemImage: "calendar")

                            Spacer()

                            Text("\(userSettings?.weeklyMinimum ?? 4) days")
                                .foregroundStyle(.secondary)
                        }
                    }
                } header: {
                    Text("Alarms")
                } footer: {
                    if let minimum = userSettings?.weeklyMinimum, minimum < 7 {
                        Text("You can set alarms on more than \(minimum) days to keep your streak going longer.")
                    }
                }

                // Stats
                Section("Stats") {
                    HStack {
                        Label("Current Streak", systemImage: "flame")

                        Spacer()

                        Text("\(streakData.first?.currentStreak ?? 0) days")
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Label("Best Streak", systemImage: "trophy")

                        Spacer()

                        Text("\(streakData.first?.longestStreak ?? 0) days")
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Label("Total Brushes", systemImage: "checkmark.circle")

                        Spacer()

                        Text("\(streakData.first?.totalVerifications ?? 0)")
                            .foregroundStyle(.secondary)
                    }
                }

                // Appearance
                Section("Appearance") {
                    Picker("Theme", selection: $currentTheme) {
                        ForEach(AppTheme.allCases, id: \.self) { theme in
                            Text(theme.displayName).tag(theme)
                        }
                    }
                    .onChange(of: currentTheme) { _, newTheme in
                        userSettings?.updateTheme(newTheme)
                        try? modelContext.save()
                        themeManager.currentTheme = newTheme
                    }
                }

                // About
                Section("About") {
                    HStack {
                        Label("Version", systemImage: "info.circle")

                        Spacer()

                        Text("1.0.0")
                            .foregroundStyle(.secondary)
                    }

                    Link(destination: URL(string: "https://10xalarm.app/privacy")!) {
                        Label("Privacy Policy", systemImage: "hand.raised")
                    }

                    Link(destination: URL(string: "https://10xalarm.app/support")!) {
                        Label("Get Help", systemImage: "questionmark.circle")
                    }
                }

                // Danger zone
                Section {
                    Button(role: .destructive) {
                        showingResetConfirmation = true
                    } label: {
                        Label("Reset Streak", systemImage: "arrow.counterclockwise")
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .alert("Reset Streak?", isPresented: $showingResetConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Reset", role: .destructive) {
                    resetStreak()
                }
            } message: {
                Text("This will reset your current streak to 0. This cannot be undone.")
            }
        }
    }

    private var enabledDaysCount: Int {
        daySchedules.filter { $0.isAlarmEnabled }.count
    }

    private func resetStreak() {
        if let streak = streakData.first {
            streak.resetStreak()
            try? modelContext.save()
        }
    }
}

// MARK: - Alarm Schedule Settings

struct AlarmScheduleSettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \DaySchedule.dayOfWeek) private var daySchedules: [DaySchedule]
    @Query private var settings: [UserSettings]

    private var weeklyMinimum: Int {
        settings.first?.weeklyMinimum ?? 4
    }

    private var enabledCount: Int {
        daySchedules.filter { $0.isAlarmEnabled }.count
    }

    var body: some View {
        List {
            Section {
                ForEach(daySchedules) { schedule in
                    AlarmDayRow(
                        schedule: schedule,
                        canDisable: enabledCount > weeklyMinimum
                    )
                }
            } footer: {
                Text("You must have at least \(weeklyMinimum) alarm days to meet your weekly minimum.")
            }
        }
        .navigationTitle("Alarm Schedule")
    }
}

struct AlarmDayRow: View {
    @Bindable var schedule: DaySchedule
    let canDisable: Bool

    @State private var showingTimePicker = false

    var body: some View {
        HStack {
            Toggle(isOn: Binding(
                get: { schedule.isAlarmEnabled },
                set: { newValue in
                    // Always allow enabling, only allow disabling if above minimum
                    if newValue || canDisable {
                        schedule.isAlarmEnabled = newValue
                    }
                }
            )) {
                Text(schedule.dayName)
            }

            if schedule.isAlarmEnabled {
                Spacer()

                Button {
                    showingTimePicker = true
                } label: {
                    Text(schedule.formattedTime ?? "7:00 AM")
                        .foregroundStyle(Color.accentColor)
                }
            }
        }
        .sheet(isPresented: $showingTimePicker) {
            TimePickerSheet(schedule: schedule)
        }
    }
}

struct TimePickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Query private var settings: [UserSettings]
    @Bindable var schedule: DaySchedule

    @State private var selectedTime: Date

    init(schedule: DaySchedule) {
        self.schedule = schedule
        _selectedTime = State(initialValue: schedule.alarmTime ?? Self.defaultTime)
    }

    private static var defaultTime: Date {
        var components = DateComponents()
        components.hour = 7
        components.minute = 0
        return Calendar.current.date(from: components) ?? Date()
    }

    var body: some View {
        NavigationStack {
            VStack {
                DatePicker(
                    "Alarm Time",
                    selection: $selectedTime,
                    displayedComponents: .hourAndMinute
                )
                .datePickerStyle(.wheel)
                .labelsHidden()

                Text("Maximum 10:00 AM")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .navigationTitle(schedule.dayName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        schedule.setAlarmTime(selectedTime)
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium])
        .preferredColorScheme(settings.first?.appTheme.colorScheme)
    }
}

// MARK: - Weekly Minimum Settings

struct WeeklyMinimumSettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var settings: [UserSettings]
    @Query(sort: \DaySchedule.dayOfWeek) private var daySchedules: [DaySchedule]

    @State private var newMinimum: Int = 4

    private var currentMinimum: Int {
        settings.first?.weeklyMinimum ?? 4
    }

    private var enabledDaysCount: Int {
        daySchedules.filter { $0.isAlarmEnabled }.count
    }

    private var canDecrease: Bool {
        newMinimum > 4
    }

    private var canIncrease: Bool {
        newMinimum < 7 && newMinimum < enabledDaysCount
    }

    var body: some View {
        List {
            Section {
                VStack(spacing: 24) {
                    Text("\(newMinimum)")
                        .font(.system(size: 72, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.accentColor)

                    Text("days per week")
                        .font(.title3)
                        .foregroundStyle(.secondary)

                    HStack(spacing: 32) {
                        Button {
                            if canDecrease {
                                newMinimum -= 1
                            }
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .font(.system(size: 44))
                                .foregroundStyle(canDecrease ? Color.accentColor : Color.gray)
                        }
                        .disabled(!canDecrease)

                        Button {
                            if canIncrease {
                                newMinimum += 1
                            }
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 44))
                                .foregroundStyle(canIncrease ? Color.accentColor : Color.gray)
                        }
                        .disabled(!canIncrease)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
            } footer: {
                if newMinimum == 7 {
                    Text("7 days enables infinite streak potential!")
                } else {
                    Text("Set alarms on more than \(newMinimum) days to keep your streak going longer.")
                }
            }

            if newMinimum != currentMinimum {
                Section {
                    Button("Save Changes") {
                        saveChanges()
                    }
                }
            }
        }
        .navigationTitle("Weekly Minimum")
        .onAppear {
            newMinimum = currentMinimum
        }
    }

    private func saveChanges() {
        if let userSettings = settings.first {
            userSettings.updateWeeklyMinimum(newMinimum)
            try? modelContext.save()
        }
    }
}

#Preview {
    SettingsView(currentTheme: .constant(.system))
        .modelContainer(for: [UserSettings.self, DaySchedule.self, StreakData.self], inMemory: true)
}
