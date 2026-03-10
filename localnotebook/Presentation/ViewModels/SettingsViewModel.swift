import Foundation
import SwiftUI

@MainActor
class SettingsViewModel: ObservableObject {
    @Published var biometricEnabled: Bool = false
    @Published var syncEnabled: Bool = true
    @Published var storageUsage: String = "0 MB"
    @Published var noteCount: Int = 0
    @Published var lastSyncTime: Date?
    @Published var markdownEnabled: Bool = true
    @Published var hapticEnabled: Bool = true
    
    private let noteRepository: NoteRepositoryProtocol
    private let syncEngine: SyncEngineProtocol
    
    init(
        noteRepository: NoteRepositoryProtocol = ServiceLocator.shared.noteRepository,
        syncEngine: SyncEngineProtocol = ServiceLocator.shared.syncEngine
    ) {
        self.noteRepository = noteRepository
        self.syncEngine = syncEngine
        
        loadSettings()
    }
    
    func loadSettings() {
        biometricEnabled = UserDefaults.standard.bool(forKey: "biometricEnabled")
        syncEnabled = UserDefaults.standard.bool(forKey: "syncEnabled")
        markdownEnabled = UserDefaults.standard.bool(forKey: "markdownEnabled")
        hapticEnabled = UserDefaults.standard.bool(forKey: "hapticEnabled")
        
        calculateStorageUsage()
        loadNoteCount()
        loadLastSyncTime()
    }
    
    func toggleBiometric(_ enabled: Bool) {
        UserDefaults.standard.set(enabled, forKey: "biometricEnabled")
        biometricEnabled = enabled
        HapticFeedback.shared.playSelection()
    }
    
    func toggleSync(_ enabled: Bool) {
        UserDefaults.standard.set(enabled, forKey: "syncEnabled")
        syncEnabled = enabled
        HapticFeedback.shared.playSelection()
    }
    
    func toggleMarkdown(_ enabled: Bool) {
        UserDefaults.standard.set(enabled, forKey: "markdownEnabled")
        markdownEnabled = enabled
        HapticFeedback.shared.playSelection()
    }
    
    func toggleHaptic(_ enabled: Bool) {
        UserDefaults.standard.set(enabled, forKey: "hapticEnabled")
        hapticEnabled = enabled
        if enabled {
            HapticFeedback.shared.playSuccess()
        }
    }
    
    func clearAllData() async throws {
        try noteRepository.deleteAll()
        loadSettings()
        HapticFeedback.shared.playSuccess()
    }
    
    func exportAllNotes() async -> URL? {
        do {
            let notes = try noteRepository.getAll()
            let exportService = ExportService()
            return try await exportService.exportNotes(notes, format: .json)
        } catch {
            return nil
        }
    }
    
    private func calculateStorageUsage() {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        if let attributes = try? FileManager.default.attributesOfFileSystem(forPath: documentsPath.path),
           let totalSize = attributes[.systemSize] as? UInt64 {
            let usedMB = Double(totalSize) / 1024.0 / 1024.0
            storageUsage = String(format: "%.1f MB", usedMB)
        } else {
            storageUsage = "Unknown"
        }
    }
    
    private func loadNoteCount() {
        do {
            let notes = try noteRepository.getAll()
            noteCount = notes.count
        } catch {
            noteCount = 0
        }
    }
    
    private func loadLastSyncTime() {
        lastSyncTime = UserDefaults.standard.object(forKey: "lastSyncTime") as? Date
    }
    
    var lastSyncTimeString: String {
        guard let time = lastSyncTime else {
            return "Never"
        }
        
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: time, relativeTo: Date())
    }
    
    var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }
    
    var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }
}
