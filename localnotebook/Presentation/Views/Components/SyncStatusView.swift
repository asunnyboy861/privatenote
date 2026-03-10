import SwiftUI

struct SyncStatusView: View {
    @ObservedObject var syncEngine: SyncEngine
    
    var body: some View {
        HStack(spacing: 8) {
            statusIcon
            
            statusText
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(backgroundColor)
        .cornerRadius(8)
        .onTapGesture {
            handleTap()
        }
    }
    
    private var statusIcon: some View {
        Group {
            if syncEngine.isSyncing {
                ProgressView()
                    .scaleEffect(0.7)
                    .frame(width: 16, height: 16)
            } else if syncEngine.lastSyncError != nil {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                    .font(.system(size: 14))
            } else if syncEngine.lastSyncDate != nil {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.system(size: 16))
            } else {
                Image(systemName: "cloud.fill")
                    .foregroundColor(.gray)
                    .font(.system(size: 16))
            }
        }
    }
    
    private var statusText: some View {
        Text(statusTextValue)
            .font(.caption2)
            .foregroundColor(.secondary)
    }
    
    private var statusTextValue: String {
        if syncEngine.isSyncing {
            return "Syncing..."
        } else if syncEngine.lastSyncError != nil {
            return "Sync Error"
        } else if let lastSync = syncEngine.lastSyncDate {
            return "Synced \(lastSync.timeAgo())"
        } else {
            return "Not Synced"
        }
    }
    
    private var backgroundColor: Color {
        if syncEngine.lastSyncError != nil {
            return Color.orange.opacity(0.1)
        } else {
            return Color.gray.opacity(0.1)
        }
    }
    
    private func handleTap() {
        if syncEngine.lastSyncError != nil {
            Task {
                try? await syncEngine.syncAll()
            }
        }
    }
}

#Preview {
    SyncStatusView(syncEngine: SyncEngine())
}
