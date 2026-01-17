import SwiftUI

/// Shows the result of a verification attempt
struct VerificationResultView: View {
    let result: VerificationOutput
    let attemptCount: Int
    let onRetry: () -> Void
    let onDismiss: () -> Void
    let isAlarmTriggered: Bool

    var body: some View {
        VStack(spacing: 24) {
            // Icon
            Image(systemName: result.passed ? "checkmark.circle.fill" : "xmark.circle.fill")
                .font(.system(size: 72))
                .foregroundStyle(result.passed ? .green : .red)

            // Message
            VStack(spacing: 8) {
                Text(result.passed ? "Verified!" : "Not Quite")
                    .font(.title.bold())

                Text(result.userMessage)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            // Attempt count (if multiple)
            if attemptCount > 1 && !result.passed {
                Text("Attempt \(attemptCount)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Buttons
            VStack(spacing: 12) {
                if result.passed {
                    Button(action: onDismiss) {
                        Text("Done")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.accentColor)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                } else {
                    Button(action: onRetry) {
                        Text("Try Again")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.accentColor)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }

                    // Tips button
                    NavigationLink {
                        VerificationTipsView()
                    } label: {
                        Text("View Tips")
                            .font(.subheadline)
                            .foregroundStyle(.accent)
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
        .padding(.top, 32)
    }
}

// MARK: - Verification Tips

struct VerificationTipsView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section("Lighting") {
                    TipRow(
                        icon: "sun.max.fill",
                        title: "Use good lighting",
                        description: "Stand facing a light source. Bathroom lights work well."
                    )
                }

                Section("Position") {
                    TipRow(
                        icon: "person.crop.rectangle",
                        title: "Center your face",
                        description: "Keep your face centered and clearly visible."
                    )

                    TipRow(
                        icon: "arrow.up.and.down",
                        title: "Right distance",
                        description: "Not too close, not too far. Your face should fill about half the screen."
                    )
                }

                Section("Toothbrush") {
                    TipRow(
                        icon: "mouth.fill",
                        title: "Brush visibly",
                        description: "Make sure the toothbrush is clearly in your mouth."
                    )

                    TipRow(
                        icon: "hand.raised.fill",
                        title: "Don't cover face",
                        description: "Hold the brush so your face is still visible."
                    )
                }

                Section("Common Issues") {
                    TipRow(
                        icon: "person.2.fill",
                        title: "One person only",
                        description: "Only you should be in the frame."
                    )

                    TipRow(
                        icon: "exclamationmark.triangle.fill",
                        title: "Avoid reflections",
                        description: "Mirror selfies may cause detection issues."
                    )
                }
            }
            .navigationTitle("Verification Tips")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct TipRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.accent)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)

                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    VerificationResultView(
        result: VerificationOutput(passed: true, reason: nil, confidence: 0.95),
        attemptCount: 1,
        onRetry: {},
        onDismiss: {},
        isAlarmTriggered: true
    )
}
