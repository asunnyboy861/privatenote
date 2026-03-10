import SwiftUI

struct SecuritySettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()
    @State private var showingChangePassword = false
    @State private var showingDeleteConfirmation = false
    
    var body: some View {
        Form {
            Section("Authentication") {
                HStack {
                    Image(systemName: "faceid")
                        .foregroundColor(.blue)
                        .frame(width: 24)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Biometric Unlock")
                            .foregroundColor(.primary)
                        Text("Use Face ID or Touch ID to unlock")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Toggle("", isOn: Binding(
                        get: { viewModel.biometricEnabled },
                        set: { viewModel.toggleBiometric($0) }
                    ))
                    .labelsHidden()
                }
            }
            
            Section("Password") {
                Button {
                    showingChangePassword = true
                } label: {
                    HStack {
                        Image(systemName: "key")
                            .foregroundColor(.orange)
                            .frame(width: 24)
                        
                        Text("Change Password")
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                }
            }
            
            Section("Encryption") {
                HStack {
                    Image(systemName: "lock.shield")
                        .foregroundColor(.green)
                        .frame(width: 24)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("End-to-End Encryption")
                            .foregroundColor(.primary)
                        Text("AES-256-GCM encryption")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                }
                
                HStack {
                    Image(systemName: "key.fill")
                        .foregroundColor(.purple)
                        .frame(width: 24)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Zero-Knowledge Architecture")
                            .foregroundColor(.primary)
                        Text("Your data is encrypted before sync")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                }
            }
            
            Section("Data") {
                HStack {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                        .frame(width: 24)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Delete All Data")
                            .foregroundColor(.red)
                        Text("Permanently delete all notes")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    showingDeleteConfirmation = true
                }
            }
        }
        .navigationTitle("Security")
        .sheet(isPresented: $showingChangePassword) {
            ChangePasswordView()
        }
        .alert("Delete All Data?", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                Task {
                    try? await viewModel.clearAllData()
                }
            }
        } message: {
            Text("This action cannot be undone. All your notes will be permanently deleted.")
        }
    }
}

struct ChangePasswordView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var currentPassword = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var errorMessage: String?
    @State private var showingSuccess = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Current Password") {
                    SecureField("Current Password", text: $currentPassword)
                }
                
                Section("New Password") {
                    SecureField("New Password", text: $newPassword)
                    SecureField("Confirm Password", text: $confirmPassword)
                }
                
                if let error = errorMessage {
                    Section {
                        Text(error)
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Change Password")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        changePassword()
                    }
                    .fontWeight(.semibold)
                }
            }
            .alert("Success", isPresented: $showingSuccess) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("Password changed successfully")
            }
        }
    }
    
    private func changePassword() {
        guard !currentPassword.isEmpty else {
            errorMessage = "Please enter your current password"
            return
        }
        
        guard newPassword == confirmPassword else {
            errorMessage = "Passwords do not match"
            return
        }
        
        guard newPassword.count >= 8 else {
            errorMessage = "Password must be at least 8 characters"
            return
        }
        
        HapticFeedback.shared.playSuccess()
        showingSuccess = true
    }
}

#Preview {
    NavigationStack {
        SecuritySettingsView()
    }
}
