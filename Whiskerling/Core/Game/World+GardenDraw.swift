import SwiftUI

/// Drawing the garden: sky, fence, lawn, tree, pond and the fish of Catch the fish.
extension World {
    private static let lawn: [SkyPhase: [Color]] = [
        .night: [Color(hex: "5E8A55"), Color(hex: "4C7A47")], .dawn: [Color(hex: "A9D885"), Color(hex: "86C469")],
        .day: [Color(hex: "A7DB7E"), Color(hex: "7DC461")], .dusk: [Color(hex: "9CC77A"), Color(hex: "79B160")]
    ]
    private static let fishColors: [(Color, Color)] = [
        (Color(hex: "F4A259"), Color(hex: "C9732C")), (Color(hex: "FFC857"), Color(hex: "D49A1E")),
        (Color(hex: "7FB7D9"), Color(hex: "4E86A8")), (Color(hex: "F28FAD"), Color(hex: "C95F80"))
    ]

    // MARK: Behind everything

    func drawGardenScenery(_ p: Pen) {
        let hz = G.floorY
        p.fillGradient(World.skies[sky]!, from: CGPoint(x: 0, y: 0), to: CGPoint(x: 0, y: hz))
        p.fillRect(0, 0, W, hz)
        let sx = W * 0.14, sy = H * 0.12
        switch sky {
        case .night:
            p.fillColor = .white
            for i in 0..<44 {
                p.alpha = 0.45 + Double(i % 3) * 0.2 + 0.1 * Double(sin(T * 2 + CGFloat(i)))
                p.circ(World.hash01(i, 3) * W, World.hash01(i, 4) * hz * 0.85, (1 + CGFloat(i % 3) * 0.6) * U); p.fill()
            }
            p.alpha = 1
            p.circ(sx, sy, 34 * U); p.fill(.rgba(255, 244, 194, 0.18))
            p.circ(sx, sy, 22 * U); p.fill(Color(hex: "FFF4C2"))
            p.fillColor = .rgba(220, 200, 140, 0.5)
            p.circ(sx - 7 * U, sy - 5 * U, 5 * U); p.fill(); p.circ(sx + 7 * U, sy + 7 * U, 3.5 * U); p.fill()
        case .day:
            p.circ(sx, sy, 40 * U); p.fill(.rgba(255, 216, 77, 0.3))
            p.circ(sx, sy, 26 * U); p.fill(Color(hex: "FFD84D"))
        case .dawn, .dusk:
            p.circ(sky == .dawn ? W * 0.12 : W * 0.88, hz - 50 * U, 28 * U); p.fill(Color(hex: "FFB347"))
        }
        if sky != .night {
            p.fillColor = sky == .day ? .rgba(255, 255, 255, 0.95) : .rgba(255, 235, 225, 0.85)
            for i in 0..<4 {
                let span = W + 240 * U
                let x = -120 * U + (T * (7 + CGFloat(i) * 3) * U + CGFloat(i) * span / 4).truncatingRemainder(dividingBy: span)
                let s = U * (1 + CGFloat(i % 2) * 0.25), y = hz * (0.18 + CGFloat(i) * 0.12)
                p.circ(x, y, 16 * s); p.fill()
                p.circ(x + 18 * s, y - 6 * s, 20 * s); p.fill()
                p.circ(x + 38 * s, y, 15 * s); p.fill()
                p.ell(x + 18 * s, y + 6 * s, 32 * s, 10 * s); p.fill()
            }
        }
        let hill = World.hills[sky]!
        p.ell(W * 0.22, hz + 6 * U, W * 0.42, 70 * U); p.fill(hill[0])
        p.ell(W * 0.8, hz + 14 * U, W * 0.48, 92 * U); p.fill(hill[1])
        drawFence(p, hz)

        let lawn = World.lawn[sky]!
        p.fillGradient(lawn, from: CGPoint(x: 0, y: hz), to: CGPoint(x: 0, y: H))
        p.fillRect(0, hz, W, H - hz)
        // mown stripes, wider towards the front
        p.fillColor = .rgba(255, 255, 255, 0.07)
        var y = hz, band = 16 * U, row = 0
        while y < H {
            if row % 2 == 0 { p.fillRect(0, y, W, band) }
            y += band; band *= 1.2; row += 1
        }
        p.fillColor = .rgba(40, 110, 40, 0.22)
        for i in 0..<34 {
            let gx = World.hash01(i, 5) * W, gy = hz + 18 * U + World.hash01(i, 6) * (H - hz - 20 * U)
            let s = objScale(gy)
            p.beginPath()
            p.moveTo(gx - 6 * s, gy); p.lineTo(gx - 3 * s, gy - 11 * s); p.lineTo(gx, gy)
            p.lineTo(gx + 3 * s, gy - 14 * s); p.lineTo(gx + 6 * s, gy)
            p.closePath(); p.fill()
        }
    }

    private func drawFence(_ p: Pen, _ hz: CGFloat) {
        // bushes peeking over the fence
        for i in 0..<7 {
            let bx = World.hash01(i, 7) * W, r = (34 + World.hash01(i, 8) * 26) * U
            p.circ(bx, hz - 52 * U, r); p.fill(Color(hex: "6DB863"))
            p.circ(bx - r * 0.4, hz - 52 * U - r * 0.3, r * 0.45); p.fill(.rgba(255, 255, 255, 0.12))
        }
        let top = hz - 64 * U, pw = 18 * U, gap = 9 * U
        p.fillColor = Color(hex: "FFF6E8"); p.strokeColor = Color(hex: "C8AE8E"); p.lineWidth = 1.5
        p.fillRect(0, top + 14 * U, W, 9 * U); p.strokeRect(0, top + 14 * U, W, 9 * U)
        p.fillRect(0, hz - 26 * U, W, 9 * U); p.strokeRect(0, hz - 26 * U, W, 9 * U)
        var x: CGFloat = -4 * U
        while x < W {
            p.beginPath()
            p.moveTo(x, hz); p.lineTo(x, top + 8 * U); p.lineTo(x + pw / 2, top); p.lineTo(x + pw, top + 8 * U); p.lineTo(x + pw, hz)
            p.closePath(); p.fill(Color(hex: "FFF6E8")); p.stroke(Color(hex: "C8AE8E"), 1.5)
            x += pw + gap
        }
        p.fillColor = .rgba(120, 90, 50, 0.18); p.fillRect(0, hz - 2, W, 3)
    }

    // MARK: Things on the lawn (sorted by depth with the cat)

    func gardenProps() -> [(CGFloat, (Pen) -> Void)] {
        var list: [(CGFloat, (Pen) -> Void)] = [
            (G.tree.y, drawTree),
            (G.pond.y - 0.5, drawPond),
            (G.pond.y + 0.5, drawLeapingFish)
        ]
        for f in G.flowers { list.append((f.y, { [unowned self] p in self.drawFlower(p, f) })) }
        return list
    }

    private func drawTree(_ p: Pen) {
        let s = objScale(G.tree.y)
        p.save(); p.translate(G.tree.x, G.tree.y); p.scale(s, s)
        p.ell(0, 0, 110, 18); p.fill(.rgba(40, 80, 30, 0.2))
        p.beginPath()
        p.moveTo(-26, 0); p.quadTo(-16, -120, -20, -230); p.lineTo(20, -230); p.quadTo(16, -120, 26, 0)
        p.closePath(); p.fill(Color(hex: "9C6B3F")); p.stroke(Color(hex: "6E4626"), 3)
        p.beginPath(); p.moveTo(-6, -40); p.quadTo(-2, -90, -8, -150); p.stroke(.rgba(110, 70, 38, 0.5), 3)
        let sway = sin(T * 0.9) * 3
        let crown: [(CGFloat, CGFloat, CGFloat)] = [(-80, -250, 70), (80, -255, 72), (0, -300, 100), (-45, -360, 66), (50, -365, 64)]
        for c in crown { p.circ(c.0 + sway, c.1, c.2 + 4); p.fill(Color(hex: "4E9E45")) }
        for c in crown { p.circ(c.0 + sway, c.1, c.2); p.fill(Color(hex: "6CBF5B")) }
        for c in crown { p.circ(c.0 + sway - c.2 * 0.3, c.1 - c.2 * 0.3, c.2 * 0.42); p.fill(.rgba(255, 255, 255, 0.12)) }
        let apples: [(CGFloat, CGFloat)] = [(-70, -240), (40, -280), (95, -235), (-20, -330), (10, -230), (60, -350)]
        for a in apples {
            p.circ(a.0 + sway, a.1, 9); p.fill(Color(hex: "E5484D"))
            p.circ(a.0 + sway - 3, a.1 - 3, 3); p.fill(.rgba(255, 255, 255, 0.6))
        }
        p.restore()
    }

    private func drawPond(_ p: Pen) {
        let c = G.pond, rx = G.pondRX, ry = G.pondRY
        p.ell(c.x, c.y + 8 * U, rx + 16 * U, ry + 12 * U); p.fill(.rgba(40, 80, 30, 0.2))
        // stones around the edge, the far ones first
        let stones = 26
        for i in 0..<stones {
            let a = CGFloat(i) / CGFloat(stones) * .pi * 2
            let shade = Double(0.82 + 0.12 * World.hash01(i, 9))
            p.ell(c.x + cos(a) * (rx + 7 * U), c.y + sin(a) * (ry + 6 * U), (13 + World.hash01(i, 10) * 5) * U, 8 * U)
            p.fill(Color(red: shade * 0.86, green: shade * 0.84, blue: shade * 0.8))
        }
        p.save()
        p.ell(c.x, c.y, rx, ry); p.clip()
        p.fillGradient([Color(hex: "6EC3EC"), Color(hex: "2F86C0")], from: CGPoint(x: 0, y: c.y - ry), to: CGPoint(x: 0, y: c.y + ry))
        p.fillRect(c.x - rx, c.y - ry, rx * 2, ry * 2)
        // fish shadows swimming under the surface
        for i in 0..<3 {
            let a = T * (0.45 + CGFloat(i) * 0.12) + CGFloat(i) * 2.1
            let fx = c.x + cos(a) * rx * 0.55, fy = c.y + sin(a) * ry * 0.45
            p.ell(fx, fy, 15 * U, 5.5 * U, a + .pi / 2); p.fill(.rgba(20, 60, 100, 0.3))
        }
        for r in ripples {
            p.alpha = Double(max(0, 1 - r.t / 1.4))
            p.ell(r.x, r.y, (10 + r.t * 46) * U, (3 + r.t * 13) * U); p.stroke(.white, 2 * U)
        }
        p.alpha = 1
        p.beginPath(); p.ellipse(c.x - rx * 0.25, c.y - ry * 0.35, rx * 0.45, ry * 0.25, from: .pi * 1.1, to: .pi * 1.6)
        p.stroke(.rgba(255, 255, 255, 0.55), 3 * U)
        p.restore()
        // lily pads with a flower
        let pads: [(CGFloat, CGFloat, CGFloat)] = [(-0.55, 0.15, 1), (0.6, -0.1, 0.85), (0.15, 0.45, 0.7)]
        for (i, pad) in pads.enumerated() {
            let px = c.x + pad.0 * rx, py = c.y + pad.1 * ry, r = 20 * U * pad.2
            p.beginPath(); p.moveTo(px, py)
            p.ellipse(px, py, r, r * 0.42, from: 0.35, to: .pi * 2 - 0.1)
            p.closePath(); p.fill(Color(hex: "5DB35A")); p.stroke(Color(hex: "3E8A3C"), 1.5)
            if i == 0 {
                p.fillColor = Color(hex: "FFC2D6")
                for k in 0..<6 {
                    let a = CGFloat(k) * .pi / 3
                    p.ell(px - 4 * U + cos(a) * 6 * U, py - 6 * U + sin(a) * 3 * U, 6 * U, 3.4 * U, a); p.fill()
                }
                p.circ(px - 4 * U, py - 6 * U, 3 * U); p.fill(Color(hex: "FFD84D"))
            }
        }
        // reeds at the left end
        for k in 0..<4 {
            let bx = c.x - rx - 4 * U + CGFloat(k) * 9 * U, h = (60 + CGFloat(k % 2) * 22) * U
            let lean = sin(T * 1.2 + CGFloat(k)) * 3 * U
            p.beginPath(); p.moveTo(bx, c.y + 4 * U); p.quadTo(bx + lean, c.y - h * 0.5, bx + lean * 2, c.y - h)
            p.stroke(Color(hex: "5E9B4A"), 3 * U)
            if k % 2 == 0 { p.ell(bx + lean * 1.8, c.y - h * 0.82, 4 * U, 11 * U); p.fill(Color(hex: "8A5A35")) }
        }
    }

    private func drawLeapingFish(_ p: Pen) {
        guard let g = fishing else { return }
        for f in g.fish {
            let pt = fishPoint(f)
            if f.caughtAt == nil && f.progress < 0.04 { continue }
            let (body, edge) = World.fishColors[f.hue % World.fishColors.count]
            p.save()
            let angle = fishAngle(f)
            p.translate(pt.x, pt.y); p.rotate(angle)
            let s = U * 1.35 * (f.caughtAt != nil ? 1.15 : 1)
            // a fish leaping to the left keeps its back up
            p.scale(s, f.caughtAt == nil && cos(angle) < 0 ? -s : s)
            if f.caughtAt != nil { p.circ(0, 0, 34); p.fill(.rgba(255, 236, 140, 0.35)) }
            p.beginPath(); p.moveTo(-18, 0); p.lineTo(-36, -13); p.lineTo(-33, 0); p.lineTo(-36, 13); p.closePath()
            p.fill(edge)
            p.ell(0, 0, 24, 12); p.fill(body); p.stroke(edge, 2)
            p.beginPath(); p.moveTo(-4, -10); p.quadTo(4, -20, 10, -10); p.closePath(); p.fill(edge)
            p.ell(-4, 3, 9, 3.5); p.fill(.rgba(255, 255, 255, 0.35)) // a lighter belly
            p.beginPath(); p.moveTo(15, 4); p.quadTo(19, 8, 23, 3); p.stroke(edge, 1.8) // a smile
            p.circ(13, -3, 4.2); p.fill(.white)
            p.circ(14, -3, 2.2); p.fill(Color(hex: "2B2027"))
            p.restore()
        }
    }

    private func drawFlower(_ p: Pen, _ f: Flower) {
        let s = objScale(f.y)
        let colors = [Color(hex: "FF8FB1"), Color(hex: "FFD84D"), Color(hex: "FFFFFF"), Color(hex: "B9A3FF")]
        p.save(); p.translate(f.x, f.y); p.scale(s, s)
        let sway = sin(T * 1.4 + f.x * 0.05) * 2
        p.beginPath(); p.moveTo(0, 0); p.quadTo(sway, -12, sway, -24); p.stroke(Color(hex: "4E9E45"), 2.5)
        p.ell(-6, -9, 6, 3, -0.5); p.fill(Color(hex: "5DB35A"))
        p.fillColor = colors[f.kind % colors.count]
        for k in 0..<5 {
            let a = CGFloat(k) * .pi * 2 / 5 + 0.3
            p.circ(sway + cos(a) * 6, -26 + sin(a) * 6, 5); p.fill()
        }
        p.circ(sway, -26, 3.6); p.fill(f.kind == 1 ? Color(hex: "E07A5F") : Color(hex: "FFC94D"))
        p.restore()
    }

    // MARK: In front of everything

    /// Butterflies by day, fireflies by night, and how many fish are caught.
    func drawGardenAir(_ p: Pen) {
        switch sky {
        case .night:
            p.fillColor = .rgba(14, 18, 48, 0.42); p.fillRect(0, 0, W, H)
            for i in 0..<8 {
                let x = W * (0.1 + 0.8 * (0.5 + 0.5 * sin(T * (0.07 + CGFloat(i) * 0.013) + CGFloat(i) * 1.7)))
                let y = G.floorY + (H - G.floorY) * (0.15 + 0.5 * (0.5 + 0.5 * sin(T * (0.11 + CGFloat(i) * 0.02) + CGFloat(i))))
                let glow = 0.5 + 0.5 * sin(T * 2.6 + CGFloat(i) * 1.3)
                p.alpha = Double(glow)
                p.circ(x, y, 9 * U); p.fill(.rgba(255, 240, 150, 0.35))
                p.circ(x, y, 2.6 * U); p.fill(Color(hex: "FFF59D"))
            }
            p.alpha = 1
        case .dawn, .dusk:
            p.fillColor = .rgba(255, 140, 90, 0.08); p.fillRect(0, 0, W, H)
            drawButterflies(p)
        case .day:
            drawButterflies(p)
        }
        if mode == .fish, let g = fishing {
            let label = "🐟 \(g.caught)"
            let fs = 26 * min(U, 1.3)
            let w = p.measure(label, size: fs).width + 30
            p.rr(14, 14, w, fs * 1.8, 16); p.fill(.rgba(255, 255, 255, 0.88)); p.stroke(Color(hex: "C8AE8E"), 2)
            p.text(label, 14 + w / 2, 14 + fs * 0.9, size: fs, weight: .heavy, color: Color(hex: "4A3B35"))
        }
    }

    private func drawButterflies(_ p: Pen) {
        let colors = [Color(hex: "FFB3D1"), Color(hex: "FFD966"), Color(hex: "A0D8F1")]
        for i in 0..<3 {
            let fi = CGFloat(i)
            let x = W * (0.12 + 0.76 * (0.5 + 0.5 * sin(T * (0.11 + 0.03 * fi) + fi * 2.3)))
            let y = G.floorY - 20 * U + sin(T * (0.37 + 0.05 * fi) + fi) * 70 * U + cos(T * 1.3 + fi) * 12 * U
            let flap = 0.25 + 0.75 * abs(sin(T * 11 + fi * 1.7))
            p.save(); p.translate(x, y); p.scale(U, U)
            p.fillColor = colors[i]
            p.ell(-9 * flap, -5, 9 * flap, 8, -0.4); p.fill()
            p.ell(9 * flap, -5, 9 * flap, 8, 0.4); p.fill()
            p.ell(-6 * flap, 6, 6 * flap, 5, 0.3); p.fill()
            p.ell(6 * flap, 6, 6 * flap, 5, -0.3); p.fill()
            p.ell(0, 0, 2, 8); p.fill(Color(hex: "4A3B35"))
            p.restore()
        }
    }

    func drawRoomFade(_ p: Pen) {
        guard roomFade > 0 else { return }
        p.alpha = Double(min(roomFade / 0.45, 1))
        p.fillColor = Color(hex: "FDF1E0"); p.fillRect(0, 0, W, H)
        p.alpha = 1
    }
}
