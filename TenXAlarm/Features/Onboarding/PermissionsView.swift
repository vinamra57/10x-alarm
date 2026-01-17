import SwiftUI
import AVFoundation

/// Screen for requesting necessary permissions
struct PermissionsView: View {
    let onComplete: () -> Void

    @State private var cameraGranted = false
    @State private var alarmGranted = false
    @State private var isRequestingCamera = false
    @State private var isRequestingAlarm = false

    private var allPermissionsGranted: Bool {
        cameraGranted && alarmGranted
    }

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // Header
            VStack(spacing: 12) {
                Image(systemName: "checkmark.shield.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(.accent)

                Text("Permissions")
                    .font(.largeTitle.bold())

                Text("10x Alarm needs a few permissions to work properly")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            Spacer()

            // Permission cards
            VStack(spacing: 16) {
                PermissionCard(
                    icon: "camera.fill",
                    title: "Camera",
                    description: "To verify you're brushing",
                    isGranted: cameraGranted,
                    isLoading: isRequestingCamera,
                    action: requestCameraPermission
                )

                PermissionCard(
                    icon: "alarm.fill",
                    title: "Alarms",
                    description: "To wake you up on schedule",
                    isGranted: alarmGranted,
                    isLoading: isRequestingAlarm,
                    action: requestAlarmPermission
                )
            }
            .padding(.horizontal, 24)

            Spacer()

            // Complete button
            Button(action: onComplete) {
                Text(allPermissionsGranted ? "Get Started" : "Grant All Permissions")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(allPermissionsGranted ? Color.accentColor : Color(.systemGray4))
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .disabled(!allPermissionsGranted)
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
        .onAppear {
            checkExistingPermissions()
        }
    }

    private func checkExistingPermissions() {
        // Check camera
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            cameraGranted = true
        default:
            cameraGranted = false
        }

        // Alarm permission is auto-granted on first alarm schedule
        // For now, we'll mark it as granted after user interacts
        alarmGranted = false
    }

    private func requestCameraPermission() {
        isRequestingCamera = true

        AVCaptureDevice.requestAccess(for: .video) { granted in
            DispatchQueue.main.async {
                cameraGranted = granted
                isRequestingCamera = false
            }
        }
    }

    private func requestAlarmPermission() {
        isRequestingAlarm = true

        // AlarmKit requests permission automatically when scheduling
        // For onboarding, we'll simulate this
        Task {
            try? await Task.sleep(for: .seconds(0.5))
            await MainActor.run {
                alarmGranted = true
                isRequestingAlarm = false
            }
        }
    }
}

// MARK: - Permission Card

struct PermissionCard: View {
    let icon: String
    let title: String
    let description: String
    let isGranted: Bool
    let isLoading: Bool
    let action: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .frame(width: 44, height: 44)
                .background(Color.accentColor.opacity(0.1))
                .foregroundStyle(.accent)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)

                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if isLoading {
                ProgressView()
            } else if isGranted {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .font(.title2)
            } else {
                Button("Allow") {
                    action()
                }
                .buttonStyle(.bordered)
                .tint(.accent)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

#Preview {
    PermissionsView(onComplete: {})
}
