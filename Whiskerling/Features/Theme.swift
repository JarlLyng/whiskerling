import IAMJARLDesignTokens
import SwiftUI
import UIKit

typealias Tokens = DesignTokens

/// The app's own colours. The room is an illustration with its own palette; these are the
/// bars, buttons and cards around it, in light and dark.
enum Theme {
    /// A colour for light and dark, with a stronger pair for Increase Contrast (#43).
    static func adaptive(_ light: Color, _ dark: Color, high lightHigh: Color, _ darkHigh: Color) -> Color {
        let l = UIColor(light), d = UIColor(dark), lh = UIColor(lightHigh), dh = UIColor(darkHigh)
        return Color(uiColor: UIColor { t in
            let high = t.accessibilityContrast == .high
            return t.userInterfaceStyle == .dark ? (high ? dh : d) : (high ? lh : l)
        })
    }

    static let bar = DesignTokens.adaptive(light: Color(hex: "FFF8EE"), dark: Color(hex: "2B2320"))
    static let barLine = adaptive(Color(hex: "F1D9B5"), Color(hex: "4A3B35"), high: Color(hex: "B8925F"), Color(hex: "8C7466"))
    static let card = DesignTokens.adaptive(light: Color(hex: "FFF8EE"), dark: Color(hex: "352B27"))
    static let screen = DesignTokens.adaptive(light: Color(hex: "FDF1E0"), dark: Color(hex: "231C19"))
    static let text = adaptive(Color(hex: "4A3B35"), Color(hex: "F6EADB"), high: Color(hex: "2E2420"), Color(hex: "FFFFFF"))
    /// Notes and second lines. At least 4.5:1 on the cards, the tiles and a chosen tile, in light
    /// and dark; the same as the text with Increase Contrast (#43).
    static let muted = adaptive(Color(hex: "725C50"), Color(hex: "CDBBAD"), high: Color(hex: "4A3B35"), Color(hex: "F6EADB"))
    static let track = DesignTokens.adaptive(light: Color(hex: "EFE2CF"), dark: Color(hex: "4A3B35"))
    static let option = DesignTokens.adaptive(light: Color(hex: "FFE7C7"), dark: Color(hex: "4A3B35"))
    static let chosen = Color(hex: "5BC57A")
    /// Pastel button faces keep dark text in both modes, so contrast holds.
    static let onPastel = Color(hex: "4A3B35")
    /// The note under a choice on a pastel face: softer than its name, still 4.5:1 on every face.
    static let onPastelSoft = adaptive(Color(hex: "5A4840"), Color(hex: "5A4840"), high: onPastel, onPastel)
    /// A button that can't be used just now (the light is off): a quiet face, its words still clear.
    static let restingFace = Color(hex: "E9E1D6")
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

    /// The text style a size grows with: the one closest to it at the standard text size, so a
    /// big title grows less than a small note, the way the system's own styles do (#42).
    static func textStyle(for size: CGFloat) -> Font.TextStyle {
        switch size {
        case 31...: .largeTitle
        case 25..<31: .title
        case 21..<25: .title2
        case 19..<21: .title3
        case 17..<19: .body
        case 16..<17: .callout
        case 14..<16: .subheadline
        case 13..<14: .footnote
        case 12..<13: .caption
        default: .caption2
        }
    }
}

/// The app's rounded type, at a size that grows with the system's text size (#42).
private struct ThemeFont: ViewModifier {
    @ScaledMetric private var size: CGFloat
    private let weight: Font.Weight

    init(size: CGFloat, weight: Font.Weight) {
        _size = ScaledMetric(wrappedValue: size, relativeTo: Theme.textStyle(for: size))
        self.weight = weight
    }

    func body(content: Content) -> some View {
        content.font(.system(size: size, weight: weight, design: .rounded))
    }
}

extension View {
    /// The app's rounded type: `size` points at the standard text size, larger or smaller with
    /// the system's text size, like the system's own text styles (#42).
    func themeFont(_ size: CGFloat, _ weight: Font.Weight = .bold) -> some View {
        modifier(ThemeFont(size: size, weight: weight))
    }
}

/// A big, soft, pressable button face used across the game.
struct PillButtonStyle: ButtonStyle {
    var color: Color
    func makeBody(configuration: Configuration) -> some View {
        PillFace(configuration: configuration, color: color)
    }
}

/// The face itself, so it can read the environment: with Increase Contrast it gets an outline (#43).
private struct PillFace: View {
    let configuration: ButtonStyleConfiguration
    let color: Color
    @Environment(\.colorSchemeContrast) private var contrast

    var body: some View {
        configuration.label
            .foregroundStyle(Theme.onPastel)
            .background {
                // The drop shadow belongs to the button face only; on the whole label it doubled the text.
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(color)
                    .shadow(color: .black.opacity(0.18), radius: 0, x: 0, y: configuration.isPressed ? 2 : 5)
                    .overlay {
                        if contrast == .increased {
                            RoundedRectangle(cornerRadius: 22, style: .continuous).stroke(Theme.onPastel.opacity(0.7), lineWidth: 2)
                        }
                    }
            }
            .offset(y: configuration.isPressed ? 3 : 0)
            .animation(.easeOut(duration: Tokens.Motion.Duration.fast), value: configuration.isPressed)
    }
}
