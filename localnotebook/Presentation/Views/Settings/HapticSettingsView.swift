import SwiftUI

struct HapticSettingsView: View {
    @AppStorage("hapticEnabled") private var hapticEnabled = true
    @State private var testFeedbackType: HapticTestType?
    
    enum HapticTestType: String, CaseIterable, Identifiable {
        case click = "Click"
        case medium = "Medium"
        case heavy = "Heavy"
        case success = "Success"
        case warning = "Warning"
        case error = "Error"
        case selection = "Selection"
        
        var id: String { rawValue }
        
        var icon: String {
            switch self {
            case .click: return "hand.tap"
            case .medium: return "hand.tap.fill"
            case .heavy: return "hand.raised"
            case .success: return "checkmark.circle"
            case .warning: return "exclamationmark.triangle"
            case .error: return "xmark.circle"
            case .selection: return "checkmark"
            }
        }
        
        var color: Color {
            switch self {
            case .click, .medium, .heavy: return .blue
            case .success: return .green
            case .warning: return .orange
            case .error: return .red
            case .selection: return .purple
            }
        }
    }
    
    var body: some View {
        Form {
            Section {
                Toggle("Enable Haptic Feedback", isOn: $hapticEnabled)
                    .onChange(of: hapticEnabled) { newValue in
                        if newValue {
                            HapticFeedback.shared.playSuccess()
                        }
                    }
            } footer: {
                Text("Haptic feedback provides tactile responses when you interact with the app.")
            }
            
            if hapticEnabled {
                Section("Test Feedback") {
                    ForEach(HapticTestType.allCases) { type in
                        Button {
                            testHaptic(type)
                        } label: {
                            HStack {
                                Image(systemName: type.icon)
                                    .foregroundColor(type.color)
                                    .frame(width: 24)
                                
                                Text(type.rawValue)
                                    .foregroundColor(.primary)
                                
                                Spacer()
                                
                                Image(systemName: "hand.tap")
                                    .foregroundColor(.secondary)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                
                Section("Feedback Types") {
                    HStack {
                        Image(systemName: "hand.tap")
                            .foregroundColor(.blue)
                            .frame(width: 24)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Click")
                                .font(.subheadline)
                            Text("Light tap for button interactions")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    HStack {
                        Image(systemName: "checkmark.circle")
                            .foregroundColor(.green)
                            .frame(width: 24)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Success")
                                .font(.subheadline)
                            Text("Confirmation for completed actions")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    HStack {
                        Image(systemName: "xmark.circle")
                            .foregroundColor(.red)
                            .frame(width: 24)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Error")
                                .font(.subheadline)
                            Text("Alert for failed operations")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    HStack {
                        Image(systemName: "exclamationmark.triangle")
                            .foregroundColor(.orange)
                            .frame(width: 24)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Warning")
                                .font(.subheadline)
                            Text("Caution for important notices")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    HStack {
                        Image(systemName: "checkmark")
                            .foregroundColor(.purple)
                            .frame(width: 24)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Selection")
                                .font(.subheadline)
                            Text("Feedback for picker and slider changes")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
        .navigationTitle("Haptic Feedback")
    }
    
    private func testHaptic(_ type: HapticTestType) {
        switch type {
        case .click:
            HapticFeedback.shared.playClick()
        case .medium:
            HapticFeedback.shared.playMedium()
        case .heavy:
            HapticFeedback.shared.playHeavy()
        case .success:
            HapticFeedback.shared.playSuccess()
        case .warning:
            HapticFeedback.shared.playWarning()
        case .error:
            HapticFeedback.shared.playError()
        case .selection:
            HapticFeedback.shared.playSelection()
        }
    }
}

#Preview {
    NavigationStack {
        HapticSettingsView()
    }
}
