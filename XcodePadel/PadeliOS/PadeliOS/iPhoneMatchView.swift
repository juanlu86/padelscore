import SwiftUI
import PadelCore

struct iPhoneMatchView: View {
    @State var viewModel = MatchViewModel()
    @State private var showingSettings = false
    private let haptics = UISelectionFeedbackGenerator()
    private let impact = UIImpactFeedbackGenerator(style: .medium)
    
    var body: some View {
        @Bindable var viewModel = viewModel
        NavigationStack {
            ZStack {
                // Background Gradient
                Color.black.ignoresSafeArea()
                
                // Dynamic Background Flare
                RadialGradient(
                    colors: [viewModel.state.isMatchOver ? (calculateTeamWinner() == 1 ? .green.opacity(0.15) : .blue.opacity(0.15)) : .yellow.opacity(0.1), .clear],
                    center: .center,
                    startRadius: 0,
                    endRadius: 400
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // PadelPro Header
                    PadelProHeader(
                        syncStatus: viewModel.syncStatus,
                        linkedCourtId: viewModel.linkedCourtId
                    ) {
                        withAnimation(.spring()) {
                            showingSettings = true
                        }
                    }
                        .padding(.horizontal)
                        .padding(.top, 8)
                    
                    if let label = viewModel.specialPointLabel {
                        SpecialPointIndicator(label: label)
                            .padding(.bottom, 16)
                            .transition(.move(edge: .top).combined(with: .opacity))
                    }
                    
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 32) {
                            // Primary Score Board
                            MatchScoreBoard(viewModel: viewModel, impact: impact)
                            
                            // Quick Controls
                            VStack(alignment: .leading, spacing: 16) {
                                Text("QUICK ACTIONS")
                                    .font(.system(size: 10, weight: .black))
                                    .tracking(2)
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal, 8)
                                
                                HStack(spacing: 12) {
                                    ProActionButton(title: "RESET", icon: "arrow.counterclockwise", color: .red) {
                                        haptics.selectionChanged()
                                        viewModel.resetMatch()
                                    }
                                    
                                    ProActionButton(title: "UNDO", icon: "arrow.uturn.backward", color: .orange) {
                                        haptics.selectionChanged()
                                        viewModel.undoPoint()
                                    }
                                    .disabled(!viewModel.canUndo)
                                    .opacity(viewModel.canUndo ? 1.0 : 0.3)
                                    
                                    ProActionButton(title: "FINISH", icon: "checkmark.circle", color: .green) {
                                        impact.impactOccurred(intensity: 1.0)
                                        viewModel.finishMatch()
                                    }
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
            .toolbar(.hidden) // We use our custom header
            .alert("Sync Failed", isPresented: Binding(
                get: { if case .failed = viewModel.syncStatus { return true } else { return false } },
                set: { if !$0 { SyncService.shared.status = .idle } }
            )) {
                Button("OK", role: .cancel) { }
            } message: {
                if case .failed(let error) = viewModel.syncStatus {
                    Text(error.localizedDescription)
                }
            }
            
            // Settings Overlay
            if !viewModel.isMatchStarted || showingSettings {
                MatchSettingsView(viewModel: viewModel, onStart: {
                    withAnimation(.spring()) {
                        impact.impactOccurred()
                        if !viewModel.isMatchStarted {
                            viewModel.startMatch()
                        } else {
                            // If mid-match, just save/sync names
                            viewModel.updateTeamNames(team1: viewModel.state.team1, team2: viewModel.state.team2)
                        }
                        showingSettings = false
                    }
                }, onClose: {
                    withAnimation(.spring()) {
                        showingSettings = false
                    }
                })
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .zIndex(1)
            }
        }
        .fullScreenCover(isPresented: .init(
            get: { viewModel.state.isMatchOver },
            set: { if !$0 && viewModel.state.isMatchOver { viewModel.resetMatch() } }
        )) {
            MatchSummaryView(
                state: viewModel.state,
                onUndo: { viewModel.undoPoint() },
                onDismiss: { viewModel.resetMatch() }
            )
        }
    }
    
    private func calculateTeamWinner() -> Int {
        let t1Sets = viewModel.state.team1Sets
        let t2Sets = viewModel.state.team2Sets
        if t1Sets > t2Sets { return 1 }
        if t2Sets > t1Sets { return 2 }
        return 0
    }
}

#Preview {
    iPhoneMatchView()
        .preferredColorScheme(.dark)
}
