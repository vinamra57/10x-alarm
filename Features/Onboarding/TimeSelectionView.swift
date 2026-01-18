import SwiftUI

/// Screen for selecting alarm times for each day
struct TimeSelectionView: View {
    let selectedDays: Set<Int>
    @Binding var alarmTimes: [Int: Date]
    let onContinue: () -> Void
    let theme: AppTheme

    @State private var useSameTime = true
    @State private var globalTime = defaultAlarmTime

    private static var defaultAlarmTime: Date {
        var components = DateComponents()
        components.hour = 8
        components.minute = 0
        return Calendar.current.date(from: components) ?? Date()
    }

    private var sortedDays: [Int] {
        selectedDays.sorted()
    }

    private let dayNames = [
        1: "Monday",
        2: "Tuesday",
        3: "Wednesday",
        4: "Thursday",
        5: "Friday",
        6: "Saturday",
        7: "Sunday"
    ]

    var body: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 12) {
                Text("Set Alarm Times")
                    .font(.largeTitle.bold())
                    .foregroundStyle(OnboardingColors.primaryText(for: theme))

                Text("When should your alarm wake you?")
                    .font(.body)
                    .foregroundStyle(OnboardingColors.secondaryText(for: theme))
            }
            .padding(.top)

            // Same time toggle
            Toggle("Same time every day", isOn: $useSameTime)
                .foregroundStyle(OnboardingColors.primaryText(for: theme))
                .tint(Color.accentColor)
                .padding(.horizontal, 24)
                .onChange(of: useSameTime) { _, newValue in
                    if newValue {
                        // Apply global time to all days
                        for day in sortedDays {
                            alarmTimes[day] = globalTime
                        }
                    }
                }

            if useSameTime {
                // Single time picker
                VStack(spacing: 8) {
                    DatePicker(
                        "Alarm time",
                        selection: $globalTime,
                        displayedComponents: .hourAndMinute
                    )
                    .datePickerStyle(.wheel)
                    .labelsHidden()
                    .onChange(of: globalTime) { _, newTime in
                        let clampedTime = clampTime(newTime)
                        globalTime = clampedTime
                        for day in sortedDays {
                            alarmTimes[day] = clampedTime
                        }
                    }

                    Text("Maximum 10:00 AM")
                        .font(.caption)
                        .foregroundStyle(OnboardingColors.secondaryText(for: theme))
                }
                .padding()
                .background(OnboardingColors.cardBackground(for: theme))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal, 24)
            } else {
                // Individual time pickers
                ScrollView {
                    VStack(spacing: 16) {
                        ForEach(sortedDays, id: \.self) { day in
                            DayTimePicker(
                                dayName: dayNames[day] ?? "",
                                time: Binding(
                                    get: { alarmTimes[day] ?? Self.defaultAlarmTime },
                                    set: { alarmTimes[day] = $0 }
                                ),
                                theme: theme,
                                clampTime: clampTime
                            )
                        }
                    }
                    .padding(.horizontal, 24)
                }

                Text("Maximum 10:00 AM for all alarms")
                    .font(.caption)
                    .foregroundStyle(OnboardingColors.secondaryText(for: theme))
            }

            Spacer()

            // Continue button
            Button(action: {
                // Ensure all times are set
                for day in sortedDays {
                    if alarmTimes[day] == nil {
                        alarmTimes[day] = globalTime
                    }
                }
                onContinue()
            }) {
                Text("Continue")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
        .onAppear {
            // Initialize times
            for day in sortedDays {
                alarmTimes[day] = globalTime
            }
        }
    }

    private func clampTime(_ date: Date) -> Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: date)

        guard let hour = components.hour else { return date }

        // Clamp to 10:00 AM max
        if hour > 10 || (hour == 10 && (components.minute ?? 0) > 0) {
            var newComponents = DateComponents()
            newComponents.hour = 10
            newComponents.minute = 0
            return calendar.date(from: newComponents) ?? date
        }

        return date
    }
}

// MARK: - Day Time Picker

struct DayTimePicker: View {
    let dayName: String
    @Binding var time: Date
    let theme: AppTheme
    let clampTime: (Date) -> Date

    @State private var localTime: Date = Date()

    var body: some View {
        HStack {
            Text(dayName)
                .font(.headline)
                .foregroundStyle(OnboardingColors.primaryText(for: theme))

            Spacer()

            DatePicker(
                "",
                selection: $localTime,
                displayedComponents: .hourAndMinute
            )
            .labelsHidden()
            .onChange(of: localTime) { _, newTime in
                let clamped = clampTime(newTime)
                if clamped != newTime {
                    localTime = clamped
                }
                time = clamped
            }
        }
        .padding()
        .background(OnboardingColors.cardBackground(for: theme))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .onAppear {
            localTime = time
        }
    }
}

#Preview {
    ZStack {
        OnboardingColors.background(for: .dark)
            .ignoresSafeArea()
        TimeSelectionView(
            selectedDays: [1, 2, 3, 4, 5],
            alarmTimes: .constant([:]),
            onContinue: {},
            theme: .dark
        )
    }
}
