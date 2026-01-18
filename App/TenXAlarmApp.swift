import SwiftUI
import SwiftData

@main
struct TenXAlarmApp: App {
    let modelContainer: ModelContainer

    init() {
        do {
            let schema = Schema([
                UserSettings.self,
                DaySchedule.self,
                Verification.self,
                StreakData.self
            ])

            let modelConfiguration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false
            )

            modelContainer = try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )

            // Initialize day schedules if needed
            let container = modelContainer
            Task { @MainActor in
                Self.initializeDaySchedules(in: container)
            }
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(modelContainer)
    }

    @MainActor
    private static func initializeDaySchedules(in container: ModelContainer) {
        let context = container.mainContext
        let descriptor = FetchDescriptor<DaySchedule>()

        do {
            let existing = try context.fetch(descriptor)

            // Create day schedules for all 7 days if not present
            if existing.isEmpty {
                for day in 1...7 {
                    let schedule = DaySchedule(dayOfWeek: day)
                    context.insert(schedule)
                }
                try context.save()
            }
        } catch {
            print("Failed to initialize day schedules: \(error)")
        }
    }
}

// MARK: - Root View

struct RootView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var settings: [UserSettings]
    private var themeManager = ThemeManager.shared

    private var hasCompletedOnboarding: Bool {
        settings.first?.onboardingCompleted ?? false
    }

    var body: some View {
        Group {
            if hasCompletedOnboarding {
                DashboardView()
            } else {
                OnboardingContainerView()
            }
        }
        .preferredColorScheme(themeManager.currentTheme.colorScheme)
        .onAppear {
            // Sync ThemeManager with saved theme on launch
            themeManager.currentTheme = settings.first?.appTheme ?? .system
        }
    }
}

// MARK: - Environment Keys

private struct AlarmServiceKey: EnvironmentKey {
    static let defaultValue: AlarmService? = nil
}

private struct StreakServiceKey: EnvironmentKey {
    static let defaultValue: StreakService? = nil
}

private struct VerificationServiceKey: EnvironmentKey {
    static let defaultValue: VerificationService? = nil
}

extension EnvironmentValues {
    var alarmService: AlarmService? {
        get { self[AlarmServiceKey.self] }
        set { self[AlarmServiceKey.self] = newValue }
    }

    var streakService: StreakService? {
        get { self[StreakServiceKey.self] }
        set { self[StreakServiceKey.self] = newValue }
    }

    var verificationService: VerificationService? {
        get { self[VerificationServiceKey.self] }
        set { self[VerificationServiceKey.self] = newValue }
    }
}
