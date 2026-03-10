import Foundation
import CryptoKit

enum CryptoEngineError: LocalizedError {
    case encryptionFailed
    case decryptionFailed
    case invalidCiphertext
    case keyDerivationFailed
    
    var errorDescription: String? {
        switch self {
        case .encryptionFailed:
            return "Encryption failed. Please try again."
        case .decryptionFailed:
            return "Decryption failed. The data may be corrupted."
        case .invalidCiphertext:
            return "Invalid ciphertext format."
        case .keyDerivationFailed:
            return "Key derivation failed."
        }
    }
}

protocol CryptoEngineProtocol {
    func encrypt(_ plaintext: String, with key: SymmetricKey) throws -> Data
    func decrypt(_ ciphertext: Data, with key: SymmetricKey) throws -> String
    func generateRandomKey() -> SymmetricKey
    func generateRandomBytes(count: Int) throws -> Data
}

final class CryptoEngine: CryptoEngineProtocol {
    
    func encrypt(_ plaintext: String, with key: SymmetricKey) throws -> Data {
        guard let data = plaintext.data(using: .utf8) else {
            throw CryptoEngineError.encryptionFailed
        }
        
        let sealedBox = try AES.GCM.seal(data, using: key)
        
        guard let combined = sealedBox.combined else {
            throw CryptoEngineError.encryptionFailed
        }
        
        return combined
    }
    
    func decrypt(_ ciphertext: Data, with key: SymmetricKey) throws -> String {
        guard ciphertext.count > 12 + 16 else {
            throw CryptoEngineError.invalidCiphertext
        }
        
        let sealedBox = try AES.GCM.SealedBox(combined: ciphertext)
        let decryptedData = try AES.GCM.open(sealedBox, using: key)
        
        guard let decrypted = String(data: decryptedData, encoding: .utf8) else {
            throw CryptoEngineError.decryptionFailed
        }
        
        return decrypted
    }
    
    func generateRandomKey() -> SymmetricKey {
        return SymmetricKey(size: .bits256)
    }
    
    func generateRandomBytes(count: Int) throws -> Data {
        var bytes = [UInt8](repeating: 0, count: count)
        let status = SecRandomCopyBytes(kSecRandomDefault, count, &bytes)
        
        guard status == errSecSuccess else {
            throw CryptoEngineError.keyDerivationFailed
        }
        
        return Data(bytes)
    }
}
