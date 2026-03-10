import SwiftUI

struct OnboardingPageView: View {
    let page: OnboardingPage
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: page.icon)
                .font(.system(size: 100))
                .foregroundColor(color(from: page.color))
                .padding(40)
                .background(color(from: page.color).opacity(0.1))
                .clipShape(Circle())
            
            Text(page.title)
                .font(.title)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
            
            Text(page.description)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }
    
    private func color(from colorValue: ColorValue) -> Color {
        switch colorValue {
        case .blue: return .blue
        case .green: return .green
        case .purple: return .purple
        case .orange: return .orange
        case .red: return .red
        }
    }
}

#Preview {
    OnboardingPageView(
        page: OnboardingPage(
            icon: "lock.shield",
            title: "End-to-End Encrypted",
            description: "Your notes are secured",
            color: .blue
        )
    )
}
