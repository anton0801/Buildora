import SwiftUI

struct SplashView: View {
    @State private var showBlock1 = false
    @State private var showBlock2 = false
    @State private var showBlock3 = false
    @State private var showBlock4 = false
    @State private var showBlock5 = false
    @State private var showLogo = false
    @State private var showTagline = false
    @State private var circleScale: CGFloat = 0.1
    @State private var bgOpacity: Double = 0

    var body: some View {
        ZStack {
            // Background
            Color.bBG
                .ignoresSafeArea()
                .opacity(bgOpacity)

            // Decorative circles
            Circle()
                .fill(Color.bYellow.opacity(0.15))
                .frame(width: 300, height: 300)
                .offset(x: -100, y: -200)
                .scaleEffect(circleScale)

            Circle()
                .fill(Color.bOrange.opacity(0.1))
                .frame(width: 200, height: 200)
                .offset(x: 120, y: 250)
                .scaleEffect(circleScale)

            Circle()
                .fill(Color.bTeal.opacity(0.12))
                .frame(width: 150, height: 150)
                .offset(x: -80, y: 280)
                .scaleEffect(circleScale)

            VStack(spacing: 32) {
                // Tower of blocks
                VStack(spacing: 3) {
                    // Block 5 (top)
                    buildingBlock(color: .bRed, width: 50, delay: 0.1, show: $showBlock5)
                    // Block 4
                    buildingBlock(color: .bOrange, width: 60, delay: 0.3, show: $showBlock4)
                    // Block 3
                    buildingBlock(color: .bYellow, width: 70, delay: 0.5, show: $showBlock3)
                    // Block 2
                    buildingBlock(color: .bTeal, width: 80, delay: 0.7, show: $showBlock2)
                    // Block 1 (bottom)
                    buildingBlock(color: .bBlue, width: 90, delay: 0.9, show: $showBlock1)
                }

                // Logo text
                VStack(spacing: 8) {
                    Text("Buildora")
                        .font(.system(size: 42, weight: .black, design: .rounded))
                        .foregroundColor(.bNavy)
                        .opacity(showLogo ? 1 : 0)
                        .scaleEffect(showLogo ? 1 : 0.7)

                    Text("Plan repairs step by step")
                        .font(.bSubhead())
                        .foregroundColor(.bNavy.opacity(0.6))
                        .opacity(showTagline ? 1 : 0)
                        .offset(y: showTagline ? 0 : 10)
                }
            }
        }
        .onAppear { startAnimation() }
    }

    private func buildingBlock(color: Color, width: CGFloat, delay: Double, show: Binding<Bool>) -> some View {
        RoundedRectangle(cornerRadius: 10)
            .fill(color)
            .frame(width: width, height: 26)
            .shadow(color: color.opacity(0.4), radius: 6, y: 4)
            .offset(y: show.wrappedValue ? 0 : -30)
            .opacity(show.wrappedValue ? 1 : 0)
    }

    private func startAnimation() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            bgOpacity = 1
            circleScale = 1
        }

        let blocks: [Binding<Bool>] = [$showBlock1, $showBlock2, $showBlock3, $showBlock4, $showBlock5]
        for (i, block) in blocks.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1 + Double(i) * 0.15) {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                    block.wrappedValue = true
                }
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                showLogo = true
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.3) {
            withAnimation(.easeOut(duration: 0.4)) {
                showTagline = true
            }
        }
    }
}

struct SplashView_Previews: PreviewProvider {
    static var previews: some View {
        SplashView()
    }
}
