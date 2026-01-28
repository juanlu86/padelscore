import SwiftUI
import PadelCore

struct MatchSettingsView: View {
    @Bindable var viewModel: MatchViewModel
    let onStart: () -> Void
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                List {
                    SettingsCard(
                        title: "STANDARD",
                        description: "Normal deuce.",
                        system: .standard,
                        current: viewModel.state.scoringSystem
                    ) {
                        viewModel.state.scoringSystem = .standard
                    }
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 2, leading: 4, bottom: 2, trailing: 4))
                    
                    SettingsCard(
                        title: "GOLDEN PT",
                        description: "Sudden death.",
                        system: .goldenPoint,
                        current: viewModel.state.scoringSystem
                    ) {
                        viewModel.state.scoringSystem = .goldenPoint
                    }
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 2, leading: 4, bottom: 2, trailing: 4))
                    
                    SettingsCard(
                        title: "STAR POINT",
                        description: "Sudden death at 3rd deuce.",
                        system: .starPoint,
                        current: viewModel.state.scoringSystem
                    ) {
                        viewModel.state.scoringSystem = .starPoint
                    }
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 2, leading: 4, bottom: 2, trailing: 4))
                }
                .listStyle(.plain)
                
                // Slim Bottom Controls
                VStack(spacing: 2) {
                    Toggle(isOn: $viewModel.state.useTieBreak) {
                        Text("TIE-BREAK")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .tint(.yellow)
                    .scaleEffect(0.9)
                    .padding(.horizontal, 8)
                    
                    Button(action: onStart) {
                        Text("START MATCH")
                            .font(.system(size: 13, weight: .black, design: .rounded))
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(Color.yellow.gradient)
                            .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 6)
                }
                .padding(.bottom, 0)
            }
        }
        .preferredColorScheme(.dark)
    }
}

struct SettingsCard: View {
    let title: String
    let description: String
    let system: ScoringSystem
    let current: ScoringSystem
    let action: () -> Void
    
    var isSelected: Bool { system == current }
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(title)
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    Spacer()
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.yellow)
                    }
                }
                
                Text(description)
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.5))
                    .lineLimit(1)
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 10)
            .background(isSelected ? Color.yellow.opacity(0.12) : Color.white.opacity(0.06))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.yellow : Color.clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    MatchSettingsView(viewModel: MatchViewModel(), onStart: {})
}
