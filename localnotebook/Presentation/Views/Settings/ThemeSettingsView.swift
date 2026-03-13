import SwiftUI

struct ThemeSettingsView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @State private var selectedTheme: AppTheme
    
    init() {
        _selectedTheme = State(initialValue: ThemeManager.shared.currentTheme)
    }
    
    private let themes: [AppTheme] = AppTheme.allCases
    
    var body: some View {
        Form {
            Section("Theme") {
                ForEach(themes, id: \.self) { theme in
                    Button {
                        selectedTheme = theme
                        themeManager.currentTheme = theme
                        HapticFeedback.shared.playSelection()
                    } label: {
                        ThemeRowContent(
                            theme: theme,
                            isSelected: themeManager.currentTheme == theme
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            
            Section("Preview") {
                ThemePreviewCard(theme: selectedTheme)
            }
            
            Section {
                Text("Choose a theme that suits your preference. The System option follows your device's appearance settings.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .navigationTitle("Theme")
    }
}

struct ThemeRowContent: View {
    let theme: AppTheme
    let isSelected: Bool
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(theme.displayName)
                    .foregroundColor(.primary)
                
                Text(themeDescription)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.accentColor)
            }
        }
    }
    
    private var themeDescription: String {
        switch theme {
        case .system: return "Follows system appearance"
        case .light: return "Light mode"
        case .dark: return "Dark mode"
        case .midnight: return "Deep blue dark theme"
        case .ocean: return "Ocean-inspired blue theme"
        case .forest: return "Nature-inspired green theme"
        case .sunset: return "Warm orange theme"
        }
    }
}

struct ThemePreviewCard: View {
    let theme: AppTheme
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Preview Title")
                        .font(.headline)
                        .foregroundColor(theme.textColor)
                    
                    Text("This is how your notes will look with the selected theme.")
                        .font(.body)
                        .foregroundColor(theme.secondaryTextColor)
                }
                
                Spacer()
            }
            
            HStack(spacing: 8) {
                PreviewTag(theme: theme, text: "Tag1")
                PreviewTag(theme: theme, text: "Tag2")
                PreviewTag(theme: theme, text: "Tag3")
            }
        }
        .padding()
        .background(theme.backgroundColor)
        .cornerRadius(12)
    }
}

struct PreviewTag: View {
    let theme: AppTheme
    let text: String
    
    var body: some View {
        Text("#\(text)")
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(theme.primaryColor.opacity(0.2))
            .foregroundColor(theme.primaryColor)
            .cornerRadius(12)
    }
}

#Preview {
    NavigationStack {
        ThemeSettingsView()
            .environmentObject(ThemeManager.shared)
    }
}
