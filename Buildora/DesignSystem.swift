import SwiftUI

// MARK: - Color System

extension Color {
    static let bYellow    = Color(hex: "FFC83A")
    static let bOrange    = Color(hex: "FF9F43")
    static let bRed       = Color(hex: "FF6B57")
    static let bBlue      = Color(hex: "3B82F6")
    static let bTeal      = Color(hex: "35D0BA")
    static let bNavy      = Color(hex: "2B2D42")
    static let bBG        = Color(hex: "FFF8EC")
    static let bGreen     = Color(hex: "52C873")
    static let bGrayBeige = Color(hex: "E9E1D3")
    static let bSectionBG = Color(hex: "F7F2E8")

    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:  (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:  (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:  (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(.sRGB, red: Double(r)/255, green: Double(g)/255, blue: Double(b)/255, opacity: Double(a)/255)
    }
}

// MARK: - Gradient System

extension LinearGradient {
    static let bYellowOrange = LinearGradient(colors: [.bYellow, .bOrange], startPoint: .topLeading, endPoint: .bottomTrailing)
    static let bOrangeRed    = LinearGradient(colors: [.bOrange, .bRed],   startPoint: .topLeading, endPoint: .bottomTrailing)
    static let bBlueTeal     = LinearGradient(colors: [.bBlue, .bTeal],    startPoint: .topLeading, endPoint: .bottomTrailing)
    static let bGreenTeal    = LinearGradient(colors: [.bGreen, .bTeal],   startPoint: .topLeading, endPoint: .bottomTrailing)
    static let bPrimary      = LinearGradient(colors: [.bYellow, .bOrange, .bRed], startPoint: .topLeading, endPoint: .bottomTrailing)
}

// MARK: - Typography

extension Font {
    static func bTitle()    -> Font { .system(size: 28, weight: .black, design: .rounded) }
    static func bHeadline() -> Font { .system(size: 20, weight: .bold,  design: .rounded) }
    static func bSubhead()  -> Font { .system(size: 16, weight: .semibold, design: .rounded) }
    static func bBody()     -> Font { .system(size: 14, weight: .regular, design: .rounded) }
    static func bCaption()  -> Font { .system(size: 12, weight: .medium, design: .rounded) }
    static func bLargeTitle() -> Font { .system(size: 34, weight: .black, design: .rounded) }
}

// MARK: - Shadow

extension View {
    func bShadow(_ opacity: Double = 0.12) -> some View {
        self.shadow(color: Color.bNavy.opacity(opacity), radius: 8, x: 0, y: 4)
    }
    func bCardStyle() -> some View {
        self
            .background(Color(.systemBackground))
            .cornerRadius(20)
            .bShadow()
    }
}

// MARK: - Custom Button Styles

struct BuildoraPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.bSubhead())
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(LinearGradient.bYellowOrange)
            .cornerRadius(16)
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
            .bShadow(0.2)
    }
}

struct BuildoraSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.bSubhead())
            .foregroundColor(.bNavy)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.bGrayBeige)
            .cornerRadius(16)
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

struct BuildoraIconButtonStyle: ButtonStyle {
    var color: Color = .bYellow
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(.white)
            .padding(12)
            .background(color)
            .cornerRadius(14)
            .scaleEffect(configuration.isPressed ? 0.9 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
            .bShadow(0.15)
    }
}

// MARK: - Reusable Card Component

struct BCard<Content: View>: View {
    let content: Content
    var padding: CGFloat = 16

    init(padding: CGFloat = 16, @ViewBuilder content: () -> Content) {
        self.padding = padding
        self.content = content()
    }

    var body: some View {
        content
            .padding(padding)
            .bCardStyle()
    }
}

// MARK: - Stat Badge

struct StatBadge: View {
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.bHeadline())
                .foregroundColor(color)
            Text(label)
                .font(.bCaption())
                .foregroundColor(.bNavy.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(color.opacity(0.1))
        .cornerRadius(14)
    }
}

// MARK: - Progress Bar

struct BProgressBar: View {
    var value: Double  // 0.0 to 1.0
    var color: Color = .bGreen
    var height: CGFloat = 8

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: height / 2)
                    .fill(Color.bGrayBeige)
                    .frame(height: height)
                RoundedRectangle(cornerRadius: height / 2)
                    .fill(color)
                    .frame(width: geo.size.width * CGFloat(min(max(value, 0), 1)), height: height)
                    .animation(.spring(response: 0.5, dampingFraction: 0.8), value: value)
            }
        }
        .frame(height: height)
    }
}

// MARK: - Section Header

struct BSectionHeader: View {
    let title: String
    var action: String? = nil
    var onAction: (() -> Void)? = nil

    var body: some View {
        HStack {
            Text(title)
                .font(.bHeadline())
                .foregroundColor(.bNavy)
            Spacer()
            if let action = action, let onAction = onAction {
                Button(action: onAction) {
                    Text(action)
                        .font(.bCaption())
                        .foregroundColor(.bBlue)
                }
            }
        }
    }
}

// MARK: - Empty State

struct BEmptyState: View {
    let icon: String
    let title: String
    let subtitle: String
    var buttonTitle: String? = nil
    var onButton: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 52))
                .foregroundColor(.bGrayBeige)
            Text(title)
                .font(.bHeadline())
                .foregroundColor(.bNavy)
            Text(subtitle)
                .font(.bBody())
                .foregroundColor(.bNavy.opacity(0.5))
                .multilineTextAlignment(.center)
            if let buttonTitle = buttonTitle, let onButton = onButton {
                Button(action: onButton) {
                    Text(buttonTitle)
                }
                .buttonStyle(BuildoraPrimaryButtonStyle())
                .frame(width: 200)
            }
        }
        .padding(32)
    }
}

// MARK: - Custom Text Field

struct BTextField: View {
    let placeholder: String
    @Binding var text: String
    var icon: String? = nil
    var keyboardType: UIKeyboardType = .default
    var isSecure: Bool = false

    var body: some View {
        HStack(spacing: 12) {
            if let icon = icon {
                Image(systemName: icon)
                    .foregroundColor(.bNavy.opacity(0.4))
                    .frame(width: 20)
            }
            if isSecure {
                SecureField(placeholder, text: $text)
                    .font(.bBody())
            } else {
                TextField(placeholder, text: $text)
                    .font(.bBody())
                    .keyboardType(keyboardType)
            }
        }
        .padding(14)
        .background(Color.bSectionBG)
        .cornerRadius(14)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.bGrayBeige, lineWidth: 1))
    }
}

// MARK: - Tag View

struct BTag: View {
    let text: String
    let color: Color
    var small: Bool = false

    var body: some View {
        Text(text)
            .font(small ? .bCaption() : .system(size: 11, weight: .semibold, design: .rounded))
            .foregroundColor(color)
            .padding(.horizontal, small ? 8 : 10)
            .padding(.vertical, small ? 3 : 5)
            .background(color.opacity(0.15))
            .cornerRadius(20)
    }
}

// MARK: - FAB (Floating Action Button)

struct BFAB: View {
    let action: () -> Void
    var icon: String = "plus"
    var color: Color = .bOrange

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 60, height: 60)
                .background(
                    LinearGradient(colors: [color, color.opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing)
                )
                .clipShape(Circle())
                .bShadow(0.25)
        }
        .scaleEffect(1)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: UUID())
    }
}

// MARK: - Building Block Shape

struct BlockTower: View {
    var blockCount: Int = 5
    var animated: Bool = false

    private let blockColors: [Color] = [.bBlue, .bTeal, .bGreen, .bYellow, .bOrange, .bRed]

    var body: some View {
        VStack(spacing: 2) {
            ForEach(0..<blockCount, id: \.self) { i in
                let reverseI = blockCount - 1 - i
                RoundedRectangle(cornerRadius: 8)
                    .fill(blockColors[reverseI % blockColors.count])
                    .frame(width: CGFloat(60 - reverseI * 5), height: 24)
                    .shadow(color: blockColors[reverseI % blockColors.count].opacity(0.3), radius: 4, y: 2)
            }
        }
    }
}

// MARK: - Color Extensions for Dark Mode

extension Color {
    static var bAdaptiveBG: Color {
        Color(.systemBackground)
    }
    static var bAdaptiveCard: Color {
        Color(.secondarySystemBackground)
    }
    static var bAdaptiveText: Color {
        Color(.label)
    }
}
