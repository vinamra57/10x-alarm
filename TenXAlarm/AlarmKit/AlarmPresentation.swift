import Foundation
import SwiftUI

#if canImport(AlarmKit)
import AlarmKit
#endif

/// Configuration for how the alarm is presented on Lock Screen
///
/// Uses AlarmKit's presentation API to customize the alarm UI
struct AlarmPresentationConfig {
    /// Alarm title shown on Lock Screen
    let title: String

    /// Whether to show snooze button (we hide it)
    let showSnooze: Bool = false

    /// Custom verify button configuration
    let verifyButton: VerifyButtonConfig

    struct VerifyButtonConfig {
        let title: String = "Verify Brush"
        let icon: String = "camera.fill"
        let foregroundColor: Color = .white
        let backgroundColor: Color = .accentColor
    }
}

// MARK: - AlarmKit Integration

#if canImport(AlarmKit)
extension AlarmPresentationConfig {
    /// Create an AlarmKit alert presentation
    func createAlertPresentation(alarmId: String) -> some AlarmAlertPresentation {
        // Create the verify button with custom intent
        let verifyIntent = VerifyBrushIntent(alarmId: alarmId)

        // Build the presentation
        // Note: Actual API may differ based on AlarmKit documentation
        return AlarmAlertPresentation(
            title: title,
            primaryButton: .custom(
                title: verifyButton.title,
                systemImage: verifyButton.icon,
                intent: verifyIntent
            )
            // No snooze button configured
        )
    }
}

// MARK: - Placeholder Types

/// Placeholder for AlarmKit types during development
struct AlarmAlertPresentation {
    let title: String
    let primaryButton: AlertButton

    enum AlertButton {
        case stop
        case snooze
        case custom(title: String, systemImage: String, intent: any AppIntent)
    }
}
#endif

// MARK: - Alarm Sound Configuration

struct AlarmSoundConfig {
    /// Use default system alarm sound
    static let defaultSound = "default"

    /// List of available custom sounds
    static let availableSounds = [
        "gentle_wake",
        "morning_chime",
        "urgent_alarm"
    ]

    /// Get URL for custom sound file
    static func soundURL(for soundName: String) -> URL? {
        Bundle.main.url(forResource: soundName, withExtension: "caf")
    }
}

// MARK: - Deep Link Handling

/// Handles deep links from the alarm
struct AlarmDeepLinkHandler {
    /// Parse a deep link URL
    static func parse(_ url: URL) -> DeepLinkAction? {
        guard url.scheme == "tenxalarm" else { return nil }

        switch url.host {
        case "verify":
            return .openVerification
        case "settings":
            return .openSettings
        case "dashboard":
            return .openDashboard
        default:
            return nil
        }
    }

    enum DeepLinkAction {
        case openVerification
        case openSettings
        case openDashboard
    }
}
