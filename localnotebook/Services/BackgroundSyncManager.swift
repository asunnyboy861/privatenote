import Foundation
import BackgroundTasks

final class BackgroundSyncManager {
    
    static let shared = BackgroundSyncManager()
    
    private let syncEngine: SyncEngineProtocol
    private let backgroundTaskIdentifier = "com.yourname.privernote.sync"
    
    #if os(iOS)
    private let syncInterval: TimeInterval = 15 * 60
    #else
    private let syncInterval: TimeInterval = 30 * 60
    #endif
    
    init(syncEngine: SyncEngineProtocol = SyncEngine()) {
        self.syncEngine = syncEngine
        
        #if os(iOS)
        registerBackgroundTasks()
        #endif
    }
    
    #if os(iOS)
    private func registerBackgroundTasks() {
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: backgroundTaskIdentifier,
            using: nil
        ) { [weak self] task in
            guard let self = self else { return }
            
            if let task = task as? BGProcessingTask {
                self.handleBackgroundSync(task: task)
            }
        }
    }
    
    func scheduleBackgroundSync() {
        let request = BGProcessingTaskRequest(identifier: backgroundTaskIdentifier)
        request.requiresNetworkConnectivity = true
        request.requiresExternalPower = false
        request.earliestBeginDate = Date(timeIntervalSinceNow: syncInterval)
        
        do {
            try BGTaskScheduler.shared.submit(request)
            print("Background sync scheduled")
        } catch {
            print("Failed to schedule background sync: \(error)")
        }
    }
    
    private func handleBackgroundSync(task: BGProcessingTask) {
        scheduleBackgroundSync()
        
        task.expirationHandler = {
            print("Background task expired")
        }
        
        Task {
            do {
                try await syncEngine.syncAll()
                task.setTaskCompleted(success: true)
                print("Background sync completed successfully")
            } catch {
                print("Background sync failed: \(error)")
                task.setTaskCompleted(success: false)
            }
        }
    }
    #endif
    
    func startPeriodicSync() {
        #if os(iOS)
        scheduleBackgroundSync()
        #endif
        
        startLocalPeriodicSync()
    }
    
    private func startLocalPeriodicSync() {
        #if os(iOS)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAppDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAppWillResignActive),
            name: UIApplication.willResignActiveNotification,
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
    }
    
    @objc private func handleAppDidBecomeActive() {
        Task {
            await performSync()
        }
    }
    
    @objc private func handleAppWillResignActive() {
        Task {
            await performSync()
        }
    }
    
    private func performSync() async {
        guard syncEngine.isAvailable() else {
            return
        }
        
        do {
            try await syncEngine.syncAll()
            print("Periodic sync completed")
        } catch {
            print("Periodic sync failed: \(error)")
        }
    }
    
    func stopPeriodicSync() {
        #if os(iOS)
        NotificationCenter.default.removeObserver(
            self,
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
        
        NotificationCenter.default.removeObserver(
            self,
            name: UIApplication.willResignActiveNotification,
            object: nil
        )
        #elseif os(macOS)
        NotificationCenter.default.removeObserver(
            self,
            name: NSApplication.didBecomeActiveNotification,
            object: nil
        )
        #endif
    }
}

#if os(iOS)
import UIKit
#else
import AppKit
#endif
