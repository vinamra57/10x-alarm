import SwiftUI

/// Welcome screen with value proposition
struct WelcomeView: View {
    let onContinue: () -> Void
    let theme: AppTheme

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // Icon
            Image(systemName: "alarm.fill")
                .font(.system(size: 80))
                .foregroundStyle(Color.accentColor)

            // Title
            Text("10x Alarm")
                .font(.largeTitle.bold())
                .foregroundStyle(OnboardingColors.primaryText(for: theme))

            Spacer()

            // Warning
            VStack(spacing: 12) {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.title2)
                        .foregroundStyle(.orange)

                    Text("Are you ready?")
                        .font(.headline)
                        .foregroundStyle(OnboardingColors.primaryText(for: theme))
                }

                // swiftlint:disable:next line_length
                Text("Once your alarm goes off, it won't stop until our ML models approve a picture of you brushing your teeth. No snooze. No skip.")
                    .font(.subheadline)
                    .foregroundStyle(OnboardingColors.secondaryText(for: theme))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            .padding()
            .background(OnboardingColors.cardBackground(for: theme))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal)

            Spacer()

            // Continue button
            Button(action: onContinue) {
                Text("Let's go")
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
    ZStack {
        OnboardingColors.background(for: .dark)
            .ignoresSafeArea()
        WelcomeView(onContinue: {}, theme: .dark)
    }
}
