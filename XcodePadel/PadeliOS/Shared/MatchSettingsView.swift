import SwiftUI
import PadelCore

struct MatchSettingsView: View {
    @Bindable var viewModel: MatchViewModel
    let onStart: () -> Void
    var onClose: (() -> Void)? = nil
    
    @State private var showingScanner = false
    @State private var manualCodeLocal = ""
    
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
                
                // Page 2: Serving & Rules
                VStack(spacing: 12) { // Increased spacing to avoid "touching"
                    servingSection
                        .padding(.top, 10)
                    
                    tieBreakToggle
                        .padding(.top, 4) // Extra breathing room
                    
                    grandSlamToggle
                        .padding(.top, 4)
                    
                    Spacer()
                    
                    startButton
                }
                .tag(1)
                .padding(.horizontal, 8)
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            #else
            VStack(spacing: 32) { // Increased for iPhone too
                HStack {
                    if let onClose = onClose {
                        Button(action: onClose) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.white.opacity(0.3))
                        }
                        .padding(.leading, 20)
                    } else {
                        Spacer().frame(width: 44)
                    }
                    
                    Spacer()
                    
                    Text(viewModel.isMatchStarted ? "ADMIN SETTINGS" : "MATCH SETUP")
                        .font(.system(size: 16, weight: .black, design: .rounded))
                        .foregroundColor(.yellow)
                    
                    Spacer()
                    
                    #if !os(watchOS)
                    Button(action: { showingScanner = true }) {
                        Image(systemName: "qrcode.viewfinder")
                            .font(.system(size: 20))
                            .foregroundColor(.yellow)
                    }
                    .padding(.trailing, 20)
                    #else
                    Spacer().frame(width: 44)
                    #endif
                }
                .padding(.top, 20)
                
                pickerSection
                    .frame(height: 180)
                
                teamSection
                
                #if !os(watchOS)
                courtConnectionSection
                #endif
                
                VStack(spacing: 24) { // Increased for iPhone
                    servingSection
                    tieBreakToggle
                    grandSlamToggle
                    startButton
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 30)
            }
            .sheet(isPresented: $showingScanner) {
                #if !os(watchOS)
                QRScannerView { result in
                    if result.hasPrefix("padelscore:link:") {
                        let id = result.replacingOccurrences(of: "padelscore:link:", with: "")
                        viewModel.linkedCourtId = id
                        showingScanner = false
                    }
                } onCancel: {
                    showingScanner = false
                }
                #endif
            }
            #endif
        }
        .preferredColorScheme(.dark)
    }
    
    private var servingSection: some View {
        HStack {
            Text(platformLabel("WHO SERVES?"))
                .font(.system(size: platformValue(watch: 11, ios: 14), weight: .bold, design: .rounded))
                .foregroundColor(.white.opacity(0.9))
            
            Spacer()
            
            HStack(spacing: 4) {
                servingButton(team: 1, label: platformValue(watch: "T1", ios: "TEAM 1"))
                servingButton(team: 2, label: platformValue(watch: "T2", ios: "TEAM 2"))
            }
            .padding(3)
            .background(Color.white.opacity(0.08))
            .clipShape(Capsule())
        }
    }

    private func servingButton(team: Int, label: String) -> some View {
        Button(action: {
            withAnimation(.spring(duration: 0.2)) {
                viewModel.state.servingTeam = team
            }
        }) {
            Text(label)
                .font(.system(size: platformValue(watch: 10, ios: 11), weight: .black, design: .rounded))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(viewModel.state.servingTeam == team ? Color.yellow : Color.clear)
                .foregroundColor(viewModel.state.servingTeam == team ? .black : .white.opacity(0.6))
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
    
    private var tieBreakToggle: some View {
        HStack {
            Text("TIE-BREAK")
                .font(.system(size: platformValue(watch: 11, ios: 14), weight: .bold, design: .rounded))
                .foregroundColor(.white.opacity(0.9))
            
            Spacer()
            
            Toggle("", isOn: $viewModel.state.useTieBreak)
                .labelsHidden()
                .tint(.yellow)
                .scaleEffect(platformValue(watch: 0.9, ios: 1.0))
                .disabled(viewModel.isMatchStarted)
                .opacity(viewModel.isMatchStarted ? 0.5 : 1.0)
        }
    }
    
    private var grandSlamToggle: some View {
        HStack {
            Text("GRAND SLAM")
                .font(.system(size: platformValue(watch: 11, ios: 14), weight: .bold, design: .rounded))
                .foregroundColor(.white.opacity(0.9))
            
            Spacer()
            
            Toggle("", isOn: $viewModel.state.isGrandSlam)
                .labelsHidden()
                .tint(.yellow)
                .scaleEffect(platformValue(watch: 0.9, ios: 1.0))
                .disabled(viewModel.isMatchStarted)
                .opacity(viewModel.isMatchStarted ? 0.5 : 1.0)
        }
    }
    
    private var teamSection: some View {
        VStack(alignment: .leading, spacing: platformValue(watch: 8, ios: 12)) {
            Text("TEAMS")
                .font(.system(size: platformValue(watch: 8, ios: 12), weight: .black, design: .rounded))
                .foregroundColor(.yellow)
            
            #if os(watchOS)
            VStack(spacing: 4) {
                teamTextField(placeholder: "T1", text: $viewModel.state.team1)
                teamTextField(placeholder: "T2", text: $viewModel.state.team2)
            }
            #else
            HStack(spacing: 12) {
                teamTextField(placeholder: "TEAM 1", text: $viewModel.state.team1)
                teamTextField(placeholder: "TEAM 2", text: $viewModel.state.team2)
            }
            #endif
        }
        .padding(.horizontal, platformValue(watch: 0, ios: 24))
    }
    
    private func teamTextField(placeholder: String, text: Binding<String>) -> some View {
        TextField(placeholder, text: text)
            .font(.system(size: platformValue(watch: 10, ios: 14), weight: .bold, design: .rounded))
            .padding(platformValue(watch: 6, ios: 12))
            .background(Color.white.opacity(0.06))
            .cornerRadius(platformValue(watch: 6, ios: 10))
            .overlay(
                RoundedRectangle(cornerRadius: platformValue(watch: 6, ios: 10))
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
            .submitLabel(.done)
    }
    
    private var startButton: some View {
        Button(action: onStart) {
            Text(viewModel.isMatchStarted ? "SAVE CHANGES" : "START MATCH")
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
        .disabled(viewModel.isMatchStarted)
        .opacity(viewModel.isMatchStarted ? 0.6 : 1.0)
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

    #if !os(watchOS)
    private var courtConnectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("CLOUD DASHBOARD")
                .font(.system(size: 12, weight: .black, design: .rounded))
                .foregroundColor(.yellow)
            
            VStack(spacing: 12) {
                if !viewModel.linkedCourtId.isEmpty {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("LINKED TO COURT")
                                .font(.system(size: 10, weight: .black, design: .rounded))
                                .foregroundColor(.white.opacity(0.4))
                            Text(viewModel.linkedCourtId.uppercased())
                                .font(.system(size: 14, weight: .black, design: .rounded))
                                .foregroundColor(.white)
                                .lineLimit(1)
                        }
                        Spacer()
                        Button(action: { 
                            Task {
                                await viewModel.unlinkCurrentCourt()
                            }
                        }) {
                            Image(systemName: "link.badge.plus")
                                .font(.system(size: 20))
                                .foregroundColor(.red.opacity(0.7))
                        }
                    }
                    .padding(16)
                    .background(Color.white.opacity(0.06))
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.yellow.opacity(0.3), lineWidth: 1)
                    )
                } else {
                    HStack(spacing: 12) {
                        Button(action: { showingScanner = true }) {
                            VStack(spacing: 6) {
                                Image(systemName: "qrcode.viewfinder")
                                    .font(.system(size: 24))
                                Text("SCAN TO PAIR")
                                    .font(.system(size: 10, weight: .black, design: .rounded))
                            }
                            .frame(width: 100, height: 80)
                            .background(Color.yellow)
                            .foregroundColor(.black)
                            .cornerRadius(16)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("OR ENTER 6-DIGIT CODE")
                                .font(.system(size: 10, weight: .black, design: .rounded))
                                .foregroundColor(.white.opacity(0.4))
                            
                            HStack {
                                TextField("ABC-123", text: $manualCodeLocal)
                                    .font(.system(size: 16, weight: .black, design: .monospaced))
                                    .padding(12)
                                    .background(Color.white.opacity(0.06))
                                    .cornerRadius(12)
                                    .submitLabel(.done)
                                    .onChange(of: manualCodeLocal) { oldValue, newValue in
                                        let filtered = String(newValue.uppercased().prefix(6))
                                        if filtered != newValue {
                                            manualCodeLocal = filtered
                                        }
                                        if filtered.count == 6 {
                                            viewModel.linkedCourtId = filtered
                                        }
                                    }
                            }
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 24)
    }
    #endif
    
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
