import Foundation

enum UserFacingError: LocalizedError {
    case authenticationFailed
    case syncFailed
    case decryptionFailed
    case networkUnavailable
    case storageFull
    case permissionDenied
    case custom(String)
    
    var errorDescription: String? {
        switch self {
        case .authenticationFailed:
            return "Authentication Failed"
        case .syncFailed:
            return "Sync Failed"
        case .decryptionFailed:
            return "Unable to Decrypt Note"
        case .networkUnavailable:
            return "No Internet Connection"
        case .storageFull:
            return "Storage Full"
        case .permissionDenied:
            return "Permission Denied"
        case .custom(let message):
            return message
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .authenticationFailed:
            return "Please try again or reset your password."
        case .syncFailed:
            return "Check your internet connection and try again."
        case .decryptionFailed:
            return "This note may be corrupted. Contact support."
        case .networkUnavailable:
            return "Please connect to Wi-Fi or cellular data."
        case .storageFull:
            return "Free up storage space in Settings."
        case .permissionDenied:
            return "Grant permission in Settings > Privacy."
        case .custom:
            return nil
        }
    }
    
    var icon: String {
        switch self {
        case .authenticationFailed:
            return "lock.shield"
        case .syncFailed:
            return "icloud.slash"
        case .decryptionFailed:
            return "lock.slash"
        case .networkUnavailable:
            return "wifi.slash"
        case .storageFull:
            return "externaldrive.full"
        case .permissionDenied:
            return "hand.raised"
        case .custom:
            return "exclamationmark.triangle"
        }
    }
}

extension UserFacingError {
    static func from(_ error: Error) -> UserFacingError {
        let errorDescription = error.localizedDescription.lowercased()
        
        if errorDescription.contains("crypto") || errorDescription.contains("decrypt") {
            return .decryptionFailed
        }
        
        if errorDescription.contains("sync") || errorDescription.contains("cloud") || errorDescription.contains("icloud") {
            return .syncFailed
        }
        
        if errorDescription.contains("network") || errorDescription.contains("internet") || errorDescription.contains("connection") {
            return .networkUnavailable
        }
        
        if errorDescription.contains("storage") || errorDescription.contains("disk") || errorDescription.contains("space") {
            return .storageFull
        }
        
        if errorDescription.contains("permission") || errorDescription.contains("access") || errorDescription.contains("denied") {
            return .permissionDenied
        }
        
        if errorDescription.contains("auth") || errorDescription.contains("password") || errorDescription.contains("login") {
            return .authenticationFailed
        }
        
        return .custom(error.localizedDescription)
    }
}
