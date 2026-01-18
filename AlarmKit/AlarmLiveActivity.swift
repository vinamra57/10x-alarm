import Foundation
import SwiftUI
import ActivityKit
import WidgetKit

#if canImport(AlarmKit)
import AlarmKit
#endif

/// Configuration for the alarm Live Activity
///
/// Displayed on Lock Screen, Dynamic Island, and StandBy when alarm fires
struct AlarmActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        /// Current alarm title
        var title: String

        /// Whether this is the primary alarm or a backup (re-fire)
        var isBackupAlarm: Bool

        /// Minutes since primary alarm fired
        var minutesSinceStart: Int
    }

    /// Alarm identifier
    var alarmId: String

    /// Original scheduled time
    var scheduledTime: Date
}

// MARK: - Live Activity Configuration

struct AlarmLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: AlarmActivityAttributes.self) { context in
            // Lock Screen / Banner UI
            AlarmLiveActivityView(
                title: context.state.title,
                isBackupAlarm: context.state.isBackupAlarm,
                minutesSinceStart: context.state.minutesSinceStart
            )
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded view
                DynamicIslandExpandedRegion(.leading) {
                    Image(systemName: "alarm.fill")
                        .foregroundStyle(Color.accentColor)
                }

                DynamicIslandExpandedRegion(.trailing) {
                    if context.state.isBackupAlarm {
                        Text("\(context.state.minutesSinceStart)m")
                            .font(.caption)
                    }
                }

                DynamicIslandExpandedRegion(.center) {
                    Text(context.state.title)
                        .font(.headline)
                }

                DynamicIslandExpandedRegion(.bottom) {
                    Link(destination: URL(string: "tenxalarm://verify")!) {
                        HStack {
                            Image(systemName: "camera.fill")
                            Text("Verify Brush")
                        }
                        .font(.subheadline.bold())
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Color.accentColor)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
            } compactLeading: {
                Image(systemName: "alarm.fill")
                    .foregroundStyle(Color.accentColor)
            } compactTrailing: {
                Text(context.state.title)
                    .lineLimit(1)
            } minimal: {
                Image(systemName: "alarm.fill")
                    .foregroundStyle(Color.accentColor)
            }
        }
    }
}

// MARK: - Lock Screen View

struct AlarmLiveActivityView: View {
    let title: String
    let isBackupAlarm: Bool
    let minutesSinceStart: Int

    var body: some View {
        VStack(spacing: 12) {
            // Title
            HStack {
                Image(systemName: "alarm.fill")
                    .foregroundStyle(Color.accentColor)

                Text(title)
                    .font(.headline)

                Spacer()

                if isBackupAlarm {
                    Text("\(minutesSinceStart) min")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            // Verify button
            Link(destination: URL(string: "tenxalarm://verify")!) {
                HStack {
                    Image(systemName: "camera.fill")
                    Text("Verify Brush")
                }
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.accentColor)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding()
    }
}

// MARK: - Live Activity Manager

@Observable
final class AlarmLiveActivityManager {
    private var currentActivity: Activity<AlarmActivityAttributes>?

    /// Start a new alarm Live Activity
    func startActivity(alarmId: String, title: String, scheduledTime: Date) async throws {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            return
        }

        let attributes = AlarmActivityAttributes(
            alarmId: alarmId,
            scheduledTime: scheduledTime
        )

        let initialState = AlarmActivityAttributes.ContentState(
            title: title,
            isBackupAlarm: false,
            minutesSinceStart: 0
        )

        let content = ActivityContent(
            state: initialState,
            staleDate: nil
        )

        currentActivity = try Activity.request(
            attributes: attributes,
            content: content,
            pushType: nil
        )
    }

    /// Update the activity for a backup alarm
    func updateForBackupAlarm(minutesSinceStart: Int) async {
        guard let activity = currentActivity else { return }

        let newState = AlarmActivityAttributes.ContentState(
            title: "Still waiting...",
            isBackupAlarm: true,
            minutesSinceStart: minutesSinceStart
        )

        let content = ActivityContent(
            state: newState,
            staleDate: nil
        )

        await activity.update(content)
    }

    /// End the activity (after verification)
    func endActivity() async {
        guard let activity = currentActivity else { return }

        let finalState = AlarmActivityAttributes.ContentState(
            title: "Verified!",
            isBackupAlarm: false,
            minutesSinceStart: 0
        )

        let content = ActivityContent(
            state: finalState,
            staleDate: nil
        )

        await activity.end(content, dismissalPolicy: .immediate)
        currentActivity = nil
    }
}
