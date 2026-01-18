import SwiftUI

/// Screen for selecting which days of the week have alarms
struct DaySelectionView: View {
    let weeklyMinimum: Int
    @Binding var selectedDays: Set<Int>
    let onContinue: () -> Void
    let theme: AppTheme

    private let days = [
        (1, "Monday", "M"),
        (2, "Tuesday", "T"),
        (3, "Wednesday", "W"),
        (4, "Thursday", "T"),
        (5, "Friday", "F"),
        (6, "Saturday", "S"),
        (7, "Sunday", "S")
    ]

    private var canContinue: Bool {
        selectedDays.count >= weeklyMinimum
    }

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // Header
            VStack(spacing: 12) {
                Text("Pick Your Days")
                    .font(.largeTitle.bold())
                    .foregroundStyle(OnboardingColors.primaryText(for: theme))

                Text("Select at least \(weeklyMinimum) days for your morning alarm")
                    .font(.body)
                    .foregroundStyle(OnboardingColors.secondaryText(for: theme))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            Spacer()

            // Day grid
            VStack(spacing: 16) {
                // Weekdays
                HStack(spacing: 12) {
                    ForEach(days.prefix(5), id: \.0) { day in
                        DayButton(
                            letter: day.2,
                            fullName: day.1,
                            isSelected: selectedDays.contains(day.0),
                            theme: theme,
                            action: { toggleDay(day.0) }
                        )
                    }
                }

                // Weekend
                HStack(spacing: 12) {
                    ForEach(days.suffix(2), id: \.0) { day in
                        DayButton(
                            letter: day.2,
                            fullName: day.1,
                            isSelected: selectedDays.contains(day.0),
                            theme: theme,
                            action: { toggleDay(day.0) }
                        )
                    }
                }
            }

            // Count indicator
            Text("\(selectedDays.count) of \(weeklyMinimum) minimum selected")
                .font(.subheadline)
                .foregroundStyle(canContinue ? OnboardingColors.secondaryText(for: theme) : Color.orange)

            Spacer()

            // Continue button
            Button(action: onContinue) {
                Text("Continue")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(canContinue ? Color.accentColor : Color(white: 0.3))
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .disabled(!canContinue)
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
    }

    private func toggleDay(_ day: Int) {
        if selectedDays.contains(day) {
            // Only allow removal if we stay above minimum
            if selectedDays.count > weeklyMinimum {
                selectedDays.remove(day)
            }
        } else {
            selectedDays.insert(day)
        }
    }
}

// MARK: - Day Button

struct DayButton: View {
    let letter: String
    let fullName: String
    let isSelected: Bool
    let theme: AppTheme
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(letter)
                    .font(.title2.bold())

                Text(fullName.prefix(3))
                    .font(.caption2)
            }
            .frame(width: 56, height: 64)
            .background(isSelected ? Color.accentColor : OnboardingColors.cardBackground(for: theme))
            .foregroundStyle(isSelected ? .white : OnboardingColors.primaryText(for: theme))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ZStack {
        OnboardingColors.background(for: .dark)
            .ignoresSafeArea()
        DaySelectionView(
            weeklyMinimum: 4,
            selectedDays: .constant([1, 2, 3, 4]),
            onContinue: {},
            theme: .dark
        )
    }
}
