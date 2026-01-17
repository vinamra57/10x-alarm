import SwiftUI

/// Welcome screen with value proposition
struct WelcomeView: View {
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // Icon
            Image(systemName: "alarm.fill")
                .font(.system(size: 80))
                .foregroundStyle(.accent)

            // Title
            VStack(spacing: 12) {
                Text("10x Alarm")
                    .font(.largeTitle.bold())

                Text("The alarm that makes you brush")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Warning
            VStack(spacing: 16) {
                Label {
                    Text("This is a commitment")
                        .font(.headline)
                } icon: {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                }

                Text("Once your alarm goes off, it won't stop until you prove you're brushing your teeth. No snooze. No skip.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal)

            Spacer()

            // Continue button
            Button(action: onContinue) {
                Text("I'm Ready")
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
    }
}

#Preview {
    WelcomeView(onContinue: {})
}
