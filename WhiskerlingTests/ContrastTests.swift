import SwiftUI
import UIKit
import XCTest
@testable import Whiskerling

/// Contrast (#43): the grey notes and the notes on the pastel faces reach the 4.5:1 that small
/// text needs on every background they sit on, in light and dark, and Increase Contrast makes them
/// stronger still.
final class ContrastTests: XCTestCase {
    /// The traits a colour is resolved in: light or dark, standard or Increase Contrast.
    private func env(_ scheme: ColorScheme, high: Bool = false) -> UITraitCollection {
        UITraitCollection { t in
            t.userInterfaceStyle = scheme == .dark ? .dark : .light
            t.accessibilityContrast = high ? .high : .normal
        }
    }

    /// WCAG's contrast ratio between two colours as they resolve in `traits`.
    private func ratio(_ a: Color, _ b: Color, in traits: UITraitCollection) -> Double {
        func lum(_ c: Color) -> Double {
            var r: CGFloat = 0, g: CGFloat = 0, bl: CGFloat = 0, al: CGFloat = 0
            UIColor(c).resolvedColor(with: traits).getRed(&r, green: &g, blue: &bl, alpha: &al)
            func lin(_ v: CGFloat) -> Double {
                let x = Double(v)
                return x <= 0.04045 ? x / 12.92 : pow((x + 0.055) / 1.055, 2.4)
            }
            return 0.2126 * lin(r) + 0.7152 * lin(g) + 0.0722 * lin(bl)
        }
        let (x, y) = (lum(a), lum(b))
        return (max(x, y) + 0.05) / (min(x, y) + 0.05)
    }

    func testGreyNotesReadOnTheirBackgrounds() {
        let chosenTile = Color(hex: "D2F2CF")
        for scheme in [ColorScheme.light, .dark] {
            let e = env(scheme)
            for (name, bg) in [("card", Theme.card), ("tile", Theme.option), ("screen", Theme.screen), ("bar", Theme.bar)] {
                XCTAssertGreaterThanOrEqual(ratio(Theme.muted, bg, in: e), 4.5, "grey on the \(name), \(scheme)")
            }
            XCTAssertGreaterThanOrEqual(ratio(Theme.onPastelSoft, chosenTile, in: e), 4.5, "a chosen tile's note, \(scheme)")
        }
    }

    func testNotesReadOnEveryPastelFace() {
        let faces = [Theme.feed, Theme.play, Theme.wash, Theme.sleep, Theme.dress, Theme.garden, Theme.go,
                     Theme.restingFace, Color(hex: "FFD3D3")]
        for scheme in [ColorScheme.light, .dark] {
            for face in faces {
                XCTAssertGreaterThanOrEqual(ratio(Theme.onPastelSoft, face, in: env(scheme)), 4.5)
                XCTAssertGreaterThanOrEqual(ratio(Theme.onPastel, face, in: env(scheme)), 4.5)
            }
        }
    }

    func testIncreaseContrastMakesTheGreyStronger() {
        for scheme in [ColorScheme.light, .dark] {
            let standard = ratio(Theme.muted, Theme.option, in: env(scheme))
            let increased = ratio(Theme.muted, Theme.option, in: env(scheme, high: true))
            XCTAssertGreaterThan(increased, standard, "\(scheme)")
            XCTAssertGreaterThanOrEqual(increased, 7, "\(scheme)")
        }
    }
}
