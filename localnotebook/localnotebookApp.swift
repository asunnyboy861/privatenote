//
//  localnotebookApp.swift
//  localnotebook
//
//  Created by MacMini4 on 2026/3/10.
//

import SwiftUI

@main
struct PrivaNoteApp: App {
    @StateObject private var appState = AppState()
    @StateObject private var syncEngine = SyncEngine()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .environmentObject(syncEngine)
        }
    }
}

class AppState: ObservableObject {
    @Published var isUnlocked: Bool = false
    @Published var hasCompletedOnboarding: Bool = false
    
    private let keyManager: KeyManagerProtocol
    private let backgroundSyncManager: BackgroundSyncManager
    
    init() {
        self.keyManager = ServiceLocator.shared.keyManager
        self.backgroundSyncManager = ServiceLocator.shared.backgroundSyncManager
        
        hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
        
        checkIfUnlocked()
        setupNotifications()
    }
    
    func checkIfUnlocked() {
        isUnlocked = keyManager.keyExists(identifier: "masterKey")
    }
    
    func unlock() {
        isUnlocked = true
        startSync()
    }
    
    func lock() {
        isUnlocked = false
        stopSync()
    }
    
    private func setupNotifications() {
        #if os(iOS)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAppDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
        #elseif os(macOS)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAppDidBecomeActive),
            name: NSApplication.didBecomeActiveNotification,
            object: nil
        )
        #endif
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleOnboardingCompleted),
            name: .onboardingCompleted,
            object: nil
        )
    }
    
    @objc private func handleAppDidBecomeActive() {
        if isUnlocked {
            startSync()
        }
    }
    
    @objc private func handleOnboardingCompleted() {
        hasCompletedOnboarding = true
    }
    
    private func startSync() {
        backgroundSyncManager.startPeriodicSync()
    }
    
    private func stopSync() {
        backgroundSyncManager.stopPeriodicSync()
    }
}
