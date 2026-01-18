import SwiftUI

/// App icon design - simple alarm clock
struct AppIconView: View {
    let size: CGFloat

    var body: some View {
        ZStack {
            Color(red: 0, green: 0.48, blue: 1.0)

            Image(systemName: "alarm.fill")
                .resizable()
                .scaledToFit()
                .foregroundStyle(.white)
                .padding(size * 0.18)
        }
        .frame(width: size, height: size)
    }
}

#Preview {
    AppIconView(size: 512)
        .clipShape(RoundedRectangle(cornerRadius: 100))
}
