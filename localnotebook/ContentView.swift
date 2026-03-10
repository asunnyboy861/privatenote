import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    
    var body: some View {
        Group {
            if !hasCompletedOnboarding {
                OnboardingView()
            } else if !appState.isUnlocked {
                UnlockView()
                    .environmentObject(appState)
            } else {
                MainTabView()
            }
        }
    }
}

struct MainTabView: View {
    @EnvironmentObject var syncEngine: SyncEngine
    
    var body: some View {
        TabView {
            NoteListView()
                .tabItem {
                    Label("Notes", systemImage: "note.text")
                }
            
            SmartFoldersView()
                .tabItem {
                    Label("Folders", systemImage: "folder")
                }
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
        .overlay(alignment: .topTrailing) {
            SyncStatusView(syncEngine: syncEngine)
                .padding(.trailing, 16)
                .padding(.top, 8)
        }
    }
}

struct SmartFoldersView: View {
    var body: some View {
        NavigationStack {
            VStack {
                EmptyStateView(
                    title: "No Smart Folders",
                    subtitle: "Create smart folders to organize your notes automatically",
                    icon: "folder.badge.gearshape"
                )
            }
            .navigationTitle("Smart Folders")
        }
    }
}

struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()
    @EnvironmentObject private var themeManager: ThemeManager
    @EnvironmentObject private var syncEngine: SyncEngine
    
    var body: some View {
        NavigationStack {
            List {
                Section("Appearance") {
                    NavigationLink {
                        ThemeSettingsView()
                    } label: {
                        HStack {
                            Image(systemName: "paintbrush")
                                .foregroundColor(.purple)
                                .frame(width: 24)
                            Text("Theme")
                            Spacer()
                            Text(themeManager.currentTheme.displayName)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    NavigationLink {
                        EditorSettingsView()
                    } label: {
                        HStack {
                            Image(systemName: "textformat.alt")
                                .foregroundColor(.blue)
                                .frame(width: 24)
                            Text("Editor Settings")
                        }
                    }
                    
                    NavigationLink {
                        HapticSettingsView()
                    } label: {
                        HStack {
                            Image(systemName: "hand.tap")
                                .foregroundColor(.orange)
                                .frame(width: 24)
                            Text("Haptic Feedback")
                            Spacer()
                            Text(viewModel.hapticEnabled ? "On" : "Off")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Section("Security") {
                    HStack {
                        Image(systemName: "lock.shield")
                            .foregroundColor(.green)
                            .frame(width: 24)
                        Text("End-to-End Encryption")
                        Spacer()
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    }
                    
                    NavigationLink {
                        SecuritySettingsView()
                    } label: {
                        HStack {
                            Image(systemName: "faceid")
                                .foregroundColor(.blue)
                                .frame(width: 24)
                            Text("Security Settings")
                            Spacer()
                            Text(viewModel.biometricEnabled ? "On" : "Off")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Section("Sync") {
                    HStack {
                        Image(systemName: "icloud")
                            .foregroundColor(.blue)
                            .frame(width: 24)
                        Text("iCloud Sync")
                        Spacer()
                        if syncEngine.isAvailable() {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                        } else {
                            Text("Unavailable")
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    NavigationLink {
                        SyncSettingsView()
                    } label: {
                        HStack {
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .foregroundColor(.purple)
                                .frame(width: 24)
                            Text("Sync Settings")
                        }
                    }
                }
                
                Section("Data") {
                    NavigationLink {
                        DataManagementView()
                    } label: {
                        HStack {
                            Image(systemName: "externaldrive")
                                .foregroundColor(.blue)
                                .frame(width: 24)
                            Text("Export & Import")
                        }
                    }
                    
                    HStack {
                        Image(systemName: "chart.pie")
                            .foregroundColor(.green)
                            .frame(width: 24)
                        Text("Storage Usage")
                        Spacer()
                        Text(viewModel.storageUsage)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Image(systemName: "note.text")
                            .foregroundColor(.orange)
                            .frame(width: 24)
                        Text("Total Notes")
                        Spacer()
                        Text("\(viewModel.noteCount)")
                            .foregroundColor(.secondary)
                    }
                }
                
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text(viewModel.appVersion)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Build")
                        Spacer()
                        Text(viewModel.buildNumber)
                            .foregroundColor(.secondary)
                    }
                    
                    Link(destination: URL(string: "https://privernote.app/privacy")!) {
                        HStack {
                            Image(systemName: "hand.raised")
                                .foregroundColor(.blue)
                                .frame(width: 24)
                            Text("Privacy Policy")
                        }
                    }
                    
                    Link(destination: URL(string: "https://privernote.app/terms")!) {
                        HStack {
                            Image(systemName: "doc.text")
                                .foregroundColor(.blue)
                                .frame(width: 24)
                            Text("Terms of Service")
                        }
                    }
                    
                    Link(destination: URL(string: "https://privernote.app/support")!) {
                        HStack {
                            Image(systemName: "questionmark.circle")
                                .foregroundColor(.blue)
                                .frame(width: 24)
                            Text("Support")
                        }
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AppState())
        .environmentObject(SyncEngine())
        .environmentObject(ThemeManager.shared)
}
