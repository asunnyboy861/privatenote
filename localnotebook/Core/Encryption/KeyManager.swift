import Foundation
import CryptoKit
import Security

enum KeyManagerError: LocalizedError {
    case keyNotFound
    case keychainError
    case derivationFailed
    case authenticationRequired
    
    var errorDescription: String? {
        switch self {
        case .keyNotFound:
            return "The required key was not found."
        case .keychainError:
            return "Keychain operation failed."
        case .derivationFailed:
            return "Key derivation failed."
        case .authenticationRequired:
            return "Authentication is required to access this key."
        }
    }
}

protocol KeyManagerProtocol {
    func deriveKeyFromPassword(_ password: String, salt: Data) throws -> SymmetricKey
    func storeKey(_ key: SymmetricKey, identifier: String) throws
    func retrieveKey(identifier: String) throws -> SymmetricKey
    func deleteKey(identifier: String) throws
    func keyExists(identifier: String) -> Bool
}

final class KeyManager: KeyManagerProtocol {
    
    private let keychainService: String
    private let cryptoEngine: CryptoEngineProtocol
    
    init(
        keychainService: String = "com.privernote.keychain",
        cryptoEngine: CryptoEngineProtocol = CryptoEngine()
    ) {
        self.keychainService = keychainService
        self.cryptoEngine = cryptoEngine
    }
    
    func deriveKeyFromPassword(_ password: String, salt: Data) throws -> SymmetricKey {
        guard let passwordData = password.data(using: .utf8) else {
            throw KeyManagerError.derivationFailed
        }
        
        let inputKey = SymmetricKey(data: passwordData)
        let derivedKey = HKDF<SHA256>.deriveKey(
            inputKeyMaterial: inputKey,
            salt: salt,
            info: Data("PrivaNote Master Key".utf8),
            outputByteCount: 32
        )
        
        return derivedKey
    }
    
    func storeKey(_ key: SymmetricKey, identifier: String) throws {
        let keyData = key.withUnsafeBytes { Data($0) }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: identifier,
            kSecValueData as String: keyData,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        SecItemDelete(query as CFDictionary)
        
        let status = SecItemAdd(query as CFDictionary, nil)
        
        guard status == errSecSuccess else {
            throw KeyManagerError.keychainError
        }
    }
    
    func retrieveKey(identifier: String) throws -> SymmetricKey {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: identifier,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let keyData = result as? Data else {
            throw KeyManagerError.keyNotFound
        }
        
        return SymmetricKey(data: keyData)
    }
    
    func deleteKey(identifier: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: identifier
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeyManagerError.keychainError
        }
    }
    
    func keyExists(identifier: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: identifier
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        return status == errSecSuccess
    }
}
