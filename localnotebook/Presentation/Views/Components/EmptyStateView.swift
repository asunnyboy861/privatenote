import SwiftUI

struct EmptyStateView: View {
    let title: String
    let subtitle: String
    let icon: String
    let actionTitle: String?
    let action: (() -> Void)?
    
    init(
        title: String,
        subtitle: String,
        icon: String = "note.text",
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.actionTitle = actionTitle
        self.action = action
    }
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: icon)
                .font(.system(size: 80))
                .foregroundColor(.gray.opacity(0.5))
                .padding(40)
                .background(
                    Circle()
                        .fill(Color.gray.opacity(0.1))
                        .frame(width: 120, height: 120)
                )
            
            Text(title)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text(subtitle)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            if let actionTitle = actionTitle, let action = action {
                Button(action: action) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text(actionTitle)
                    }
                    .font(.headline)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 14)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .padding(.top, 8)
            }
            
            VStack(spacing: 12) {
                Text("💡 Quick Tips")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                
                HStack(spacing: 16) {
                    TipCard(
                        icon: "pin.fill",
                        text: "Pin important notes",
                        color: .orange
                    )
                    
                    TipCard(
                        icon: "star.fill",
                        text: "Star favorites",
                        color: .yellow
                    )
                    
                    TipCard(
                        icon: "tag.fill",
                        text: "Add tags",
                        color: .blue
                    )
                }
                .padding(.horizontal, 20)
            }
            .padding(.top, 32)
        }
        .padding(.vertical, 60)
    }
}

struct TipCard: View {
    let icon: String
    let text: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(color)
            
            Text(text)
                .font(.caption2)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .frame(width: 80)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 8)
        .background(color.opacity(0.08))
        .cornerRadius(8)
    }
}

#Preview {
    EmptyStateView(
        title: "No Notes Yet",
        subtitle: "Tap the + button to create your first note",
        actionTitle: "Create Note",
        action: { print("Create note tapped") }
    )
}
