import SwiftUI
import AVFoundation

/// Screen for requesting necessary permissions
struct PermissionsView: View {
    @Binding var selectedTheme: AppTheme
    @Binding var cameraGranted: Bool
    @Binding var alarmGranted: Bool
    @Binding var hasCheckedPermissions: Bool
    let onComplete: () -> Void

    @State private var isRequestingCamera = false
    @State private var isRequestingAlarm = false

    private var allPermissionsGranted: Bool {
        cameraGranted && alarmGranted
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 12) {
                    Image(systemName: "checkmark.shield.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(Color.accentColor)

                    Text("Permissions")
                        .font(.largeTitle.bold())
                        .foregroundStyle(OnboardingColors.primaryText(for: selectedTheme))

                    Text("10x Alarm needs a few permissions to work properly")
                        .font(.body)
                        .foregroundStyle(OnboardingColors.secondaryText(for: selectedTheme))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding(.top, 32)

                // Permission cards
                VStack(spacing: 16) {
                    PermissionCard(
                        icon: "camera.fill",
                        title: "Camera",
                        description: "To verify you're brushing",
                        isGranted: cameraGranted,
                        isLoading: isRequestingCamera,
                        theme: selectedTheme,
                        action: requestCameraPermission
                    )

                    PermissionCard(
                        icon: "alarm.fill",
                        title: "Alarms",
                        description: "To wake you up on schedule",
                        isGranted: alarmGranted,
                        isLoading: isRequestingAlarm,
                        theme: selectedTheme,
                        action: requestAlarmPermission
                    )
                }
                .padding(.horizontal, 24)

                // Privacy notice
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "lock.shield.fill")
                        .font(.title3)
                        .foregroundStyle(.green)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Your Privacy Matters")
                            .font(.subheadline.bold())
                            .foregroundStyle(OnboardingColors.primaryText(for: selectedTheme))

                        // swiftlint:disable:next line_length
                        Text("Photos are deleted immediately after verification. No images are stored, and your data is never used for ML training or shared with anyone.")
                            .font(.caption)
                            .foregroundStyle(OnboardingColors.secondaryText(for: selectedTheme))
                    }
                }
                .padding()
                .background(OnboardingColors.cardBackground(for: selectedTheme))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal, 24)

                // Theme selector
                VStack(alignment: .leading, spacing: 12) {
                    Text("Appearance")
                        .font(.headline)
                        .foregroundStyle(OnboardingColors.primaryText(for: selectedTheme))
                        .padding(.horizontal, 24)

                    Picker("Theme", selection: $selectedTheme) {
                        ForEach(AppTheme.allCases, id: \.self) { theme in
                            Text(theme.displayName).tag(theme)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 24)
                }

                Spacer(minLength: 32)

                // Complete button
                Button(action: onComplete) {
                    Text(allPermissionsGranted ? "Get Started" : "Grant All Permissions")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(allPermissionsGranted ? Color.accentColor : Color(white: 0.3))
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .disabled(!allPermissionsGranted)
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
        }
        .onAppear {
            // Only check permissions once
            if !hasCheckedPermissions {
                checkExistingPermissions()
                hasCheckedPermissions = true
            }
        }
    }

    private func checkExistingPermissions() {
        // Check camera
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            cameraGranted = true
        default:
            break // Don't reset to false, keep existing state
        }
        // Note: alarmGranted keeps its existing state
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
    let theme: AppTheme
    let action: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .frame(width: 44, height: 44)
                .background(Color.accentColor.opacity(0.15))
                .foregroundStyle(Color.accentColor)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(OnboardingColors.primaryText(for: theme))

                Text(description)
                    .font(.caption)
                    .foregroundStyle(OnboardingColors.secondaryText(for: theme))
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
                .buttonStyle(.borderedProminent)
                .tint(Color.accentColor)
            }
        }
        .padding()
        .background(OnboardingColors.cardBackground(for: theme))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

#Preview {
    PermissionsView(
        selectedTheme: .constant(.dark),
        cameraGranted: .constant(false),
        alarmGranted: .constant(true),
        hasCheckedPermissions: .constant(false),
        onComplete: {}
    )
}
