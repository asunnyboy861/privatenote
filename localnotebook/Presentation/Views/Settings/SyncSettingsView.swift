import SwiftUI

struct SyncSettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()
    @EnvironmentObject var syncEngine: SyncEngine
    
    var body: some View {
        Form {
            Section("iCloud Sync") {
                HStack {
                    Image(systemName: "icloud")
                        .foregroundColor(.blue)
                        .frame(width: 24)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("iCloud Status")
                            .foregroundColor(.primary)
                        Text(syncEngine.isAvailable() ? "Connected" : "Not Available")
                            .font(.caption)
                            .foregroundColor(syncEngine.isAvailable() ? .green : .secondary)
                    }
                    
                    Spacer()
                    
                    if syncEngine.isAvailable() {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    }
                }
                
                HStack {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .foregroundColor(.purple)
                        .frame(width: 24)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Auto Sync")
                            .foregroundColor(.primary)
                        Text("Sync notes automatically")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Toggle("", isOn: Binding(
                        get: { viewModel.syncEnabled },
                        set: { viewModel.toggleSync($0) }
                    ))
                    .labelsHidden()
                }
            }
            
            Section("Sync Status") {
                HStack {
                    Image(systemName: "clock")
                        .foregroundColor(.orange)
                        .frame(width: 24)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Last Synced")
                            .foregroundColor(.primary)
                        Text(viewModel.lastSyncTimeString)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
                
                Button {
                    Task {
                        try? await syncEngine.syncAll()
                        viewModel.loadSettings()
                        HapticFeedback.shared.playSuccess()
                    }
                } label: {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(.blue)
                            .frame(width: 24)
                        
                        Text("Sync Now")
                            .foregroundColor(.primary)
                    }
                }
            }
            
            Section("Conflict Resolution") {
                HStack {
                    Image(systemName: "arrow.triangle.merge")
                        .foregroundColor(.yellow)
                        .frame(width: 24)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Automatic Resolution")
                            .foregroundColor(.primary)
                        Text("Uses vector clocks for conflict detection")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                }
            }
            
            Section {
                Text("Your notes are encrypted before syncing to iCloud. Only you can decrypt them with your password.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .navigationTitle("Sync Settings")
    }
}

#Preview {
    NavigationStack {
        SyncSettingsView()
            .environmentObject(SyncEngine())
    }
}
