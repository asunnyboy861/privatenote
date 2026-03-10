import Foundation
import Combine

@MainActor
final class OnboardingViewModel: ObservableObject {
    @Published var currentPage: Int = 0
    
    private let userDefaults: UserDefaults
    
    let pages: [OnboardingPage] = [
        OnboardingPage(
            icon: "lock.shield",
            title: "End-to-End Encrypted",
            description: "Your notes are secured with military-grade AES-GCM 256-bit encryption",
            color: .blue
        ),
        OnboardingPage(
            icon: "faceid",
            title: "Biometric Security",
            description: "Unlock with Face ID or Touch ID for instant, secure access",
            color: .green
        ),
        OnboardingPage(
            icon: "icloud",
            title: "Encrypted Cloud Sync",
            description: "Your notes sync across devices with zero-knowledge encryption",
            color: .purple
        ),
        OnboardingPage(
            icon: "hand.raised",
            title: "Privacy First",
            description: "We can't read your notes. Only you have the key.",
            color: .orange
        )
    ]
    
    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }
    
    func nextPage() {
        guard currentPage < pages.count - 1 else { return }
        currentPage += 1
    }
    
    func previousPage() {
        guard currentPage > 0 else { return }
        currentPage -= 1
    }
    
    func completeOnboarding() {
        userDefaults.set(true, forKey: "hasCompletedOnboarding")
        NotificationCenter.default.post(
            name: .onboardingCompleted,
            object: nil
        )
    }
    
    func skipOnboarding() {
        userDefaults.set(true, forKey: "hasCompletedOnboarding")
        NotificationCenter.default.post(
            name: .onboardingCompleted,
            object: nil
        )
    }
}

extension Notification.Name {
    static let onboardingCompleted = Notification.Name("onboardingCompleted")
}
