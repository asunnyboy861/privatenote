import Foundation

final class ServiceLocator {
    static let shared = ServiceLocator()
    
    private var services: [String: Any] = [:]
    
    private init() {}
    
    func register<Service>(_ serviceType: Service.Type, instance: Service) {
        let key = String(describing: serviceType)
        services[key] = instance
    }
    
    func resolve<Service>(_ serviceType: Service.Type) -> Service? {
        let key = String(describing: serviceType)
        return services[key] as? Service
    }
    
    func resolve<Service>(_ serviceType: Service.Type, factory: () -> Service) -> Service {
        if let existing = resolve(serviceType) {
            return existing
        }
        let instance = factory()
        register(serviceType, instance: instance)
        return instance
    }
    
    func reset() {
        services.removeAll()
    }
}

extension ServiceLocator {
    var cryptoEngine: CryptoEngineProtocol {
        resolve(CryptoEngineProtocol.self) ?? CryptoEngine()
    }
    
    var keyManager: KeyManagerProtocol {
        resolve(KeyManagerProtocol.self) ?? KeyManager()
    }
    
    var noteStore: NoteStoreProtocol {
        resolve(NoteStoreProtocol.self) ?? NoteStore()
    }
    
    var noteRepository: NoteRepositoryProtocol {
        resolve(NoteRepositoryProtocol.self) ?? NoteRepository()
    }
    
    var biometricAuth: BiometricAuthProtocol {
        resolve(BiometricAuthProtocol.self) ?? BiometricAuth()
    }
    
    var syncEngine: SyncEngineProtocol {
        resolve(SyncEngineProtocol.self) ?? SyncEngine()
    }
    
    var exportService: ExportServiceProtocol {
        resolve(ExportServiceProtocol.self) ?? ExportService()
    }
    
    var importService: ImportServiceProtocol {
        resolve(ImportServiceProtocol.self) ?? ImportService()
    }
    
    var backgroundSyncManager: BackgroundSyncManager {
        resolve(BackgroundSyncManager.self) ?? BackgroundSyncManager.shared
    }
    
    var searchService: SearchServiceProtocol {
        resolve(SearchServiceProtocol.self) ?? SearchService()
    }
    
    var smartFolderService: SmartFolderServiceProtocol {
        resolve(SmartFolderServiceProtocol.self) ?? SmartFolderService()
    }
    
    var versionHistoryService: VersionHistoryServiceProtocol {
        resolve(VersionHistoryServiceProtocol.self) ?? VersionHistoryService()
    }
}
