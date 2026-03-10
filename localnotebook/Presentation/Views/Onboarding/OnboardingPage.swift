import Foundation

struct OnboardingPage: Identifiable, Codable {
    let id: UUID
    let icon: String
    let title: String
    let description: String
    let color: ColorValue
    
    init(
        id: UUID = UUID(),
        icon: String,
        title: String,
        description: String,
        color: ColorValue
    ) {
        self.id = id
        self.icon = icon
        self.title = title
        self.description = description
        self.color = color
    }
}

enum ColorValue: String, Codable {
    case blue, green, purple, orange, red
}
