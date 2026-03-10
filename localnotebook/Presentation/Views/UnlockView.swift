import SwiftUI

struct UnlockView: View {
    @EnvironmentObject var appState: AppState
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    @State private var isSettingUp: Bool = true
    @State private var errorMessage: String?
    @State private var showingBiometricPrompt = false
    
    private let keyManager: KeyManagerProtocol = ServiceLocator.shared.keyManager
    private let biometricAuth: BiometricAuthProtocol = ServiceLocator.shared.biometricAuth
    
    var body: some View {
        VStack(spacing: 30) {
            logoSection
            
            if isSettingUp {
                setupSection
            } else {
                unlockSection
            }
            
            errorMessageSection
            
            Spacer()
            
            actionButton
        }
        .padding()
        .animation(.easeInOut, value: isSettingUp)
    }
    
    private var logoSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "lock.shield")
                .font(.system(size: 80))
                .foregroundColor(.blue)
            
            Text("PrivaNote")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text(isSettingUp ? "Secure Your Notes" : "Enter Password to Unlock")
                .font(.title3)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }
    
    private var setupSection: some View {
        VStack(spacing: 20) {
            SecureField("Create Password", text: $password)
                .textFieldStyle(.roundedBorder)
                .disableAutocorrection(true)
            
            SecureField("Confirm Password", text: $confirmPassword)
                .textFieldStyle(.roundedBorder)
                .disableAutocorrection(true)
            
            if biometricAuth.isAvailable() {
                Button(action: { showingBiometricPrompt = true }) {
                    Label("Use Biometric", systemImage: "faceid")
                }
                .buttonStyle(.bordered)
            }
        }
    }
    
    private var unlockSection: some View {
        VStack(spacing: 20) {
            SecureField("Password", text: $password)
                .textFieldStyle(.roundedBorder)
                .disableAutocorrection(true)
            
            if biometricAuth.isAvailable() {
                Button(action: authenticateWithBiometrics) {
                    Label("Use Biometric", systemImage: "faceid")
                }
                .buttonStyle(.bordered)
            }
        }
    }
    
    private var errorMessageSection: some View {
        Group {
            if let error = errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
            }
        }
    }
    
    private var actionButton: some View {
        Button(action: handleAction) {
            Text(isSettingUp ? "Setup" : "Unlock")
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(password.isEmpty ? Color.gray : Color.blue)
                .cornerRadius(12)
        }
        .disabled(password.isEmpty)
    }
    
    private func handleAction() {
        errorMessage = nil
        
        if isSettingUp {
            if password != confirmPassword {
                errorMessage = "Passwords do not match"
                return
            }
            
            if password.count < 6 {
                errorMessage = "Password must be at least 6 characters"
                return
            }
            
            setupPassword()
        } else {
            verifyPassword()
        }
    }
    
    private func setupPassword() {
        do {
            let salt = try ServiceLocator.shared.cryptoEngine.generateRandomBytes(count: 32)
            let key = try keyManager.deriveKeyFromPassword(password, salt: salt)
            try keyManager.storeKey(key, identifier: "masterKey")
            
            appState.unlock()
        } catch {
            errorMessage = "Setup failed: \(error.localizedDescription)"
        }
    }
    
    private func verifyPassword() {
        do {
            let storedKey = try keyManager.retrieveKey(identifier: "masterKey")
            
            if let saltKey = try? keyManager.retrieveKey(identifier: "salt") {
                let saltData = saltKey.withUnsafeBytes { Data($0) }
                if let derivedKey = try? keyManager.deriveKeyFromPassword(password, salt: saltData) {
                    let storedKeyData = storedKey.withUnsafeBytes { Data($0) }
                    let derivedKeyData = derivedKey.withUnsafeBytes { Data($0) }
                    
                    if storedKeyData == derivedKeyData {
                        appState.unlock()
                        return
                    }
                }
            }
            
            errorMessage = "Incorrect password"
        } catch {
            errorMessage = "Verification failed: \(error.localizedDescription)"
        }
    }
    
    private func authenticateWithBiometrics() {
        Task {
            do {
                let success = try await biometricAuth.authenticate(
                    reason: "Unlock PrivaNote"
                )
                
                if success {
                    appState.unlock()
                }
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}

#Preview {
    UnlockView()
        .environmentObject(AppState())
}
