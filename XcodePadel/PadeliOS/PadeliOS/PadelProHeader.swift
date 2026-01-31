import SwiftUI

struct PadelProHeader: View {
    let syncStatus: SyncService.Status
    let linkedCourtId: String
    let onEdit: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("PADELSCORE PRO")
                    .font(.system(size: 10, weight: .black))
                    .tracking(2)
                    .foregroundColor(.zinc400)
                
                HStack(spacing: 6) {
                    Circle()
                        .fill(statusColor)
                        .frame(width: 6, height: 6)
                        .shadow(color: statusColor.opacity(0.5), radius: 2)
                    
                    Text(statusLabel)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.zinc500)
                }
            }
            
            Spacer()
            
            HStack(spacing: 12) {
                syncBadge
                
                Button(action: onEdit) {
                    Text(!linkedCourtId.isEmpty ? "COURT \(linkedCourtId)" : "LOCAL MATCH")
                        .font(.system(size: 8, weight: .black))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.white.opacity(0.05))
                        .clipShape(Capsule())
                        .foregroundColor(.yellow)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 12)
    }
    
    private var statusColor: Color {
        if case .failed = syncStatus { return .red }
        return .yellow
    }
    
    private var statusLabel: String {
        if case .failed = syncStatus { return "SYNC ERROR" }
        return "LIVE FROM COURT"
    }
    
    private var syncBadge: some View {
        Group {
            switch syncStatus {
            case .idle:
                Image(systemName: "cloud")
                    .font(.system(size: 12))
                    .foregroundColor(.zinc500)
            case .syncing:
                ProgressView()
                    .controlSize(.small)
                    .tint(.yellow)
            case .synced:
                Image(systemName: "cloud.checkmark.fill")
                    .font(.system(size: 12))
                    .foregroundColor(.green)
            case .failed(_):
                Image(systemName: "cloud.badge.exclamationmark.fill")
                    .font(.system(size: 12))
                    .foregroundColor(.red)
            }
        }
    }
}
