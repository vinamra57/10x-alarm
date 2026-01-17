import AppIntents
import SwiftUI

/// App Intent for the "Verify Brush" button on the alarm
///
/// This intent is triggered when the user taps the Verify Brush button
/// on the AlarmKit Lock Screen presentation
struct VerifyBrushIntent: AppIntent {
    static var title: LocalizedStringResource = "Verify Brush"
    static var description = IntentDescription("Open camera to verify you're brushing your teeth")

    /// Opens the app when run
    static var openAppWhenRun: Bool = true

    /// The alarm identifier (passed from AlarmKit)
    @Parameter(title: "Alarm ID")
    var alarmId: String?

    init() {}

    init(alarmId: String) {
        self.alarmId = alarmId
    }

    func perform() async throws -> some IntentResult {
        // Post notification to open verification camera
        await MainActor.run {
            NotificationCenter.default.post(
                name: .openVerificationCamera,
                object: nil,
                userInfo: ["alarmId": alarmId ?? "unknown"]
            )
        }

        return .result()
    }
}

// MARK: - Notification

extension Notification.Name {
    static let openVerificationCamera = Notification.Name("openVerificationCamera")
}

// MARK: - App Shortcuts

struct TenXAlarmShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: VerifyBrushIntent(),
            phrases: [
                "Verify brush with \(.applicationName)",
                "Start brushing verification in \(.applicationName)"
            ],
            shortTitle: "Verify Brush",
            systemImageName: "camera.fill"
        )
    }
}
