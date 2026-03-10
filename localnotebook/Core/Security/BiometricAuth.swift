import Foundation
import LocalAuthentication

enum BiometricAuthError: LocalizedError {
    case notAvailable
    case authenticationFailed
    case userCancel
    case userFallback
    case systemCancel
    case passcodeNotSet
    case lockout
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .notAvailable:
            return "Biometric authentication is not available on this device."
        case .authenticationFailed:
            return "Authentication failed. Please try again."
        case .userCancel:
            return "Authentication was cancelled by user."
        case .userFallback:
            return "User chose to use password instead."
        case .systemCancel:
            return "Authentication was cancelled by system."
        case .passcodeNotSet:
            return "No passcode is set on this device."
        case .lockout:
            return "Too many failed attempts. Please try again later."
        case .unknown:
            return "An unknown error occurred."
        }
    }
}

protocol BiometricAuthProtocol {
    func isAvailable() -> Bool
    func authenticate(reason: String) async throws -> Bool
}

final class BiometricAuth: BiometricAuthProtocol {
    
    private let context = LAContext()
    
    func isAvailable() -> Bool {
        var error: NSError?
        return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
    }
    
    func authenticate(reason: String) async throws -> Bool {
        var error: NSError?
        
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            throw mapError(error)
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, error in
                DispatchQueue.main.async {
                    if let error = error {
                        continuation.resume(throwing: self.mapError(error))
                    } else {
                        continuation.resume(returning: success)
                    }
                }
            }
        }
    }
    
    private func mapError(_ error: Error?) -> BiometricAuthError {
        guard let error = error as? LAError else {
            return .unknown
        }
        
        switch error.code {
        case .authenticationFailed:
            return .authenticationFailed
        case .userCancel:
            return .userCancel
        case .userFallback:
            return .userFallback
        case .systemCancel:
            return .systemCancel
        case .passcodeNotSet:
            return .passcodeNotSet
        case .biometryLockout:
            return .lockout
        case .biometryNotAvailable:
            return .notAvailable
        default:
            return .unknown
        }
    }
}
