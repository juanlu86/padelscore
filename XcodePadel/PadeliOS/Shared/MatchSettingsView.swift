import SwiftUI
import PadelCore

struct MatchSettingsView: View {
    @Bindable var viewModel: MatchViewModel
    let onStart: () -> Void
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            #if os(watchOS)
            TabView {
                // Page 1: Scoring System
                VStack(spacing: 0) {
                    Text("SYSTEM")
                        .font(.system(size: 10, weight: .black, design: .rounded))
                        .foregroundColor(.yellow)
                        .padding(.top, 4)
                    pickerSection
                }
                .tag(0)
                
                // Page 2: Serving & Ruels
                VStack(spacing: 4) {
                    servingSection
                        .padding(.top, 8)
                    
                    tieBreakToggle
                    
                    Spacer()
                    
                    startButton
                }
                .tag(1)
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            #else
            VStack(spacing: 24) {
                Text("MATCH SETUP")
                    .font(.system(size: 14, weight: .black, design: .rounded))
                    .foregroundColor(.yellow)
                    .padding(.top, 12)
                
                pickerSection
                    .frame(height: 180)
                
                VStack(spacing: 16) {
                    servingSection
                    tieBreakToggle
                    startButton
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 20)
            }
            #endif
        }
        .preferredColorScheme(.dark)
    }
    
    private var servingSection: some View {
        HStack {
            Text(platformLabel("WHO SERVES?"))
                .font(.system(size: platformValue(watch: 11, ios: 13), weight: .bold, design: .rounded))
                .foregroundColor(.white.opacity(0.9))
            
            Spacer()
            
            HStack(spacing: 0) {
                Button(action: { viewModel.state.servingTeam = 1 }) {
                    Text(platformValue(watch: "T1", ios: "TEAM 1"))
                        .font(.system(size: platformValue(watch: 10, ios: 11), weight: .black))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(viewModel.state.servingTeam == 1 ? Color.yellow : Color.white.opacity(0.08))
                        .foregroundColor(viewModel.state.servingTeam == 1 ? .black : .white)
                }
                
                Button(action: { viewModel.state.servingTeam = 2 }) {
                    Text(platformValue(watch: "T2", ios: "TEAM 2"))
                        .font(.system(size: platformValue(watch: 10, ios: 11), weight: .black))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(viewModel.state.servingTeam == 2 ? Color.yellow : Color.white.opacity(0.08))
                        .foregroundColor(viewModel.state.servingTeam == 2 ? .black : .white)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }
    
    private var tieBreakToggle: some View {
        HStack {
            Text("TIE-BREAK")
                .font(.system(size: platformValue(watch: 11, ios: 13), weight: .bold, design: .rounded))
                .foregroundColor(.white.opacity(0.9))
            
            Spacer()
            
            Toggle("", isOn: $viewModel.state.useTieBreak)
                .labelsHidden()
                .tint(.yellow)
                .scaleEffect(platformValue(watch: 0.9, ios: 1.0))
        }
    }
    
    private var startButton: some View {
        Button(action: onStart) {
            Text("START MATCH")
                .font(.system(size: platformValue(watch: 13, ios: 16), weight: .black, design: .rounded))
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, platformValue(watch: 8, ios: 12))
                .background(Color.yellow.gradient)
                .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
    
    private var pickerSection: some View {
        GeometryReader { proxy in
            let center = proxy.size.height / 2
            
            ZStack {
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 8) {
                        Color.clear.frame(height: center - 25)
                        
                        ForEach(ScoringSystem.allCases, id: \.self) { system in
                            pickerRow(for: system, in: center)
                        }
                        
                        Color.clear.frame(height: center - 25)
                    }
                    .scrollTargetLayout()
                }
                .scrollTargetBehavior(.viewAligned)
                .scrollPosition(id: Binding(
                    get: { viewModel.state.scoringSystem },
                    set: { if let s = $0, viewModel.state.scoringSystem != s {
                        viewModel.state.scoringSystem = s 
                    }}
                ))
                .coordinateSpace(name: "picker")
            }
        }
        .frame(maxHeight: .infinity)
    }
    
    private func pickerRow(for system: ScoringSystem, in center: CGFloat) -> some View {
        SettingsCard(
            title: system.rawValue.uppercased(),
            description: systemDescription(for: system),
            system: system,
            current: viewModel.state.scoringSystem
        ) {
            withAnimation(.spring(duration: 0.3)) {
                viewModel.state.scoringSystem = system
            }
        }
        .frame(height: 50)
        .visualEffect { content, proxy in
            let midY = proxy.frame(in: .named("picker")).midY
            let verticalDiff = abs(midY - center)
            let scale = max(0.9, 1.15 - (verticalDiff / 300))
            let opacity = max(0.5, 1.0 - (verticalDiff / 150))
            
            return content
                .scaleEffect(scale)
                .opacity(opacity)
        }
    }

    private func platformValue<T>(watch: T, ios: T) -> T {
        #if os(watchOS)
        return watch
        #else
        return ios
        #endif
    }

    private func platformLabel(_ text: String) -> String {
        #if os(watchOS)
        return text.replacingOccurrences(of: "WHO SERVES?", with: "SERVES:")
        #else
        return text
        #endif
    }
    
    private func systemDescription(for system: ScoringSystem) -> String {
        switch system {
        case .standard: return "Standard rules."
        case .goldenPoint: return "Sudden death 40-40."
        case .starPoint: return "3rd deuce finish."
        }
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
