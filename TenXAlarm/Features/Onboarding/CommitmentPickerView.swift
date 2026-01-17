import SwiftUI

/// Screen for selecting weekly minimum commitment
struct CommitmentPickerView: View {
    @Binding var weeklyMinimum: Int
    let onContinue: () -> Void

    private let minDays = 4
    private let maxDays = 7

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // Header
            VStack(spacing: 12) {
                Text("Your Commitment")
                    .font(.largeTitle.bold())

                Text("How many days per week will you commit to brushing?")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            Spacer()

            // Day picker
            VStack(spacing: 24) {
                Text("\(weeklyMinimum)")
                    .font(.system(size: 72, weight: .bold, design: .rounded))
                    .foregroundStyle(.accent)

                Text("days per week")
                    .font(.title3)
                    .foregroundStyle(.secondary)

                // Slider
                HStack {
                    Text("\(minDays)")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Slider(
                        value: Binding(
                            get: { Double(weeklyMinimum) },
                            set: { weeklyMinimum = Int($0) }
                        ),
                        in: Double(minDays)...Double(maxDays),
                        step: 1
                    )
                    .tint(.accent)

                    Text("\(maxDays)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 32)
            }

            // Streak info
            if weeklyMinimum == 7 {
                Label {
                    Text("7 days = infinite streak potential")
                        .font(.subheadline)
                } icon: {
                    Image(systemName: "flame.fill")
                        .foregroundStyle(.orange)
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                Text("With \(weeklyMinimum) days, your max streak is \(weeklyMinimum) days before reset")
                    .font(.caption)
                    .foregroundStyle(.secondary)
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
    CommitmentPickerView(weeklyMinimum: .constant(4), onContinue: {})
}
