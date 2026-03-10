import SwiftUI

struct ThemeSettingsView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @State private var selectedTheme: AppTheme
    
    init() {
        _selectedTheme = State(initialValue: ThemeManager.shared.currentTheme)
    }
    
    var body: some View {
        Form {
            Section("Theme") {
                ForEach(AppTheme.allCases) { theme in
                    Button {
                        selectedTheme = theme
                        themeManager.setTheme(theme)
                        HapticFeedback.shared.playSelection()
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(theme.displayName)
                                    .foregroundColor(.primary)
                                
                                Text(theme.description)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            if themeManager.currentTheme == theme {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.accentColor)
                            }
                        }
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
                ForEach(["Tag1", "Tag2", "Tag3"], id: \.self) { tag in
                    Text("#\(tag)")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(theme.primaryColor.opacity(0.2))
                        .foregroundColor(theme.primaryColor)
                        .cornerRadius(12)
                }
            }
        }
        .padding()
        .background(theme.backgroundColor)
        .cornerRadius(12)
    }
}

extension AppTheme {
    var description: String {
        switch self {
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

#Preview {
    NavigationStack {
        ThemeSettingsView()
            .environmentObject(ThemeManager.shared)
    }
}
