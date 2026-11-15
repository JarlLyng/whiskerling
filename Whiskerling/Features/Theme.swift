import IAMJARLDesignTokens
import SwiftUI

typealias Tokens = DesignTokens

/// The app's own colours. The room is an illustration with its own palette; these are the
/// bars, buttons and cards around it, in light and dark.
enum Theme {
    static let bar = DesignTokens.adaptive(light: Color(hex: "FFF8EE"), dark: Color(hex: "2B2320"))
    static let barLine = DesignTokens.adaptive(light: Color(hex: "F1D9B5"), dark: Color(hex: "4A3B35"))
    static let card = DesignTokens.adaptive(light: Color(hex: "FFF8EE"), dark: Color(hex: "352B27"))
    static let screen = DesignTokens.adaptive(light: Color(hex: "FDF1E0"), dark: Color(hex: "231C19"))
    static let text = DesignTokens.adaptive(light: Color(hex: "4A3B35"), dark: Color(hex: "F6EADB"))
    static let muted = DesignTokens.adaptive(light: Color(hex: "8C7466"), dark: Color(hex: "C2AE9F"))
    static let track = DesignTokens.adaptive(light: Color(hex: "EFE2CF"), dark: Color(hex: "4A3B35"))
    static let option = DesignTokens.adaptive(light: Color(hex: "FFE7C7"), dark: Color(hex: "4A3B35"))
    static let chosen = Color(hex: "5BC57A")
    /// Pastel button faces keep dark text in both modes, so contrast holds.
    static let onPastel = Color(hex: "4A3B35")
    static let feed = Color(hex: "FFD6A5")
    static let play = Color(hex: "CDEAC0")
    static let wash = Color(hex: "BDE0FE")
    static let sleep = Color(hex: "D9CCF2")
    static let dress = Color(hex: "FFC8DD")
    static let garden = Color(hex: "FCEFA0")
    static let go = Color(hex: "7BD389")

    static func meter(_ v: Double) -> Color {
        v > 60 ? Color(hex: "5BC57A") : (v > 30 ? Color(hex: "F2C14E") : Color(hex: "EF6F6C"))
    }

    static func font(_ size: CGFloat, _ weight: Font.Weight = .bold) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }
}

/// A big, soft, pressable button face used across the game.
struct PillButtonStyle: ButtonStyle {
    var color: Color
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(Theme.onPastel)
            .background {
                // The drop shadow belongs to the button face only; on the whole label it doubled the text.
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(color)
                    .shadow(color: .black.opacity(0.18), radius: 0, x: 0, y: configuration.isPressed ? 2 : 5)
            }
            .offset(y: configuration.isPressed ? 3 : 0)
            .animation(.easeOut(duration: Tokens.Motion.Duration.fast), value: configuration.isPressed)
    }
}
