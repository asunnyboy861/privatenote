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
        NavigationView {
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
    var body: some View {
        NavigationView {
            List {
                Section("Security") {
                    HStack {
                        Image(systemName: "lock.shield")
                            .foregroundColor(.blue)
                        Text("End-to-End Encryption")
                        Spacer()
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    }
                    
                    HStack {
                        Image(systemName: "faceid")
                            .foregroundColor(.blue)
                        Text("Biometric Unlock")
                        Spacer()
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    }
                }
                
                Section("Sync") {
                    HStack {
                        Image(systemName: "icloud")
                            .foregroundColor(.blue)
                        Text("iCloud Sync")
                        Spacer()
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    }
                }
                
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    Link(destination: URL(string: "https://privernote.app/privacy")!) {
                        HStack {
                            Image(systemName: "hand.raised")
                            Text("Privacy Policy")
                        }
                    }
                    
                    Link(destination: URL(string: "https://privernote.app/terms")!) {
                        HStack {
                            Image(systemName: "doc.text")
                            Text("Terms of Service")
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
}
