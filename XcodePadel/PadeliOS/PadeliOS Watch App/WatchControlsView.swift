import SwiftUI

struct WatchControlsView: View {
    @Bindable var viewModel: MatchViewModel
    
    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                Text("Match Controls")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                ControlRow(title: "Undo Last", icon: "arrow.uturn.backward", color: .orange) {
                    viewModel.undoPoint()
                }
                .disabled(!viewModel.canUndo)
                
                ControlRow(title: "Reset Match", icon: "arrow.counterclockwise", color: .red) {
                    viewModel.resetMatch()
                }
                
                ControlRow(title: "Finish Match", icon: "checkmark.circle.fill", color: .green) {
                    viewModel.finishMatch()
                }
            }
            .padding(.horizontal)
        }
    }
}

struct ControlRow: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                Text(title)
                Spacer()
            }
            .padding()
            .background(color.opacity(0.2))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}
