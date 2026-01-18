import SwiftUI

/// Screen for selecting weekly minimum commitment
struct CommitmentPickerView: View {
    @Binding var weeklyMinimum: Int
    let onContinue: () -> Void
    let theme: AppTheme

    private let minDays = 4
    private let maxDays = 7

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // Header
            VStack(spacing: 12) {
                Text("Your Commitment")
                    .font(.largeTitle.bold())
                    .foregroundStyle(OnboardingColors.primaryText(for: theme))

                Text("How many days per week will you wake up early?")
                    .font(.body)
                    .foregroundStyle(OnboardingColors.secondaryText(for: theme))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            Spacer()

            // Day picker
            VStack(spacing: 24) {
                Text("\(weeklyMinimum)")
                    .font(.system(size: 72, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.accentColor)

                Text("days per week")
                    .font(.title3)
                    .foregroundStyle(OnboardingColors.secondaryText(for: theme))

                // Slider
                HStack {
                    Text("\(minDays)")
                        .font(.caption)
                        .foregroundStyle(OnboardingColors.secondaryText(for: theme))

                    Slider(
                        value: Binding(
                            get: { Double(weeklyMinimum) },
                            set: { weeklyMinimum = Int($0) }
                        ),
                        in: Double(minDays)...Double(maxDays),
                        step: 1
                    )
                    .tint(Color.accentColor)

                    Text("\(maxDays)")
                        .font(.caption)
                        .foregroundStyle(OnboardingColors.secondaryText(for: theme))
                }
                .padding(.horizontal, 32)
            }

            // Streak info
            if weeklyMinimum == 7 {
                Label {
                    Text("7 days = infinite streak potential")
                        .font(.subheadline)
                        .foregroundStyle(OnboardingColors.primaryText(for: theme))
                } icon: {
                    Image(systemName: "flame.fill")
                        .foregroundStyle(.orange)
                }
                .padding()
                .background(OnboardingColors.cardBackground(for: theme))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                Text("You can set alarms on more than \(weeklyMinimum) days to keep your streak going longer")
                    .font(.caption)
                    .foregroundStyle(OnboardingColors.secondaryText(for: theme))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            Spacer()

            // Continue button
            Button(action: onContinue) {
                Text("Continue")
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
        CommitmentPickerView(weeklyMinimum: .constant(4), onContinue: {}, theme: .dark)
    }
}
