import SwiftUI
import PadelCore

struct MatchSettingsView: View {
    @Bindable var viewModel: MatchViewModel
    let onStart: () -> Void
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                VStack(spacing: 4) {
                    Text("MATCH SETTINGS")
                        .font(.system(.subheadline, design: .rounded, weight: .black))
                        .foregroundColor(.yellow)
                    
                    Text("Select Scoring System")
                        .font(.system(size: 10))
                        .foregroundColor(.white.opacity(0.8))
                }
                .padding(.top, 10)
                .padding(.bottom, 8)
                
                List {
                    SettingsCard(
                        title: "STANDARD",
                        description: "Normal deuce/advantage.",
                        system: .standard,
                        current: viewModel.state.scoringSystem
                    ) {
                        viewModel.state.scoringSystem = .standard
                    }
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8))
                    
                    SettingsCard(
                        title: "GOLDEN POINT",
                        description: "Sudden death at 40-40.",
                        system: .goldenPoint,
                        current: viewModel.state.scoringSystem
                    ) {
                        viewModel.state.scoringSystem = .goldenPoint
                    }
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8))
                    
                    SettingsCard(
                        title: "STAR POINT",
                        description: "Match ends at 3rd deuce.",
                        system: .starPoint,
                        current: viewModel.state.scoringSystem
                    ) {
                        viewModel.state.scoringSystem = .starPoint
                    }
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8))
                }
                .listStyle(.plain)
                
                Button(action: onStart) {
                    Text("START MATCH")
                        .font(.system(.headline, design: .rounded, weight: .bold))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.yellow.gradient)
                        .cornerRadius(12)
                }
                .padding(.horizontal, 10)
                .padding(.bottom, 10)
            }
        }
        .preferredColorScheme(.dark) // Force dark mode for this view
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
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(title)
                        .font(.system(.headline, design: .rounded, weight: .bold))
                        .foregroundColor(.white)
                    Spacer()
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.yellow)
                    }
                }
                
                Text(description)
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.6))
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(isSelected ? Color.yellow.opacity(0.15) : Color.white.opacity(0.08))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.yellow : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    MatchSettingsView(viewModel: MatchViewModel(), onStart: {})
}
