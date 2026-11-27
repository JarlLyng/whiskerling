import SwiftUI
import UIKit
import XCTest
@testable import Whiskerling

/// Larger Text (#42): the app's text grows with the system's text size, at least to twice its
/// size at the largest sizes, while the bars around the room stop at the largest standard size so
/// the room stays in view.
@MainActor
final class LargerTextTests: XCTestCase {
    private let suite = "whiskerling.tests.largertext"

    /// The height a view takes at a text size, in a window `width` points wide.
    private func height<V: View>(_ view: V, at type: DynamicTypeSize, width: CGFloat = 1032) -> CGFloat {
        let host = UIHostingController(rootView: view.environment(\.dynamicTypeSize, type))
        return host.sizeThatFits(in: CGSize(width: width, height: .greatestFiniteMagnitude)).height
    }

    func testEachSizeFollowsTheNearestTextStyle() {
        let expected: [(CGFloat, Font.TextStyle)] = [
            (44, .largeTitle), (34, .largeTitle), (28, .title), (26, .title), (24, .title2), (22, .title2),
            (20, .title3), (19, .title3), (18, .body), (17, .body), (16, .callout), (15, .subheadline),
            (14, .subheadline), (13, .footnote), (12, .caption), (11, .caption2),
        ]
        for (size, style) in expected {
            XCTAssertEqual(Theme.textStyle(for: size), style, "\(size) points")
        }
    }

    func testTextKeepsItsSizeAtTheStandardSize() {
        // the App Store screenshots and everyone on the standard size see the same text as before
        let theme = height(Text(verbatim: "Whiskerling").themeFont(17), at: .large)
        let fixed = height(Text(verbatim: "Whiskerling").font(.system(size: 17, weight: .bold, design: .rounded)), at: .large)
        XCTAssertEqual(theme, fixed, accuracy: 0.5)
    }

    func testTextGrowsToAtLeastTwiceItsSize() {
        // Apple's Larger Text asks for at least 200%; the system reaches it at the third accessibility size
        for size: CGFloat in [13, 15, 17, 19] {
            let line = Text(verbatim: "Whiskerling").themeFont(size)
            let standard = height(line, at: .large)
            let larger = height(line, at: .accessibility3)
            XCTAssertGreaterThanOrEqual(larger / standard, 2, "\(size) points")
            XCTAssertGreaterThan(height(line, at: .accessibility5), larger, "\(size) points, and on to the largest")
        }
    }

    func testTheBarsAroundTheRoomStopGrowing() {
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
        SaveStore.save(SaveState(name: "Mis", coat: "orange"), to: defaults)
        let model = GameModel(defaults: defaults) // never the real cat
        model.sound.enabled = false
        for bar in [AnyView(HUDBar(model: model)), AnyView(ActionBar(model: model))] {
            let standard = height(bar, at: .large)
            let capped = height(bar, at: HUDBar.largestType)
            XCTAssertGreaterThanOrEqual(capped, standard, "the bar grows with the text up to the cap")
            XCTAssertEqual(height(bar, at: .accessibility5), capped, accuracy: 0.5, "and no further, so the room stays in view")
        }
    }
}
