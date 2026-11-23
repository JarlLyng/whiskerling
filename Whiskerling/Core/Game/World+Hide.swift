import SwiftUI

/// A place the cat hides in hide and seek (#20), worked out from the room's layout each time, so a
/// resized window moves it along with the room.
struct HideSpot {
    enum Peek { case head, tail, hangingTail, lump }
    let id: String
    /// The depth it's drawn at among the things in the room, just behind what hides the cat.
    var depth: CGFloat
    /// What peeks out, where, and how large; `flip` mirrors it.
    var peeks: [(Peek, CGPoint, CGFloat, Bool)]
    /// Where the cat stands when it comes out.
    var out: CGPoint
}

/// One round of hide and seek: the cat hides `finds` times, and there's no way to lose.
struct HideGame {
    static let finds = 8
    static let readyTime: CGFloat = 2, countTime: CGFloat = 1.8, foundTime: CGFloat = 1.6, hintEvery: CGFloat = 6
    enum Phase { case ready, counting, hidden, found }
    var phase = Phase.ready
    var t: CGFloat = 0
    var spot: String?
    var found = 0
    var hintT: CGFloat = 0
    var finished = false
}

extension World {
    // MARK: Hiding places

    /// Behind the basket's rim, behind the litter box, under the rug and behind the curtain
    /// indoors; behind the apple tree, over the fence and behind the pond in the garden.
    func hideSpots() -> [HideSpot] {
        let st = stage, head = st.size * st.head
        func out(_ x: CGFloat) -> CGPoint { CGPoint(x: min(max(x, G.minX), G.maxX), y: G.catY) }
        if room == .garden {
            let ts = objScale(G.tree.y), fence = G.floorY - 64 * U, fs = objScale(G.floorY) * head
            let ps = objScale(G.pond.y)
            return [
                HideSpot(id: "tree", depth: G.tree.y - 1,
                         peeks: [(.head, CGPoint(x: G.tree.x + 44 * ts, y: G.tree.y - 118 * ts), ts * head * 0.9, false),
                                 (.tail, CGPoint(x: G.tree.x - 22 * ts, y: G.tree.y - 8 * ts), ts * st.size, true)],
                         out: out(G.tree.x - 150 * U)),
                HideSpot(id: "fenceLeft", depth: -1,
                         peeks: [(.head, CGPoint(x: W * 0.27, y: fence + 2 * U), fs, false)], out: out(W * 0.27)),
                HideSpot(id: "fenceRight", depth: -1,
                         peeks: [(.head, CGPoint(x: W * 0.6, y: fence + 2 * U), fs, false)], out: out(W * 0.6)),
                HideSpot(id: "pond", depth: G.pond.y - 1,
                         peeks: [(.head, CGPoint(x: G.pond.x - G.pondRX * 0.5, y: G.pond.y - G.pondRY - 14 * ps),
                                  ps * head * 0.85, false)],
                         out: out(G.pond.x - G.pondRX * 0.5))
            ]
        }
        let bs = objScale(G.bed.y), ls = objScale(G.litter.y), ry = H * 0.885, rs = objScale(ry)
        return [
            HideSpot(id: "basket", depth: G.bed.y,
                     peeks: [(.head, CGPoint(x: G.bed.x + 8 * bs, y: G.bed.y - 50 * bs), bs * head * 0.85, false)],
                     out: out(G.bed.x - 40 * U)),
            HideSpot(id: "litter", depth: G.litter.y - 1,
                     peeks: [(.head, CGPoint(x: G.litter.x + 34 * ls, y: G.litter.y - 98 * ls), ls * head * 0.8, false)],
                     out: out(G.litter.x + 160 * U)),
            HideSpot(id: "rug", depth: ry,
                     peeks: [(.lump, CGPoint(x: W * 0.64, y: ry), rs, false),
                             (.tail, CGPoint(x: W * 0.64 + 62 * rs, y: ry - 4 * rs), rs * st.size, false)],
                     out: out(W * 0.64)),
            HideSpot(id: "curtain", depth: -1,
                     peeks: [(.hangingTail, CGPoint(x: G.win.minX - 12 * U, y: G.win.maxY + 18 * U), U * st.size, false)],
                     out: out(G.win.minX))
        ]
    }

    func hideSpot(_ id: String?) -> HideSpot? { hideSpots().first { $0.id == id } }

    /// Points a finger can find the cat at, one per thing that peeks out.
    func hidePoints(_ spot: HideSpot) -> [CGPoint] {
        spot.peeks.map { peek, at, s, flip in
            switch peek {
            case .head: return at
            case .lump: return CGPoint(x: at.x, y: at.y - 14 * s)
            case .tail: return CGPoint(x: at.x + (flip ? -40 : 40) * s, y: at.y - 30 * s)
            case .hangingTail: return CGPoint(x: at.x, y: at.y + 40 * s)
            }
        }
    }

    // MARK: The game

    @discardableResult
    func startHide() -> Bool {
        guard let s = save, !s.lightsOff, mode == .normal, isPro else { return false }
        if s.needs.energy < 12 { meowSay(L10n.tooTiredToPlay); return false }
        setMode(.hide)
        bowl = nil; toy = nil
        cat.walk = nil; cat.jump = nil; cat.activity = .hide; cat.petT = 0; cat.vx = 0; cat.moving = false
        sound.stopPurr()
        hiding = HideGame()
        meowSay(L10n.hideStart, HideGame.readyTime)
        return true
    }

    /// Whether the cat is out of sight just now.
    var catHidden: Bool {
        guard mode == .hide, let g = hiding else { return false }
        return g.phase == .counting || g.phase == .hidden
    }

    func updateHide(_ dt: CGFloat) {
        guard var g = hiding else { return }
        g.t += dt
        switch g.phase {
        case .ready where g.t >= HideGame.readyTime, .found where g.t >= HideGame.foundTime && !g.finished:
            if g.found >= HideGame.finds { g.finished = true; hiding = g; finishHide(g.found); return }
            // off it goes: a puff where it stood, and a new place, never the same one twice running
            burst(.sparkle, cat.x, cat.y - 80 * catScale, count: 12, speed: 180 * U, life: 0.7, size: 8 * U)
            sound.pop()
            bubble = nil
            let choices = hideSpots().map(\.id).filter { $0 != g.spot }
            g.spot = choices.randomElement()
            g.phase = .counting; g.t = 0
        case .counting where g.t >= HideGame.countTime:
            g.phase = .hidden; g.t = 0; g.hintT = 0
        case .hidden:
            g.hintT += dt
            if g.hintT >= HideGame.hintEvery, let spot = hideSpot(g.spot), let p = hidePoints(spot).first {
                // a little meow from the hiding place, as a hint
                g.hintT = 0
                sound.meow(pitch: stage.pitch * 1.1)
                spawn(.text, p.x, p.y - 40 * U, vy: -30 * U, life: 1, size: 22 * U, text: "?")
            }
        default:
            break
        }
        hiding = g
        if g.phase == .found { cat.y += (G.catY - cat.y) * min(1, dt * 6) }
    }

    func tapHide(_ p: CGPoint) {
        guard var g = hiding, g.phase == .hidden, let spot = hideSpot(g.spot) else { return }
        let reach = 95 * U // generous: small fingers, and the tail is thin
        guard hidePoints(spot).contains(where: { hypot($0.x - p.x, $0.y - p.y) < reach }) else { return }
        g.phase = .found; g.t = 0; g.found += 1
        hiding = g
        cat.x = spot.out.x; cat.y = spot.out.y
        cat.hop = 0.35; cat.happyT = 1.4; cat.activity = .hide
        save!.needs.fun = min(100, save!.needs.fun + 3)
        save!.needs.energy = max(0, save!.needs.energy - 0.6)
        let at = hidePoints(spot).first ?? spot.out
        burst(.sparkle, at.x, at.y, count: 12, speed: 180 * U, life: 0.8, size: 9 * U)
        if g.found % 2 == 0 { addHearts(1, at: CGPoint(x: spot.out.x, y: spot.out.y - 200 * U)) } else { sound.chime() }
        meowSay(L10n.foundLines.randomElement()!, 1.5)
        hudDue = true
    }

    private func finishHide(_ found: Int) {
        save!.needs.energy = max(0, save!.needs.energy - 3)
        addHearts(1)
        burst(.sparkle, cat.x, cat.y - 150 * U, count: 18, speed: 220 * U, life: 1.1, size: 10 * U)
        sound.fanfare()
        meowSay(L10n.hideBye, 2.6)
        post(.toast(L10n.hideResult(name, found)))
        modeEndT = 2.4
        hudDue = true
    }

    /// Ends the game where it stands: a hidden cat comes out first.
    func stopHide() {
        if let g = hiding, g.phase == .counting || g.phase == .hidden, let spot = hideSpot(g.spot) {
            cat.x = spot.out.x; cat.y = spot.out.y
        }
        hiding = nil
    }

    // MARK: Drawing

    /// The spots drawn among the room's things, by depth. The ones on the wall or behind the fence
    /// are drawn with the scenery instead (`drawHidePeek(onWall:)`).
    func hideProps() -> [(CGFloat, (Pen) -> Void)] {
        guard mode == .hide, let g = hiding, g.phase == .hidden, let spot = hideSpot(g.spot), spot.depth >= 0 else { return [] }
        return [(spot.depth, { [unowned self] p in self.drawPeeks(p, spot) })]
    }

    /// Behind the curtain or the fence, drawn before them so they hide the cat.
    func drawHidePeek(onWall p: Pen) {
        guard mode == .hide, let g = hiding, g.phase == .hidden, let spot = hideSpot(g.spot), spot.depth < 0 else { return }
        drawPeeks(p, spot)
    }

    private func drawPeeks(_ p: Pen, _ spot: HideSpot) {
        let k = coat, wiggle = reduceMotion ? 0 : sin(T * 3.2)
        for (peek, at, s, flip) in spot.peeks {
            p.save(); p.translate(at.x, at.y); p.scale(flip ? -s : s, s)
            switch peek {
            case .head:
                var pose = CatPose(coat: k, stage: stage)
                pose.eyes = .wide
                pose.lookX = at.x < W / 2 ? 0.8 : -0.8
                pose.wear = save?.wear ?? Wear()
                p.rotate(reduceMotion ? 0 : sin(T * 1.6) * 0.06)
                CatArt.drawHead(p, k, pose)
            case .tail:
                tailPath(p, wiggle, hanging: false); p.stroke(k.line, 22); p.stroke(tailFill(k), 15.5); stripes(p, k)
            case .hangingTail:
                tailPath(p, wiggle, hanging: true); p.stroke(k.line, 22); p.stroke(tailFill(k), 15.5); stripes(p, k)
            case .lump:
                // a cat-sized bump under the rug, with a shadow on the far side so it stands out
                p.ell(6, 2, 80, 10); p.fill(.rgba(40, 60, 60, 0.2))
                p.beginPath(); p.moveTo(-74, 2); p.quadTo(-60, -44, 0, -46); p.quadTo(60, -44, 74, 2); p.closePath()
                let rug = shows("rug") ? DecorArt.pinkRug : DecorArt.rug
                p.fill(rug.mixed(with: .black, 0.06)); p.stroke(rug.mixed(with: .black, 0.28), 2.5)
                p.beginPath(); p.moveTo(10, -44); p.quadTo(58, -40, 70, -2); p.quadTo(40, -24, 10, -44); p.closePath()
                p.fill(.rgba(40, 60, 60, 0.15))
                p.beginPath(); p.moveTo(-44, -30); p.quadTo(-16, -42, 14, -40); p.stroke(.rgba(255, 255, 255, 0.55), 5)
                p.dash = [10, 8]
                p.beginPath(); p.moveTo(-64, -6); p.quadTo(0, -36, 64, -6); p.stroke(.white, 3)
                p.dash = []
            }
            p.restore()
        }
    }

    private func tailPath(_ p: Pen, _ w: CGFloat, hanging: Bool) {
        p.beginPath()
        if hanging {
            p.moveTo(0, -6); p.bezierTo(4, 30, -10 + w * 8, 60, 6 + w * 12, 86)
        } else {
            p.moveTo(0, 0); p.bezierTo(40, 4, 74, -14, 62 + w * 10, -58 - w * 4)
        }
    }

    private func tailFill(_ k: Coat) -> Color { k.pattern == .calico ? k.p1 : k.fur }

    private func stripes(_ p: Pen, _ k: Coat) {
        guard k.pattern == .stripes else { return }
        p.lineCap = .butt; p.dash = [7, 10]
        p.stroke(k.dark, 15.5)
        p.dash = []; p.lineCap = .round
    }

    /// "1, 2, 3": big numbers in the middle of the room while the cat hides.
    func drawHideCount(_ p: Pen) {
        guard mode == .hide, let g = hiding, g.phase == .counting else { return }
        let n = min(Int(g.t / (HideGame.countTime / 3)) + 1, 3)
        let x = W / 2, y = H * 0.42, r = 64 * U
        p.circ(x, y, r); p.fill(.rgba(255, 255, 255, 0.78)); p.stroke(Color(hex: "E7A86B"), 4 * U)
        p.text("\(n)", x, y + 2 * U, size: 78 * U, weight: .heavy, color: Color(hex: "8A5A3C"))
    }
}
