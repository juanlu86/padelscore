import SwiftUI
import PadelCore

struct GlassScoreCard: View {
    let name: String
    let score: String
    let games: Int
    let sets: Int
    let isServing: Bool
    let hasWon: Bool
    let color: Color
    let onTap: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Button(action: onTap) {
                ZStack {
                    // Glass Background
                    Circle()
                        .fill(.white.opacity(0.05))
                        .frame(width: 140, height: 140)
                        .overlay(
                            Circle()
                                .stroke(.white.opacity(0.1), lineWidth: 1)
                        )
                        .overlay {
                            // Inner Glow if serving
                            if isServing {
                                Circle()
                                    .stroke(color.opacity(0.3), lineWidth: 4)
                                    .blur(radius: 4)
                            }
                        }
                    
                    // Score Text
                    Text(score)
                        .font(.system(size: score == "AD" ? 44 : 64, weight: .black, design: .rounded))
                        .foregroundColor(isServing ? .white : .white.opacity(0.7))
                        .minimumScaleFactor(0.4)
                        .lineLimit(1)
                        .shadow(color: .black.opacity(0.3), radius: 5, y: 5)
                }
                .overlay(alignment: .topTrailing) {
                    // Ball Indicator
                    if isServing {
                        Circle()
                            .fill(.yellow)
                            .frame(width: 24, height: 24)
                            .overlay(
                                Circle().stroke(.black, lineWidth: 5)
                            )
                            .shadow(color: .yellow.opacity(0.5), radius: 8)
                            .offset(x: -8, y: 8)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
            }
            .buttonStyle(ScoreButtonStyle())
            
            VStack(spacing: 6) {
                Text(name.isEmpty ? "TEAM" : name.uppercased())
                    .font(.system(size: 12, weight: .black))
                    .foregroundColor(isServing || hasWon ? .white : .zinc500)
                    .multilineTextAlignment(.center)
                    .lineLimit(1)
                
                if hasWon {
                    Text("WINNER")
                        .font(.system(size: 8, weight: .black))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(.yellow)
                        .foregroundColor(.black)
                        .clipShape(Capsule())
                } else {
                    HStack(spacing: 8) {
                        setGameBadge(label: "S", value: sets)
                        setGameBadge(label: "G", value: games)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: isServing)
    }
    
    private func setGameBadge(label: String, value: Int) -> some View {
        HStack(spacing: 2) {
            Text(label)
                .font(.system(size: 7, weight: .black))
                .foregroundColor(.zinc500)
            Text("\(value)")
                .font(.system(size: 9, weight: .black, design: .monospaced))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(.white.opacity(0.05))
        .clipShape(Capsule())
    }
}

struct ScoreButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.92 : 1.0)
            .animation(.interactiveSpring(), value: configuration.isPressed)
    }
}
