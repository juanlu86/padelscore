import SwiftUI

struct SpecialPointIndicator: View {
    let label: String
    @State private var pulseScale: CGFloat = 1.0
    @State private var glowOpacity: Double = 0.3
    
    var body: some View {
        Text(label)
            .font(.system(size: 14, weight: .black, design: .rounded))
            .tracking(2.0)
            .foregroundColor(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 8)
            .background {
                ZStack {
                    Capsule()
                        .fill(themeColor)
                        .blur(radius: 12)
                        .opacity(glowOpacity)
                        .scaleEffect(pulseScale * 1.3)
                    
                    Capsule()
                        .fill(.ultraThinMaterial)
                    
                    Capsule()
                        .strokeBorder(themeColor.opacity(0.6), lineWidth: 1)
                }
            }
            .scaleEffect(pulseScale)
            .shadow(color: .black.opacity(0.3), radius: 10, y: 5)
            .onAppear {
                withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                    pulseScale = 1.05
                    glowOpacity = 0.6
                }
            }
            .transition(.asymmetric(
                insertion: .move(edge: .top).combined(with: .opacity).combined(with: .scale(scale: 0.8)),
                removal: .opacity.combined(with: .scale(scale: 0.5))
            ))
    }
    
    private var themeColor: Color {
        label.contains("STAR") ? .orange : .yellow
    }
}
