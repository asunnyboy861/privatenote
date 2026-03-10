import SwiftUI

struct ErrorAlertView: View {
    let error: UserFacingError
    let onDismiss: () -> Void
    let onRetry: (() -> Void)?
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: error.icon)
                .font(.system(size: 60))
                .foregroundColor(.orange)
            
            Text(error.errorDescription ?? "Error")
                .font(.title2)
                .fontWeight(.bold)
            
            if let suggestion = error.recoverySuggestion {
                Text(suggestion)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            HStack(spacing: 16) {
                Button("Dismiss") {
                    onDismiss()
                }
                .font(.headline)
                .padding(.horizontal, 24)
                .padding(.vertical, 10)
                .background(Color.gray.opacity(0.2))
                .foregroundColor(.primary)
                .cornerRadius(8)
                
                if let onRetry = onRetry {
                    Button("Retry") {
                        onRetry()
                    }
                    .font(.headline)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 10)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
            }
        }
        .padding(30)
        #if os(iOS)
        .background(Color(uiColor: .systemBackground))
        #elseif os(macOS)
        .background(Color(nsColor: .windowBackgroundColor))
        #endif
        .cornerRadius(16)
        .shadow(radius: 10)
    }
}

#Preview {
    ErrorAlertView(
        error: .syncFailed,
        onDismiss: { print("Dismissed") },
        onRetry: { print("Retrying") }
    )
}
