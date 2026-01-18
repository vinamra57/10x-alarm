import SwiftUI
import SwiftData

/// Container view managing the onboarding flow
struct OnboardingContainerView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var currentStep: OnboardingStep = .welcome
    @State private var weeklyMinimum: Int = 4
    @State private var selectedDays: Set<Int> = []
    @State private var alarmTimes: [Int: Date] = [:]
    @State private var selectedTheme: AppTheme = .system

    // Permission states - stored here so they persist across tab swipes
    @State private var cameraGranted = false
    @State private var alarmGranted = false
    @State private var hasCheckedPermissions = false

    enum OnboardingStep: Int, CaseIterable {
        case welcome
        case commitment
        case daySelection
        case timeSelection
        case permissions
    }

    var body: some View {
        ZStack {
            backgroundColor
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Progress indicator
                ProgressIndicator(
                    currentStep: currentStep.rawValue,
                    totalSteps: OnboardingStep.allCases.count,
                    theme: selectedTheme
                )
                .padding(.top)

                // Content
                TabView(selection: $currentStep) {
                    WelcomeView(onContinue: { currentStep = .commitment }, theme: selectedTheme)
                        .tag(OnboardingStep.welcome)

                    CommitmentPickerView(
                        weeklyMinimum: $weeklyMinimum,
                        onContinue: { currentStep = .daySelection },
                        theme: selectedTheme
                    )
                    .tag(OnboardingStep.commitment)

                    DaySelectionView(
                        weeklyMinimum: weeklyMinimum,
                        selectedDays: $selectedDays,
                        onContinue: { currentStep = .timeSelection },
                        theme: selectedTheme
                    )
                    .tag(OnboardingStep.daySelection)

                    TimeSelectionView(
                        selectedDays: selectedDays,
                        alarmTimes: $alarmTimes,
                        onContinue: { currentStep = .permissions },
                        theme: selectedTheme
                    )
                    .tag(OnboardingStep.timeSelection)

                    PermissionsView(
                        selectedTheme: $selectedTheme,
                        cameraGranted: $cameraGranted,
                        alarmGranted: $alarmGranted,
                        hasCheckedPermissions: $hasCheckedPermissions,
                        onComplete: completeOnboarding
                    )
                    .tag(OnboardingStep.permissions)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut, value: currentStep)
            }
        }
        .preferredColorScheme(selectedTheme.colorScheme)
    }

    private var backgroundColor: Color {
        OnboardingColors.background(for: selectedTheme)
    }

    private static var defaultAlarmTime: Date {
        var components = DateComponents()
        components.hour = 8
        components.minute = 0
        return Calendar.current.date(from: components) ?? Date()
    }

    private func completeOnboarding() {
        // Default time is 8:00 AM
        let fallbackTime = Self.defaultAlarmTime

        // Find the earliest alarm time from user's selections, or use default
        let earliestTime: Date = alarmTimes.values.min(by: { a, b in
            let calA = Calendar.current.dateComponents([.hour, .minute], from: a)
            let calB = Calendar.current.dateComponents([.hour, .minute], from: b)
            let minutesA = (calA.hour ?? 0) * 60 + (calA.minute ?? 0)
            let minutesB = (calB.hour ?? 0) * 60 + (calB.minute ?? 0)
            return minutesA < minutesB
        }) ?? fallbackTime

        // Auto-add days if user hasn't selected enough to meet minimum
        var finalSelectedDays = selectedDays
        if finalSelectedDays.count < weeklyMinimum {
            // Add first unchecked days of the week until we meet minimum
            for day in 1...7 {
                if finalSelectedDays.count >= weeklyMinimum { break }
                if !finalSelectedDays.contains(day) {
                    finalSelectedDays.insert(day)
                }
            }
        }

        // Ensure all selected days have alarm times
        for day in finalSelectedDays {
            if alarmTimes[day] == nil {
                alarmTimes[day] = earliestTime
            }
        }

        // Save settings
        let settings = UserSettings(
            weeklyMinimum: weeklyMinimum,
            onboardingCompleted: true,
            appTheme: selectedTheme
        )
        modelContext.insert(settings)

        // Save day schedules
        for day in 1...7 {
            let descriptor = FetchDescriptor<DaySchedule>(
                predicate: #Predicate { $0.dayOfWeek == day }
            )

            if let schedule = try? modelContext.fetch(descriptor).first {
                schedule.isAlarmEnabled = finalSelectedDays.contains(day)
                schedule.alarmTime = alarmTimes[day]
            }
        }

        try? modelContext.save()
    }
}

// MARK: - Progress Indicator

struct ProgressIndicator: View {
    let currentStep: Int
    let totalSteps: Int
    let theme: AppTheme

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<totalSteps, id: \.self) { index in
                Capsule()
                    .fill(index <= currentStep ? Color.accentColor : OnboardingColors.progressInactive(for: theme))
                    .frame(height: 4)
            }
        }
        .padding(.horizontal, 24)
    }
}

// MARK: - Onboarding Colors

struct OnboardingColors {
    static func background(for theme: AppTheme) -> Color {
        switch theme {
        case .dark:
            return Color(red: 0.07, green: 0.07, blue: 0.09)
        case .light, .system:
            return Color(UIColor.systemBackground)
        }
    }

    static func cardBackground(for theme: AppTheme) -> Color {
        switch theme {
        case .dark:
            return Color(red: 0.12, green: 0.12, blue: 0.14)
        case .light, .system:
            return Color(UIColor.secondarySystemBackground)
        }
    }

    static func progressInactive(for theme: AppTheme) -> Color {
        switch theme {
        case .dark:
            return Color(white: 0.25)
        case .light, .system:
            return Color(UIColor.systemGray4)
        }
    }

    static func secondaryText(for theme: AppTheme) -> Color {
        switch theme {
        case .dark:
            return Color(white: 0.6)
        case .light, .system:
            return Color(UIColor.secondaryLabel)
        }
    }

    static func primaryText(for theme: AppTheme) -> Color {
        switch theme {
        case .dark:
            return Color.white
        case .light, .system:
            return Color(UIColor.label)
        }
    }
}

#Preview {
    OnboardingContainerView()
        .modelContainer(for: [UserSettings.self, DaySchedule.self], inMemory: true)
}
