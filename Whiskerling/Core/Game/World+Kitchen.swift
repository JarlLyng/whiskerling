import SwiftUI

/// The kitchen (#38), a third room with Pro: a window, cupboards, a counter with a sink and an
/// oven, a fridge and the cookie jar. The bowl, the basket and the litter box stay in the living
/// room. Places are worked out from the window's size every time, like the other rooms.
extension World {
    // MARK: Layout

    var kWin: CGRect { CGRect(x: W * 0.13, y: H * 0.1, width: min(W * 0.24, H * 0.42), height: H * 0.22) }
    /// The front of the counter, standing on the floor at the back.
    var kCounter: CGRect { CGRect(x: W * 0.04, y: G.floorY - 62 * U, width: W * 0.58, height: 84 * U) }
    var kWorktopY: CGFloat { kCounter.minY - 8 * U }
    var kSinkX: CGFloat { min(max(kWin.midX, kCounter.minX + 70 * U), kCounter.maxX - 200 * U) }
    var kOven: CGRect {
        CGRect(x: kCounter.minX + kCounter.width * 0.66 - 56 * U, y: kCounter.minY + 10 * U, width: 112 * U, height: 64 * U)
    }
    var kFridge: CGRect {
        let x = max(W * 0.7, kCounter.maxX + 34 * U), top = H * 0.12
        return CGRect(x: min(x, W - 140 * U), y: top, width: 118 * U, height: G.floorY + 20 * U - top)
    }
    /// The mixing bowl on the worktop: tap it to bake.
    var kBowl: CGPoint { CGPoint(x: (kSinkX + kOven.midX) / 2, y: kWorktopY) }
    var kJar: CGPoint { CGPoint(x: kCounter.maxX - 34 * U, y: kWorktopY) }
    /// Where the cat sits on the counter while the child bakes.
    var kCounterSeat: CGPoint { CGPoint(x: kCounter.minX + 64 * U, y: kWorktopY + 2 * U) }
    var cookieJar: Int { save?.cookies ?? 0 }
    static let jarSize = 24

    // MARK: Going between rooms

    /// The room chooser (#38): needs the light on and no game going on; the garden and the
    /// kitchen need Pro.
    @discardableResult
    func go(to r: Room) -> Bool {
        guard let s = save, !s.lightsOff, mode == .normal, r == .living || isPro, room != r else { return false }
        enterRoom(r)
        switch r {
        case .living: meowSay(L10n.homeAgain, 2.2)
        case .garden: meowSay(sky == .night ? L10n.gardenNight : L10n.gardenLines.randomElement()!, 2.8)
        case .kitchen: meowSay(L10n.kitchenHello, 3)
        }
        return true
    }

    // MARK: The cat in the kitchen

    /// Now and then the cat looks into the fridge, or takes a cookie from the jar.
    func kitchenHabit() -> Bool {
        guard room == .kitchen, mode == .normal, kitchenT <= 0, Double.random(in: 0...1) < 0.3 else { return false }
        kitchenT = .random(in: 25...50)
        if cookieJar > 0 && Bool.random() {
            goTo(min(max(kJar.x, G.minX), G.maxX), G.catY, speed: 0.9, tag: "jar") { [weak self] in
                guard let self, self.cookieJar > 0, self.save != nil else { return }
                self.save!.cookies = self.cookieJar - 1
                self.save!.needs.food = min(100, self.save!.needs.food + 4)
                self.cat.hop = 0.35; self.cat.happyT = 1.4
                self.meowSay(L10n.stoleCookie, 2.2)
                self.hudDue = true
            }
        } else {
            goTo(min(max(kFridge.midX, G.minX), G.maxX), G.catY, speed: 0.8, tag: "fridge") { [weak self] in
                guard let self else { return }
                self.fridgeOpenT = 1.4
                self.cat.look = 0
                self.meowSay(L10n.fridgeLine, 2)
            }
        }
        return true
    }

    // MARK: Drawing

    func drawKitchenScenery(_ p: Pen) {
        let fy = G.floorY
        // tiles on the wall, and a white splashback over the counter
        p.fillColor = Color(hex: "EAF5EF"); p.fillRect(0, 0, W, fy)
        p.strokeColor = .rgba(120, 170, 150, 0.18); p.lineWidth = 1.5
        let t = 36 * U
        p.beginPath()
        var x: CGFloat = 0
        while x < W { p.moveTo(x, 0); p.lineTo(x, fy); x += t }
        var y: CGFloat = 0
        while y < fy { p.moveTo(0, y); p.lineTo(W, y); y += t }
        p.stroke()
        p.fillColor = Color(hex: "FFFFFF"); p.fillRect(kCounter.minX, kWorktopY - 70 * U, kCounter.width, 70 * U)
        p.strokeColor = .rgba(150, 170, 165, 0.35); p.lineWidth = 1
        p.beginPath()
        var bx = kCounter.minX
        while bx < kCounter.maxX { p.moveTo(bx, kWorktopY - 70 * U); p.lineTo(bx, kWorktopY); bx += 24 * U }
        p.moveTo(kCounter.minX, kWorktopY - 46 * U); p.lineTo(kCounter.maxX, kWorktopY - 46 * U)
        p.moveTo(kCounter.minX, kWorktopY - 22 * U); p.lineTo(kCounter.maxX, kWorktopY - 22 * U)
        p.stroke()

        // the floor: a checked vinyl, its rows deeper towards the front
        p.fillColor = Color(hex: "F3E2C4"); p.fillRect(0, fy, W, H - fy)
        let cw = 54 * U
        var ry = fy, rh = 16 * U, row = 0
        p.fillColor = Color(hex: "E6CDA6")
        while ry < H {
            var cx: CGFloat = row % 2 == 0 ? 0 : cw
            while cx < W { p.fillRect(cx, ry, cw, rh); cx += cw * 2 }
            ry += rh; rh *= 1.18; row += 1
        }
        p.fillColor = .rgba(140, 90, 40, 0.25); p.fillRect(0, fy - 1, W, 2)

        drawKitchenWindow(p)
        drawCupboards(p)
        drawHidePeek(onWall: p, only: ["fridgeSide"])
        drawFridge(p)
        drawHidePeek(onWall: p, only: ["fridgeTop"])
        drawCounter(p)
    }

    private func drawKitchenWindow(_ p: Pen) {
        let w = kWin
        p.save()
        p.beginPath(); p.rect(w.minX, w.minY, w.width, w.height); p.clip()
        p.fillGradient(World.skies[sky]!, from: CGPoint(x: 0, y: w.minY), to: CGPoint(x: 0, y: w.maxY))
        p.fillRect(w.minX, w.minY, w.width, w.height)
        let sx = w.maxX - w.width * 0.26, sy = w.minY + w.height * 0.3
        if sky == .night {
            p.circ(sx, sy, 16 * U); p.fill(Color(hex: "FFF4C2"))
        } else {
            p.circ(sx, sy, 24 * U); p.fill(.rgba(255, 216, 77, 0.3))
            p.circ(sx, sy, 15 * U); p.fill(Color(hex: "FFD84D"))
        }
        p.ell(w.midX, w.maxY + w.height * 0.25, w.width * 0.8, w.height * 0.4)
        p.fill(season.ground(World.hills[sky]![0], night: sky == .night))
        drawFalling(p, in: w, count: 12, seed: 7)
        p.restore()
        let f = 8 * U
        p.strokeColor = .white; p.lineWidth = f
        p.strokeRect(w.minX, w.minY, w.width, w.height)
        p.beginPath(); p.moveTo(w.midX, w.minY); p.lineTo(w.midX, w.maxY); p.stroke(.white, f * 0.55)
        // a gingham valance over the window
        let vy = w.minY - 6 * U, vh = 26 * U, sq = 9 * U
        p.fillColor = .white; p.fillRect(w.minX - 14 * U, vy, w.width + 28 * U, vh)
        p.fillColor = .rgba(226, 92, 100, 0.55)
        var gx = w.minX - 14 * U, col = 0
        while gx < w.maxX + 14 * U {
            var gy = vy, r = 0
            while gy < vy + vh { if (col + r) % 2 == 0 { p.fillRect(gx, gy, min(sq, w.maxX + 14 * U - gx), min(sq, vy + vh - gy)) }; gy += sq; r += 1 }
            gx += sq; col += 1
        }
        p.beginPath()
        var sx2 = w.minX - 14 * U
        p.moveTo(sx2, vy + vh)
        while sx2 < w.maxX + 14 * U { p.quadTo(sx2 + 9 * U, vy + vh + 8 * U, sx2 + 18 * U, vy + vh); sx2 += 18 * U }
        p.stroke(.rgba(200, 70, 80, 0.6), 2)
    }

    private func drawCupboards(_ p: Pen) {
        let top = H * 0.07, h = H * 0.17, gap = 18 * U
        let spans = [(kCounter.minX, kWin.minX - gap - 14 * U), (kWin.maxX + gap + 14 * U, kCounter.maxX)]
        for (x0, x1) in spans where x1 - x0 > 50 * U {
            let n = max(1, Int((x1 - x0) / (90 * U)))
            let dw = (x1 - x0) / CGFloat(n)
            for i in 0..<n {
                let dx = x0 + CGFloat(i) * dw
                p.rr(dx + 2, top, dw - 4, h, 6 * U); p.fill(Color(hex: "B9DCC9")); p.stroke(Color(hex: "7FAE96"), 2)
                p.rr(dx + 10 * U, top + 10 * U, dw - 20 * U, h - 20 * U, 4 * U); p.stroke(.rgba(255, 255, 255, 0.5), 2)
                p.circ(dx + (i % 2 == 0 ? dw - 16 * U : 16 * U), top + h - 18 * U, 4 * U); p.fill(Color(hex: "E7C35A"))
            }
        }
    }

    private func drawFridge(_ p: Pen) {
        let r = kFridge, split = r.minY + r.height * 0.36
        p.ell(r.midX, r.maxY, r.width * 0.6, 8 * U); p.fill(.rgba(90, 55, 30, 0.16))
        p.rr(r.minX, r.minY, r.width, r.height, 14 * U); p.fill(Color(hex: "D7ECF7")); p.stroke(Color(hex: "8DB5CC"), 2.5)
        p.beginPath(); p.moveTo(r.minX, split); p.lineTo(r.maxX, split); p.stroke(Color(hex: "8DB5CC"), 2.5)
        p.rr(r.minX + 12 * U, r.minY + 22 * U, 8 * U, split - r.minY - 44 * U, 4 * U); p.fill(Color(hex: "A9C9DB"))
        p.rr(r.minX + 12 * U, split + 22 * U, 8 * U, 90 * U, 4 * U); p.fill(Color(hex: "A9C9DB"))
        // a child's drawing of a cat under a magnet
        p.save()
        p.translate(r.midX + 14 * U, split + 70 * U); p.rotate(-0.08)
        p.rr(-30 * U, -24 * U, 60 * U, 50 * U, 3 * U); p.fill(.white); p.stroke(.rgba(150, 150, 150, 0.4), 1)
        p.circ(0, 2 * U, 13 * U); p.stroke(Color(hex: "F4A259"), 3 * U)
        p.beginPath(); p.moveTo(-10 * U, -6 * U); p.lineTo(-8 * U, -18 * U); p.lineTo(-2 * U, -10 * U)
        p.moveTo(10 * U, -6 * U); p.lineTo(8 * U, -18 * U); p.lineTo(2 * U, -10 * U); p.stroke(Color(hex: "F4A259"), 3 * U)
        p.circ(0, -24 * U, 4 * U); p.fill(Color(hex: "EF476F"))
        p.restore()
        if fridgeOpenT > 0 {
            // the top door swung open: a light, shelves and a fish
            let inner = CGRect(x: r.minX + 6 * U, y: r.minY + 6 * U, width: r.width - 12 * U, height: split - r.minY - 12 * U)
            p.rr(inner.minX, inner.minY, inner.width, inner.height, 8 * U); p.fill(Color(hex: "FFFBE6"))
            p.beginPath(); p.moveTo(inner.minX, inner.midY); p.lineTo(inner.maxX, inner.midY); p.stroke(Color(hex: "CFE3EE"), 3)
            p.save(); p.translate(inner.midX, inner.midY - 12 * U); p.scale(U * 0.6, U * 0.6)
            p.ell(0, 0, 28, 13); p.fill(Color(hex: "7FB7D9"))
            p.beginPath(); p.moveTo(-24, 0); p.lineTo(-42, -12); p.lineTo(-42, 12); p.closePath(); p.fill()
            p.restore()
            p.rr(inner.minX - r.width * 0.7, r.minY, r.width * 0.7, split - r.minY, 10 * U)
            p.fill(Color(hex: "E7F3FA")); p.stroke(Color(hex: "8DB5CC"), 2.5)
        }
    }

    private func drawCounter(_ p: Pen) {
        let c = kCounter
        p.ell(c.midX, c.maxY, c.width * 0.52, 9 * U); p.fill(.rgba(90, 55, 30, 0.14))
        p.rr(c.minX, c.minY, c.width, c.height, 6 * U); p.fill(Color(hex: "F6E7CF")); p.stroke(Color(hex: "C9A67A"), 2.5)
        // cupboard doors, skipping the oven
        let n = max(2, Int(c.width / (96 * U)))
        let dw = c.width / CGFloat(n)
        for i in 0..<n {
            let dx = c.minX + CGFloat(i) * dw
            if dx + dw > kOven.minX - 4 * U && dx < kOven.maxX + 4 * U { continue }
            p.rr(dx + 8 * U, c.minY + 10 * U, dw - 16 * U, c.height - 20 * U, 4 * U); p.stroke(.rgba(201, 166, 122, 0.7), 2)
            p.circ(dx + dw / 2, c.minY + 22 * U, 3.5 * U); p.fill(Color(hex: "C9A67A"))
        }
        // the cupboard where a tail can hang out (#20)
        if hideSpotNow == "cupboard" {
            let d = kCupboardDoor
            p.rr(d.minX, d.minY, d.width, d.height, 4 * U); p.fill(Color(hex: "5A4436"))
            p.rr(d.minX - d.width * 0.55, d.minY, d.width * 0.55, d.height, 4 * U); p.fill(Color(hex: "F6E7CF")); p.stroke(Color(hex: "C9A67A"), 2)
            drawHidePeek(onWall: p, only: ["cupboard"])
        }
        // the oven, glowing while it bakes
        let o = kOven
        p.rr(o.minX, o.minY, o.width, o.height, 8 * U); p.fill(Color(hex: "4A4E57")); p.stroke(Color(hex: "2E3138"), 2)
        let glow = ovenGlow
        p.rr(o.minX + 12 * U, o.minY + 12 * U, o.width - 24 * U, o.height - 26 * U, 6 * U)
        p.fill(glow > 0 ? Color(hex: "FFB347").opacity(0.35 + 0.55 * Double(glow)) : Color(hex: "23262C"))
        p.rr(o.minX + 14 * U, o.minY + 4 * U, o.width - 28 * U, 5 * U, 2.5 * U); p.fill(Color(hex: "C9CDD6"))
        // the worktop, with the sink and the hob set into it
        p.rr(c.minX - 6 * U, kWorktopY, c.width + 12 * U, 12 * U, 4 * U); p.fill(Color(hex: "D9B48A")); p.stroke(Color(hex: "A57F57"), 2)
        let sx = kSinkX
        p.ell(sx, kWorktopY + 3 * U, 46 * U, 9 * U); p.fill(Color(hex: "B7C3CC"))
        drawHidePeek(onWall: p, only: ["sink"])
        p.rr(sx - 50 * U, kWorktopY + 3 * U, 100 * U, 9 * U, 3 * U); p.fill(Color(hex: "D9B48A"))
        p.beginPath(); p.moveTo(sx + 30 * U, kWorktopY - 2 * U); p.lineTo(sx + 30 * U, kWorktopY - 34 * U)
        p.quadTo(sx + 30 * U, kWorktopY - 44 * U, sx + 18 * U, kWorktopY - 40 * U); p.stroke(Color(hex: "AEB8C2"), 5 * U)
        for k in 0..<2 {
            let hx = o.midX + CGFloat(k * 2 - 1) * 26 * U
            p.ell(hx, kWorktopY + 1 * U, 20 * U, 4 * U); p.fill(Color(hex: "3B3F47"))
        }
        drawMixingBowl(p)
        drawCookieJar(p)
    }

    /// The mixing bowl on the worktop, bobbing a little to say "tap me" while nothing is baking.
    private func drawMixingBowl(_ p: Pen) {
        let b = kBowl
        let bob = mode == .normal && !reduceMotion ? sin(T * 2.4) * 2 * U : 0
        p.save(); p.translate(b.x, b.y - bob); p.scale(U, U)
        p.beginPath(); p.moveTo(-34, -26); p.quadTo(-32, 2, 0, 2); p.quadTo(32, 2, 34, -26); p.closePath()
        p.fill(Color(hex: "F28FA8")); p.stroke(Color(hex: "C25B78"), 2.5)
        p.ell(0, -26, 34, 7); p.fill(Color(hex: "F8C3D0")); p.stroke(Color(hex: "C25B78"), 2)
        p.beginPath(); p.moveTo(10, -30); p.lineTo(26, -58); p.stroke(Color(hex: "C99A6B"), 5)
        p.restore()
    }

    private func drawCookieJar(_ p: Pen) {
        let j = kJar, n = cookieJar
        p.save(); p.translate(j.x, j.y); p.scale(U, U)
        p.rr(-26, -62, 52, 62, 12); p.fill(.rgba(220, 240, 250, 0.55)); p.stroke(Color(hex: "9CC3D6"), 2.5)
        p.rr(-22, -72, 44, 12, 5); p.fill(Color(hex: "C99A6B")); p.stroke(Color(hex: "8B6440"), 2)
        for i in 0..<min(n, 12) {
            let cx = -12 + CGFloat(i % 3) * 12, cy = -12 - CGFloat(i / 3) * 11
            DecorArt.fishCookie(p, cx, cy, 0.42)
        }
        p.restore()
    }

    // MARK: Hide and seek in the kitchen (#20)

    var kCupboardDoor: CGRect {
        CGRect(x: kCounter.minX + 14 * U, y: kCounter.minY + 10 * U, width: 64 * U, height: kCounter.height - 20 * U)
    }

    /// The id of the place the cat is hiding just now, if it is.
    var hideSpotNow: String? {
        guard mode == .hide, let g = hiding, g.phase == .hidden else { return nil }
        return g.spot
    }

    /// In the sink, on top of the fridge, beside the fridge, and in a cupboard.
    func kitchenSpots() -> [HideSpot] {
        let st = stage, head = st.size * st.head, s = objScale(G.floorY)
        func out(_ x: CGFloat) -> CGPoint { CGPoint(x: min(max(x, G.minX), G.maxX), y: G.catY) }
        let f = kFridge, d = kCupboardDoor
        return [
            HideSpot(id: "sink", depth: -1,
                     peeks: [(.head, CGPoint(x: kSinkX - 4 * U, y: kWorktopY - 24 * U), s * head * 0.72, false)], out: out(kSinkX)),
            HideSpot(id: "fridgeTop", depth: -1,
                     peeks: [(.hangingTail, CGPoint(x: f.midX + 26 * U, y: f.minY + 4 * U), U * st.size, false)], out: out(f.midX)),
            HideSpot(id: "fridgeSide", depth: -1,
                     peeks: [(.head, CGPoint(x: f.minX + 4 * U, y: f.minY + f.height * 0.5), s * head * 0.85, false)],
                     out: out(f.minX - 60 * U)),
            HideSpot(id: "cupboard", depth: -1,
                     peeks: [(.tail, CGPoint(x: d.midX, y: d.maxY - 6 * U), s * st.size, false)], out: out(d.midX + 80 * U))
        ]
    }
}
