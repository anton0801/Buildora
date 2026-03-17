import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var appState: AppState
    @State private var currentPage = 0
    @State private var animateContent = false

    var body: some View {
        ZStack {
            Color.bBG.ignoresSafeArea()

            VStack(spacing: 0) {
                // Page content
                TabView(selection: $currentPage) {
                    OnboardingPage1(animate: $animateContent).tag(0)
                    OnboardingPage2(animate: $animateContent).tag(1)
                    OnboardingPage3(animate: $animateContent).tag(2)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: currentPage)

                // Bottom controls
                VStack(spacing: 20) {
                    // Dot indicators
                    HStack(spacing: 8) {
                        ForEach(0..<3, id: \.self) { i in
                            Capsule()
                                .fill(i == currentPage ? Color.bOrange : Color.bGrayBeige)
                                .frame(width: i == currentPage ? 24 : 8, height: 8)
                                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: currentPage)
                        }
                    }

                    // Buttons
                    HStack(spacing: 12) {
                        if currentPage < 2 {
                            Button("Skip") {
                                finishOnboarding()
                            }
                            .buttonStyle(BuildoraSecondaryButtonStyle())

                            Button("Next") {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                    currentPage += 1
                                    animateContent = false
                                }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                                        animateContent = true
                                    }
                                }
                            }
                            .buttonStyle(BuildoraPrimaryButtonStyle())
                        } else {
                            Button("Get Started") {
                                finishOnboarding()
                            }
                            .buttonStyle(BuildoraPrimaryButtonStyle())
                        }
                    }
                    .padding(.horizontal, 24)
                }
                .padding(.bottom, 48)
                .padding(.top, 16)
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    animateContent = true
                }
            }
        }
    }

    private func finishOnboarding() {
        withAnimation(.easeInOut(duration: 0.4)) {
            appState.hasCompletedOnboarding = true
        }
    }
}

// MARK: - Page 1: Organize every room

struct OnboardingPage1: View {
    @Binding var animate: Bool
    @State private var selectedRoom = 0
    let rooms = [("Kitchen", "fork.knife", Color.bOrange), ("Bathroom", "drop", Color.bBlue), ("Bedroom", "bed.double", Color.bTeal)]

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // Illustration: Room cards
            VStack(spacing: 12) {
                ForEach(rooms.indices, id: \.self) { i in
                    let (name, icon, color) = rooms[i]
                    HStack(spacing: 14) {
                        Image(systemName: icon)
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 48, height: 48)
                            .background(color)
                            .cornerRadius(14)

                        Text(name)
                            .font(.bSubhead())
                            .foregroundColor(.bNavy)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.bNavy.opacity(0.3))
                    }
                    .padding(16)
                    .background(Color.white)
                    .cornerRadius(18)
                    .bShadow(0.08)
                    .offset(x: animate ? 0 : 60)
                    .opacity(animate ? 1 : 0)
                    .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(Double(i) * 0.1), value: animate)
                    .onTapGesture {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { selectedRoom = i }
                    }
                }
            }
            .padding(.horizontal, 32)

            // Text
            VStack(spacing: 12) {
                Text("Organize every room")
                    .font(.bTitle())
                    .foregroundColor(.bNavy)
                    .multilineTextAlignment(.center)
                    .opacity(animate ? 1 : 0)
                    .offset(y: animate ? 0 : 20)
                    .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.3), value: animate)

                Text("Create separate plans for each room and track progress clearly.")
                    .font(.bBody())
                    .foregroundColor(.bNavy.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .opacity(animate ? 1 : 0)
                    .offset(y: animate ? 0 : 10)
                    .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.4), value: animate)
            }

            Spacer()
        }
    }
}

// MARK: - Page 2: Track tasks and materials

struct OnboardingPage2: View {
    @Binding var animate: Bool
    @State private var checkedItems: Set<Int> = []

    let items = [
        ("Install new floor tiles", "square.on.square.fill", Color.bBlue),
        ("Buy paint for walls", "paintbrush.fill", Color.bRed),
        ("Order lighting fixtures", "lightbulb.fill", Color.bYellow),
    ]

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            VStack(spacing: 10) {
                ForEach(items.indices, id: \.self) { i in
                    let (text, icon, color) = items[i]
                    HStack(spacing: 14) {
                        Image(systemName: icon)
                            .font(.system(size: 16))
                            .foregroundColor(color)
                            .frame(width: 36, height: 36)
                            .background(color.opacity(0.15))
                            .cornerRadius(10)

                        Text(text)
                            .font(.bBody())
                            .foregroundColor(.bNavy)
                            .strikethrough(checkedItems.contains(i), color: .bNavy.opacity(0.4))

                        Spacer()

                        Image(systemName: checkedItems.contains(i) ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 24))
                            .foregroundColor(checkedItems.contains(i) ? .bGreen : .bGrayBeige)
                    }
                    .padding(14)
                    .background(Color.white)
                    .cornerRadius(16)
                    .bShadow(0.06)
                    .offset(x: animate ? 0 : -60)
                    .opacity(animate ? 1 : 0)
                    .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(Double(i) * 0.12), value: animate)
                    .onTapGesture {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            if checkedItems.contains(i) {
                                checkedItems.remove(i)
                            } else {
                                checkedItems.insert(i)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 32)

            VStack(spacing: 12) {
                Text("Track tasks and materials")
                    .font(.bTitle())
                    .foregroundColor(.bNavy)
                    .multilineTextAlignment(.center)
                    .opacity(animate ? 1 : 0)
                    .offset(y: animate ? 0 : 20)
                    .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.35), value: animate)

                Text("Keep all tasks, materials, and purchases in one place.")
                    .font(.bBody())
                    .foregroundColor(.bNavy.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .opacity(animate ? 1 : 0)
                    .offset(y: animate ? 0 : 10)
                    .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.45), value: animate)
            }

            Spacer()
        }
    }
}

// MARK: - Page 3: Control budget

struct OnboardingPage3: View {
    @Binding var animate: Bool

    let bars: [(String, Double, Color)] = [
        ("Materials", 0.75, .bBlue),
        ("Labor",     0.55, .bOrange),
        ("Delivery",  0.30, .bTeal),
        ("Tools",     0.45, .bYellow),
    ]

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // Bar chart illustration
            HStack(alignment: .bottom, spacing: 16) {
                ForEach(bars.indices, id: \.self) { i in
                    let (label, value, color) = bars[i]
                    VStack(spacing: 6) {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(color)
                            .frame(width: 44, height: animate ? CGFloat(value * 120) : 0)
                            .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(Double(i) * 0.1), value: animate)

                        Text(label)
                            .font(.system(size: 10, weight: .semibold, design: .rounded))
                            .foregroundColor(.bNavy.opacity(0.6))
                    }
                }
            }
            .padding(.horizontal, 40)

            VStack(spacing: 12) {
                Text("Control budget easily")
                    .font(.bTitle())
                    .foregroundColor(.bNavy)
                    .multilineTextAlignment(.center)
                    .opacity(animate ? 1 : 0)
                    .offset(y: animate ? 0 : 20)
                    .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.4), value: animate)

                Text("See where your money goes and what still needs to be done.")
                    .font(.bBody())
                    .foregroundColor(.bNavy.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .opacity(animate ? 1 : 0)
                    .offset(y: animate ? 0 : 10)
                    .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.5), value: animate)
            }

            Spacer()
        }
    }
}
