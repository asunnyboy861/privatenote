import Foundation
import SwiftUI

enum AppTheme: String, CaseIterable, Identifiable {
    case system = "System"
    case light = "Light"
    case dark = "Dark"
    case midnight = "Midnight"
    case ocean = "Ocean"
    case forest = "Forest"
    case sunset = "Sunset"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .system: return "System"
        case .light: return "Light"
        case .dark: return "Dark"
        case .midnight: return "Midnight"
        case .ocean: return "Ocean"
        case .forest: return "Forest"
        case .sunset: return "Sunset"
        }
    }
    
    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark, .midnight, .ocean, .forest, .sunset: return .dark
        }
    }
    
    var primaryColor: Color {
        switch self {
        case .system, .light: return .blue
        case .dark: return .purple
        case .midnight: return .indigo
        case .ocean: return .cyan
        case .forest: return .green
        case .sunset: return .orange
        }
    }
    
    var backgroundColor: Color {
        switch self {
        case .system, .light: return .white
        case .dark: return Color(white: 0.1)
        case .midnight: return Color(red: 0.05, green: 0.05, blue: 0.15)
        case .ocean: return Color(red: 0.05, green: 0.1, blue: 0.15)
        case .forest: return Color(red: 0.05, green: 0.1, blue: 0.05)
        case .sunset: return Color(red: 0.15, green: 0.08, blue: 0.05)
        }
    }
    
    var secondaryBackgroundColor: Color {
        switch self {
        case .system, .light: return Color(white: 0.95)
        case .dark: return Color(white: 0.15)
        case .midnight: return Color(red: 0.1, green: 0.1, blue: 0.2)
        case .ocean: return Color(red: 0.1, green: 0.15, blue: 0.2)
        case .forest: return Color(red: 0.1, green: 0.15, blue: 0.1)
        case .sunset: return Color(red: 0.2, green: 0.12, blue: 0.08)
        }
    }
    
    var textColor: Color {
        switch self {
        case .system, .light: return .primary
        case .dark: return .white
        case .midnight: return Color(white: 0.95)
        case .ocean: return Color(white: 0.95)
        case .forest: return Color(white: 0.95)
        case .sunset: return Color(white: 0.95)
        }
    }
    
    var secondaryTextColor: Color {
        switch self {
        case .system, .light: return .secondary
        case .dark: return Color(white: 0.7)
        case .midnight: return Color(white: 0.7)
        case .ocean: return Color(white: 0.7)
        case .forest: return Color(white: 0.7)
        case .sunset: return Color(white: 0.7)
        }
    }
    
    var accentColor: Color {
        primaryColor
    }
    
    var dividerColor: Color {
        switch self {
        case .system, .light: return Color(white: 0.9)
        case .dark, .midnight, .ocean, .forest, .sunset: return Color(white: 0.2)
        }
    }
    
    var icon: String {
        switch self {
        case .system: return "circle.lefthalf.filled"
        case .light: return "sun.max.fill"
        case .dark: return "moon.fill"
        case .midnight: return "star.fill"
        case .ocean: return "water"
        case .forest: return "leaf.fill"
        case .sunset: return "sun.haze.fill"
        }
    }
}

final class ThemeManager: ObservableObject {
    static let shared = ThemeManager()
    
    @Published var currentTheme: AppTheme {
        didSet {
            UserDefaults.standard.set(currentTheme.rawValue, forKey: "appTheme")
            applyTheme()
        }
    }
    
    @Published var customFont: Font = .body
    @Published var fontSize: FontSize = .medium
    
    enum FontSize: String, CaseIterable {
        case small = "Small"
        case medium = "Medium"
        case large = "Large"
        case extraLarge = "Extra Large"
        
        var font: Font {
            switch self {
            case .small: return .caption
            case .medium: return .body
            case .large: return .title3
            case .extraLarge: return .title
            }
        }
    }
    
    private let themeKey = "appTheme"
    private let fontSizeKey = "fontSize"
    
    init() {
        let savedTheme = UserDefaults.standard.string(forKey: themeKey) ?? AppTheme.system.rawValue
        currentTheme = AppTheme(rawValue: savedTheme) ?? .system
        
        let savedFontSize = UserDefaults.standard.string(forKey: fontSizeKey) ?? FontSize.medium.rawValue
        fontSize = FontSize(rawValue: savedFontSize) ?? .medium
        
        setupAppearance()
    }
    
    func applyTheme() {
        applyThemeColors()
    }
    
    func setFontSize(_ size: FontSize) {
        fontSize = size
        UserDefaults.standard.set(size.rawValue, forKey: fontSizeKey)
    }
    
    func resetToSystem() {
        currentTheme = .system
        fontSize = .medium
    }
    
    private func setupAppearance() {
        #if os(iOS)
        setupiOSAppearance()
        #elseif os(macOS)
        setupmacOSAppearance()
        #endif
    }
    
    #if os(iOS)
    private func setupiOSAppearance() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(currentTheme.secondaryBackgroundColor)
        appearance.titleTextAttributes = [.foregroundColor: UIColor(currentTheme.textColor)]
        
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithOpaqueBackground()
        tabBarAppearance.backgroundColor = UIColor(currentTheme.secondaryBackgroundColor)
        
        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
    }
    #elseif os(macOS)
    private func setupmacOSAppearance() {
    }
    #endif
    
    private func applyThemeColors() {
        #if os(iOS)
        let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene
        windowScene?.windows.first?.backgroundColor = UIColor(currentTheme.backgroundColor)
        #endif
    }
}

struct ThemeModifier: ViewModifier {
    let theme: AppTheme
    
    func body(content: Content) -> some View {
        content
            .preferredColorScheme(theme.colorScheme)
    }
}

extension View {
    func applyTheme(_ theme: AppTheme) -> some View {
        modifier(ThemeModifier(theme: theme))
    }
}

struct ThemePickerView: View {
    @ObservedObject var themeManager = ThemeManager.shared
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                Section("Appearance") {
                    ForEach(AppTheme.allCases) { theme in
                        Button(action: {
                            withAnimation {
                                themeManager.currentTheme = theme
                            }
                        }) {
                            HStack {
                                Image(systemName: theme.icon)
                                    .foregroundColor(themeManager.currentTheme == theme ? theme.primaryColor : theme.textColor)
                                    .frame(width: 30)
                                
                                Text(theme.displayName)
                                    .foregroundColor(theme.textColor)
                                
                                Spacer()
                                
                                if themeManager.currentTheme == theme {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(theme.primaryColor)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
                
                Section("Font Size") {
                    Picker("Font Size", selection: $themeManager.fontSize) {
                        ForEach(ThemeManager.FontSize.allCases, id: \.self) { size in
                            Text(size.rawValue).tag(size)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                Section {
                    Button("Reset to System") {
                        themeManager.resetToSystem()
                    }
                    .foregroundColor(.red)
                }
            }
            .navigationTitle("Theme")
            .toolbar {
                #if os(iOS)
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
                #elseif os(macOS)
                ToolbarItem(placement: .automatic) {
                    Button("Done") {
                        dismiss()
                    }
                }
                #endif
            }
            .background(themeManager.currentTheme.backgroundColor)
        }
    }
}
