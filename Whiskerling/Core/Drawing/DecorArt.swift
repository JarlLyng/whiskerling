import SwiftUI

/// The living room's decorations (#18), drawn in code like everything else. Each is drawn around a
/// point at a scale, so the room and the wardrobe's tiles share the same drawing.
enum DecorArt {
    static let rug = Color(hex: "A9DCD7")
    static let pinkRug = Color(hex: "F4B6C9")
    static let wallHeart = Color(hex: "F7CFD8")
    private static let bulbColors = [Color(hex: "FFD84D"), Color(hex: "FF8FB1"), Color(hex: "7FD1F2"), Color(hex: "9BE07F")]

    static func heart(_ p: Pen, _ x: CGFloat, _ y: CGFloat, _ r: CGFloat) {
        p.beginPath()
        p.moveTo(x, y + r * 0.95)
        p.bezierTo(x - r * 1.7, y - r * 0.2, x - r * 0.65, y - r * 1.45, x, y - r * 0.45)
        p.bezierTo(x + r * 0.65, y - r * 1.45, x + r * 1.7, y - r * 0.2, x, y + r * 0.95)
        p.closePath()
    }

    /// A fish-shaped cookie (#38), pale before baking and golden after.
    static func fishCookie(_ p: Pen, _ x: CGFloat, _ y: CGFloat, _ s: CGFloat, golden: Bool = true) {
        let fill = golden ? Color(hex: "E3A55B") : Color(hex: "F3D9AE"), line = golden ? Color(hex: "A96A2C") : Color(hex: "CDAE7E")
        p.save(); p.translate(x, y); p.scale(s, s)
        p.beginPath()
        p.moveTo(14, 0); p.quadTo(8, -11, -6, -9); p.quadTo(-12, -8, -15, -3); p.lineTo(-24, -10); p.lineTo(-21, 0)
        p.lineTo(-24, 10); p.lineTo(-15, 3); p.quadTo(-12, 8, -6, 9); p.quadTo(8, 11, 14, 0); p.closePath()
        p.fill(fill); p.stroke(line, 1.6)
        p.circ(7, -2, 1.8); p.fill(line)
        p.beginPath(); p.moveTo(-3, -5); p.quadTo(0, 0, -3, 5); p.stroke(line, 1.2)
        p.restore()
    }

    /// A plant in a pot standing at (x, y), about 150 units tall.
    static func plant(_ p: Pen, _ x: CGFloat, _ y: CGFloat, _ s: CGFloat, sway: CGFloat = 0) {
        p.save(); p.translate(x, y); p.scale(s, s)
        p.ell(0, 0, 32, 7); p.fill(.rgba(90, 55, 30, 0.18))
        let light = Color(hex: "62B460"), dark = Color(hex: "3F8C46")
        let leaves: [(CGFloat, CGFloat, Bool)] = [(-0.95, 66, true), (0.95, 64, true), (-0.5, 90, false),
                                                  (0.5, 88, false), (-0.18, 100, true), (0.22, 96, false)]
        for (a, len, back) in leaves {
            p.save(); p.translate(0, -46); p.rotate(a + sway)
            p.beginPath(); p.moveTo(0, 0); p.quadTo(-17, -len * 0.55, 0, -len); p.quadTo(17, -len * 0.55, 0, 0); p.closePath()
            p.fill(back ? dark : light)
            p.beginPath(); p.moveTo(0, -6); p.lineTo(0, -len + 10); p.stroke(.rgba(255, 255, 255, 0.28), 1.6)
            p.restore()
        }
        p.beginPath(); p.moveTo(-25, -46); p.lineTo(25, -46); p.lineTo(18, 0); p.lineTo(-18, 0); p.closePath()
        p.fill(Color(hex: "D9774B")); p.stroke(Color(hex: "A9532E"), 2.5)
        p.rr(-29, -55, 58, 12, 4); p.fill(Color(hex: "E58A5F")); p.stroke(Color(hex: "A9532E"), 2.5)
        p.restore()
    }

    /// A cat tree standing at (x, y): two sisal posts, two platforms with cushions and a ball on a
    /// string, about 210 units tall.
    static func catTree(_ p: Pen, _ x: CGFloat, _ y: CGFloat, _ s: CGFloat, swing: CGFloat = 0) {
        p.save(); p.translate(x, y); p.scale(s, s)
        let wood = Color(hex: "C99A6B"), woodLine = Color(hex: "8B6440")
        let rope = Color(hex: "E3C9A0"), ropeLine = Color(hex: "B89668")
        let pad = Color(hex: "8FC1D9"), padLine = Color(hex: "5E93AD")
        p.ell(0, 0, 70, 10); p.fill(.rgba(90, 55, 30, 0.18))
        for (px, top) in [(CGFloat(-26), CGFloat(-122)), (30, -192)] {
            p.rr(px - 9, top, 18, -14 - top, 3); p.fill(rope); p.stroke(ropeLine, 2)
            p.beginPath()
            var yy = top + 6
            while yy < -18 { p.moveTo(px - 9, yy); p.lineTo(px + 9, yy + 3); yy += 7 }
            p.stroke(ropeLine.opacity(0.6), 1.2)
        }
        p.rr(-62, -16, 124, 16, 6); p.fill(wood); p.stroke(woodLine, 2.5)
        p.rr(-58, -130, 72, 12, 5); p.fill(wood); p.stroke(woodLine, 2.5)
        p.rr(-52, -140, 60, 12, 6); p.fill(pad); p.stroke(padLine, 2)
        p.rr(-2, -200, 66, 12, 5); p.fill(wood); p.stroke(woodLine, 2.5)
        p.rr(4, -210, 54, 12, 6); p.fill(pad); p.stroke(padLine, 2)
        let bx = 54 + swing * 6
        p.beginPath(); p.moveTo(54, -188); p.lineTo(bx, -150); p.stroke(woodLine, 1.5)
        p.circ(bx, -144, 7); p.fill(Color(hex: "FF8FB1")); p.stroke(Color(hex: "D9607F"), 2)
        p.restore()
    }

    /// Fairy lights hanging in three swags from `a` to `b`. With `glow` each bulb has a halo, for
    /// a dark room; `t` makes them twinkle (0 keeps them steady).
    static func lights(_ p: Pen, from a: CGPoint, to b: CGPoint, sag: CGFloat, bulb r: CGFloat, glow: Bool, t: CGFloat,
                       perSwag: Int = 5) {
        let swags = 3
        var bulbs: [CGPoint] = []
        p.beginPath(); p.moveTo(a.x, a.y)
        for i in 0..<swags {
            let f0 = CGFloat(i) / CGFloat(swags), f1 = CGFloat(i + 1) / CGFloat(swags)
            let p0 = CGPoint(x: a.x + (b.x - a.x) * f0, y: a.y + (b.y - a.y) * f0)
            let p1 = CGPoint(x: a.x + (b.x - a.x) * f1, y: a.y + (b.y - a.y) * f1)
            let c = CGPoint(x: (p0.x + p1.x) / 2, y: (p0.y + p1.y) / 2 + sag * 2)
            p.quadTo(c.x, c.y, p1.x, p1.y)
            for k in 1...perSwag {
                let u = CGFloat(k) / CGFloat(perSwag + 1), v = 1 - u
                bulbs.append(CGPoint(x: v * v * p0.x + 2 * v * u * c.x + u * u * p1.x,
                                     y: v * v * p0.y + 2 * v * u * c.y + u * u * p1.y))
            }
        }
        p.stroke(Color(hex: "4F5B3A"), max(1, r * 0.3))
        for (i, q) in bulbs.enumerated() {
            let color = bulbColors[i % bulbColors.count]
            let lit = t == 0 ? 1 : 0.75 + 0.25 * sin(t * 2.2 + CGFloat(i) * 1.3)
            if glow {
                p.fillRadial([.init(color: color.opacity(0.6 * Double(lit)), location: 0), .init(color: color.opacity(0), location: 1)],
                             center: q, radius: r * 4.5)
                p.circ(q.x, q.y + r * 0.6, r * 4.5); p.fill()
            }
            p.rr(q.x - r * 0.35, q.y - r * 0.2, r * 0.7, r * 0.5, r * 0.15); p.fill(Color(hex: "4F5B3A"))
            p.ell(q.x, q.y + r * 0.9, r * 0.7, r); p.fill(color.opacity(glow ? 1 : 0.6 + 0.4 * Double(lit)))
        }
    }

    /// A pale picture with the cat's own head in it, in its coat and with what it wears.
    static func portrait(_ p: Pen, _ r: CGRect, cat: CatPose, unit u: CGFloat) {
        p.fillColor = Color(hex: "FFF1E0"); p.fillRect(r.minX, r.minY, r.width, r.height)
        p.save()
        p.beginPath(); p.rect(r.minX, r.minY, r.width, r.height); p.clip()
        p.fillColor = Color(hex: "FBE0C4")
        p.ell(r.midX, r.maxY + 4 * u, r.width * 0.42, r.height * 0.3); p.fill()
        let s = min(r.width / 150, r.height / 120)
        p.translate(r.midX, r.midY + 10 * s); p.scale(s, s)
        CatArt.drawHead(p, cat.coat, cat)
        p.restore()
    }
}
