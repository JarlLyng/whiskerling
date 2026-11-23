#if DEBUG
import SwiftUI

/// App Store screenshots (debug builds only). A scene is staged after every layout, and while
/// `screenshotScene` is set the world stands still apart from clouds and swaying, so a capture
/// is the same every time. See `GameModel.setUpScreenshot`.
extension World {
    func stageScreenshot(_ scene: String) {
        guard save != nil, W > 1 else { return }
        parts.removeAll()
        bubble = nil
        cat = CatState()
        cat.timer = 1_000; cat.needT = 1_000; cat.blinkT = 1_000
        cat.y = G.catY
        switch scene {
        case "fish":
            stageFishing()
        case "night":
            cat.x = G.bed.x; cat.y = G.bed.y; cat.activity = .sleep
            let s = catScale
            for (i, d) in [(0.0, 18.0), (1.0, 26.0), (2.0, 34.0)].enumerated() {
                spawn(.zzz, cat.x - (50 + CGFloat(i) * 22) * s, cat.y - (110 + CGFloat(i) * 46) * s,
                      life: 2.4, size: CGFloat(d.1) * U * 0.6)
            }
        case "wardrobe":
            cat.x = min(max(W * 0.68, G.minX), G.maxX); cat.happyT = 1_000
        case "party": // a first birthday (#17)
            cat.x = min(max(W * 0.6, G.minX), G.maxX); cat.happyT = 1_000
            party = Party(kind: .birthday(1), t: Party.length / 2)
            say(L10n.birthdayAge(1), 10_000)
            bubble?.t = 9_999
        case "decor": // the room with everything put up (#18)
            cat.x = min(max(W * 0.6, G.minX), G.maxX); cat.happyT = 1_000
        case "decornight":
            cat.x = G.bed.x; cat.y = G.bed.y; cat.activity = .sleep
        case "nap": // a grown-up habit: a nap on the rug, with the yarn it brought over (#17)
            cat.x = min(max(W * 0.6, G.minX), G.maxX); cat.activity = .nap
            toy = Toy(x: W * 0.42, y: G.catY + 4 * U)
        default: // the room, also behind the parental gate
            cat.x = W * 0.58; cat.petT = 1_000
            bowl = (.kibble, 1)
            say(L10n.hello(name), 10_000)
            bubble?.t = 9_999 // fully shown
            let hp = catHeadPos()
            for (dx, dy, r) in [(-70.0, -40.0, 15.0), (64.0, -70.0, 12.0), (-20.0, -110.0, 10.0)] {
                spawn(.heart, hp.x + CGFloat(dx) * U, hp.y + CGFloat(dy) * U, life: 1.4, size: CGFloat(r) * U)
            }
        }
    }

    /// Two fish in the air, one just caught, and the cat mid-leap.
    private func stageFishing() {
        var g = FishGame()
        g.caught = 7; g.leapsLeft = 4; g.spawnT = 1_000
        let y0 = G.pond.y - 2 * U
        // one fish rising on the left, one coming down on the right, the cat between them
        g.fish = [
            LeapingFish(x0: G.pond.x - G.pondRX * 0.85, x1: G.pond.x - G.pondRX * 0.85 + 110 * U, y0: y0, h: 230 * U,
                        t: 0.7, dur: 2, hue: 0),
            LeapingFish(x0: G.pond.x + G.pondRX * 1.1, x1: G.pond.x + G.pondRX * 0.75, y0: y0, h: 190 * U,
                        t: 1.35, dur: 2, hue: 3)
        ]
        cat.activity = .fish
        cat.x = clampToPond(G.pond.x + G.pondRX * 0.1)
        cat.jump = Jump(t: 0.31, h: 70 * U, vx: 0)
        var caught = LeapingFish(x0: cat.x, x1: cat.x, y0: y0, h: 0, dur: 2, hue: 1)
        let hp = catHeadPos()
        caught.caughtAt = CGPoint(x: hp.x + 46 * U, y: hp.y - 70 * U)
        caught.fallT = 0.08
        g.fish.append(caught)
        fishing = g
        ripples = [Ripple(x: G.pond.x - G.pondRX * 0.55, y: G.pond.y, t: 0.5),
                   Ripple(x: G.pond.x + G.pondRX * 0.4, y: G.pond.y, t: 0.25)]
        if let c = caught.caughtAt {
            burst(.sparkle, c.x, c.y, count: 10, speed: 1, life: 0.8, size: 9 * U)
            for i in parts.indices { parts[i].x += cos(CGFloat(i)) * 40 * U; parts[i].y += sin(CGFloat(i)) * 40 * U }
        }
        say(L10n.caughtLines[0], 10_000)
        bubble?.t = 9_999
    }
}
#endif
