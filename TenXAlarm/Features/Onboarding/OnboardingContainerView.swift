import SwiftUI
import SwiftData

/// Container view managing the onboarding flow
struct OnboardingContainerView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var currentStep: OnboardingStep = .welcome
    @State private var weeklyMinimum: Int = 4
    @State private var selectedDays: Set<Int> = []
    @State private var alarmTimes: [Int: Date] = [:]

    enum OnboardingStep: Int, CaseIterable {
        case welcome
        case commitment
        case daySelection
        case timeSelection
        case permissions
    }

    var body: some View {
        VStack(spacing: 0) {
            // Progress indicator
            ProgressIndicator(
                currentStep: currentStep.rawValue,
                totalSteps: OnboardingStep.allCases.count
            )
            .padding(.top)

            // Content
            TabView(selection: $currentStep) {
                WelcomeView(onContinue: { currentStep = .commitment })
                    .tag(OnboardingStep.welcome)

                CommitmentPickerView(
                    weeklyMinimum: $weeklyMinimum,
                    onContinue: { currentStep = .daySelection }
                )
                .tag(OnboardingStep.commitment)

                DaySelectionView(
                    weeklyMinimum: weeklyMinimum,
                    selectedDays: $selectedDays,
                    onContinue: { currentStep = .timeSelection }
                )
                .tag(OnboardingStep.daySelection)

                TimeSelectionView(
                    selectedDays: selectedDays,
                    alarmTimes: $alarmTimes,
                    onContinue: { currentStep = .permissions }
                )
                .tag(OnboardingStep.timeSelection)

                PermissionsView(
                    onComplete: completeOnboarding
                )
                .tag(OnboardingStep.permissions)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut, value: currentStep)
        }
        .background(Color(.systemBackground))
    }

    private func completeOnboarding() {
        // Save settings
        let settings = UserSettings(
            weeklyMinimum: weeklyMinimum,
            onboardingCompleted: true
        )
        modelContext.insert(settings)

        // Save day schedules
        for day in 1...7 {
            let descriptor = FetchDescriptor<DaySchedule>(
                predicate: #Predicate { $0.dayOfWeek == day }
            )

            if let schedule = try? modelContext.fetch(descriptor).first {
                schedule.isAlarmEnabled = selectedDays.contains(day)
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

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<totalSteps, id: \.self) { index in
                Capsule()
                    .fill(index <= currentStep ? Color.accentColor : Color(.systemGray4))
                    .frame(height: 4)
            }
        }
        .padding(.horizontal, 24)
    }
}

#Preview {
    OnboardingContainerView()
        .modelContainer(for: [UserSettings.self, DaySchedule.self], inMemory: true)
}
