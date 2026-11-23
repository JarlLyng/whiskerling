import SwiftUI

enum EyeKind { case open, wide, sad, happy, closed, blink }
enum MouthKind { case smile, open, flat, sad }

struct Wear: Codable, Equatable {
    var head: String?
    var face: String?
    var neck: String?

    subscript(slot: ItemSlot) -> String? {
        get { switch slot { case .head: head; case .face: face; case .neck: neck } }
        set { switch slot { case .head: head = newValue; case .face: face = newValue; case .neck: neck = newValue } }
    }
}

/// Everything needed to draw the cat in one frame.
struct CatPose {
    var x: CGFloat = 0
    var y: CGFloat = 0
    var s: CGFloat = 1
    var coat: Coat
    var stage: Stage
    var eyes: EyeKind = .open
    var lid: CGFloat = 0
    var mouth: MouthKind = .smile
    var blush = false
    var tear = false
    var tilt: CGFloat = 0
    var tail: CGFloat = 0
    var lookX: CGFloat = 0
    var lookY: CGFloat = 0
    var wear = Wear()
    var dirt: CGFloat = 0
    var pawsUp = false
    var lift: CGFloat = 0
    var step: CGFloat = 0
    var shadow = true
}

/// The cat is drawn with its feet at (0, 0) and is about 190 units tall at scale 1.
enum CatArt {
    private static let ink = Color(hex: "2B2027")

    static func drawCat(_ p: Pen, _ c: CatPose) {
        let k = c.coat, bs = c.stage.body, hs = c.stage.head
        p.save()
        p.translate(c.x, c.y)
        if c.shadow {
            let sh = 1 - min(c.lift / (220 * c.s), 0.6)
            p.ell(0, 0, 60 * c.s * bs * sh, 11 * c.s * sh)
            p.fill(.rgba(90, 55, 30, 0.18))
        }
        p.translate(0, -c.lift)
        p.scale(c.s, c.s)

        // body
        p.save()
        p.scale(bs, bs)
        let sw = sin(c.tail)
        p.beginPath()
        p.moveTo(26, -20)
        p.bezierTo(80, -12, 98 + sw * 6, -60, 72 + sw * 18, -106)
        p.stroke(k.line, 22)
        p.stroke(k.tail, 15.5)
        if k.pattern == .stripes {
            p.lineCap = .butt
            p.dash = [7, 10]
            p.stroke(k.dark, 15.5)
            p.dash = []
            p.lineCap = .round
        }
        for x: CGFloat in [-30, 30] {
            p.ell(x, -22, 24, 21); p.fill(k.fur); p.stroke(k.line, 3.2)
        }
        p.ell(0, -56, 45, 55); p.fill(k.fur)
        bodyMarkings(p, k)
        p.ell(0, -56, 45, 55); p.stroke(k.line, 3.2)
        p.ell(0, -44, 26, 34); p.fill(k.light)
        if c.dirt > 0.05 { dirtSpots(p, c.dirt, [(-18, -40, 9), (21, -72, 7), (10, -22, 6), (-30, -20, 6)]) }
        if !c.pawsUp {
            paw(p, k, -15, -7 - max(0, c.step) * 7)
            paw(p, k, 15, -7 - max(0, -c.step) * 7)
        }
        p.restore()

        // head
        let headY = -118 * bs
        p.save()
        p.translate(0, headY)
        p.rotate(c.tilt)
        p.scale(hs, hs)
        drawHead(p, k, c)
        p.restore()

        // the collar is drawn after the head so it shows under the chin
        if let neck = c.wear.neck { drawNeck(p, neck, headY + 47 * hs, bs) }
        if c.pawsUp {
            paw(p, k, -40 * hs, headY + 32 * hs)
            paw(p, k, 40 * hs, headY + 32 * hs)
        }
        p.restore()
    }

    static func bodyMarkings(_ p: Pen, _ k: Coat) {
        guard let pattern = k.pattern else { return }
        p.save()
        p.ell(0, -56, 45, 55); p.clip()
        switch pattern {
        case .stripes:
            p.strokeColor = k.dark; p.lineWidth = 6
            for i in 0..<3 {
                let y = -84 + CGFloat(i) * 19
                p.beginPath(); p.moveTo(-48, y); p.quadTo(-36, y + 7, -27, y + 3); p.stroke()
                p.beginPath(); p.moveTo(48, y); p.quadTo(36, y + 7, 27, y + 3); p.stroke()
            }
        case .calico:
            p.ell(-30, -84, 28, 30); p.fill(k.p1)
            p.ell(36, -42, 22, 26); p.fill(k.p2)
            p.ell(26, -100, 16, 12); p.fill(k.p1)
        case .bicolor: // a white bib from the chin down
            p.ell(0, -52, 33, 58); p.fill(k.p1)
        case .points: // darker towards the legs
            p.ell(0, -4, 50, 24); p.fill(k.p2.opacity(0.28))
            p.ell(0, 2, 50, 16); p.fill(k.p2.opacity(0.28))
        }
        p.restore()
    }

    static func paw(_ p: Pen, _ k: Coat, _ x: CGFloat, _ y: CGFloat) {
        p.ell(x, y, 13, 9); p.fill(k.paw); p.stroke(k.line, 3)
        p.beginPath()
        p.moveTo(x - 4, y + 1); p.lineTo(x - 4, y + 7)
        p.moveTo(x + 4, y + 1); p.lineTo(x + 4, y + 7)
        p.stroke(k.line, 1.6)
    }

    static func dirtSpots(_ p: Pen, _ a: CGFloat, _ spots: [(CGFloat, CGFloat, CGFloat)]) {
        p.fillColor = .rgba(115, 80, 45, Double(0.5 * a))
        for s in spots { p.circ(s.0, s.1, s.2); p.fill() }
    }

    static func ear(_ p: Pen, _ k: Coat, side: CGFloat, fill: Color) {
        p.save()
        p.scale(side, 1)
        p.beginPath(); p.moveTo(-53, -12); p.lineTo(-45, -68); p.lineTo(-12, -44); p.closePath()
        p.fill(fill); p.stroke(k.line, 3.2)
        p.beginPath(); p.moveTo(-45, -22); p.lineTo(-41, -56); p.lineTo(-22, -41); p.closePath()
        p.fill(k.inner)
        p.restore()
    }

    static func drawHead(_ p: Pen, _ k: Coat, _ c: CatPose) {
        ear(p, k, side: 1, fill: k.ear(left: false))
        ear(p, k, side: -1, fill: k.ear(left: true))
        p.ell(0, 0, 60, 48); p.fill(k.fur)
        if let pattern = k.pattern {
            p.save()
            p.ell(0, 0, 60, 48); p.clip()
            switch pattern {
            case .stripes:
                p.beginPath()
                p.moveTo(0, -46); p.lineTo(0, -30); p.moveTo(-13, -44); p.lineTo(-10, -31); p.moveTo(13, -44); p.lineTo(10, -31)
                p.moveTo(-62, -2); p.lineTo(-47, 1); p.moveTo(-62, 8); p.lineTo(-48, 8)
                p.moveTo(62, -2); p.lineTo(47, 1); p.moveTo(62, 8); p.lineTo(48, 8)
                p.stroke(k.dark, 5)
            case .calico:
                p.ell(-38, -28, 32, 26); p.fill(k.p1)
                p.ell(42, -24, 28, 24); p.fill(k.p2)
            case .bicolor: // a white lower face and a blaze up between the eyes
                p.ell(0, 24, 44, 26); p.fill(k.p1)
                p.beginPath(); p.moveTo(-15, 8); p.quadTo(-4, -14, 0, -40); p.quadTo(4, -14, 15, 8); p.closePath()
                p.fill(k.p1)
            case .points: // a dark mask over the nose and round the eyes, fading out to the cheeks
                p.save()
                p.translate(0, 10); p.scale(1, 0.86)
                p.fillRadial([.init(color: k.p2, location: 0), .init(color: k.p2, location: 0.5),
                              .init(color: k.p2.opacity(0), location: 1)], radius: 52)
                p.circ(0, 0, 52); p.fill()
                p.restore()
            }
            p.restore()
        }
        p.ell(0, 0, 60, 48); p.stroke(k.line, 3.2)
        // muzzle
        p.ell(-12, 15, 16, 12); p.fill(k.muzzle)
        p.ell(12, 15, 16, 12); p.fill(k.muzzle)
        if c.blush {
            p.ell(-38, 14, 10, 6); p.fill(.rgba(255, 110, 140, 0.33))
            p.ell(38, 14, 10, 6); p.fill(.rgba(255, 110, 140, 0.33))
        }
        eye(p, k, c, -23, -6, side: -1)
        eye(p, k, c, 23, -6, side: 1)
        p.beginPath(); p.moveTo(-6.5, 6); p.lineTo(6.5, 6); p.lineTo(0, 13); p.closePath(); p.fill(k.nose)
        mouth(p, c.mouth)
        p.beginPath()
        p.moveTo(-26, 12); p.lineTo(-64, 4); p.moveTo(-26, 16); p.lineTo(-66, 17); p.moveTo(-26, 20); p.lineTo(-62, 29)
        p.moveTo(26, 12); p.lineTo(64, 4); p.moveTo(26, 16); p.lineTo(66, 17); p.moveTo(26, 20); p.lineTo(62, 29)
        p.stroke(k.whisker, 1.6)
        if c.dirt > 0.05 { dirtSpots(p, c.dirt, [(-34, -22, 7), (30, 26, 6), (44, -12, 5)]) }
        if let face = c.wear.face { drawFace(p, face) }
        if let head = c.wear.head { drawHat(p, head) }
    }

    static func eye(_ p: Pen, _ k: Coat, _ c: CatPose, _ ex: CGFloat, _ ey: CGFloat, side: CGFloat) {
        switch c.eyes {
        case .happy:
            p.beginPath(); p.arc(ex, ey + 5, 10, .pi * 1.15, .pi * 1.85); p.stroke(ink, 4); return
        case .closed:
            p.beginPath(); p.arc(ex, ey - 5, 10, .pi * 0.15, .pi * 0.85); p.stroke(ink, 4); return
        case .blink:
            p.beginPath(); p.moveTo(ex - 10, ey + 1); p.lineTo(ex + 10, ey + 1); p.stroke(ink, 4); return
        default:
            break
        }
        p.ell(ex, ey, 12, 14); p.fill(k.eye); p.stroke(ink, 2.4)
        let wide = c.eyes == .wide
        let lx = c.lookX * 3, ly = c.lookY * 3
        p.ell(ex + lx, ey + ly, wide ? 9 : 6.2, wide ? 12 : 10.5); p.fill(Color(hex: "1D1820"))
        p.circ(ex + lx - 3, ey + ly - 5, 3.6); p.fill(.white)
        p.circ(ex + lx + 3.2, ey + ly + 4, 1.7); p.fill(.white)
        if c.lid > 0 {
            p.save()
            p.ell(ex, ey, 12.6, 14.6); p.clip()
            p.fillColor = k.lid
            p.fillRect(ex - 14, ey - 16, 28, 2 + 28 * c.lid)
            p.restore()
            let lidY = ey - 14 + 28 * c.lid
            p.beginPath(); p.moveTo(ex - 11, lidY); p.lineTo(ex + 11, lidY); p.stroke(ink, 3)
        }
        if c.eyes == .sad {
            p.beginPath(); p.moveTo(ex + side * 11, ey - 19); p.lineTo(ex - side * 9, ey - 26); p.stroke(ink, 3.2)
            if c.tear && side < 0 { p.ell(ex + 3, ey + 21, 4, 6); p.fill(Color(hex: "7EC8F2")) }
        }
    }

    static func mouth(_ p: Pen, _ m: MouthKind) {
        switch m {
        case .flat:
            p.beginPath(); p.moveTo(-7, 21); p.lineTo(7, 21); p.stroke(ink, 2.6)
            return
        case .sad:
            p.beginPath(); p.moveTo(-8, 24); p.quadTo(0, 16, 8, 24); p.stroke(ink, 2.6)
            return
        case .open:
            p.ell(0, 22, 7, 8); p.fill(Color(hex: "7A2C3A"))
            p.ell(0, 26, 4.5, 3.4); p.fill(Color(hex: "F27C8C"))
        case .smile:
            break
        }
        p.beginPath()
        p.moveTo(0, 13); p.quadTo(-1, 21, -9, 20)
        p.moveTo(0, 13); p.quadTo(1, 21, 9, 20)
        p.stroke(ink, 2.6)
    }

    static func drawHat(_ p: Pen, _ id: String) {
        switch id {
        case "bow":
            p.save(); p.translate(36, -40); p.rotate(0.35)
            p.beginPath(); p.moveTo(0, 0); p.lineTo(-24, -14); p.lineTo(-22, 14); p.closePath()
            p.fill(Color(hex: "FF5C9A")); p.stroke(Color(hex: "B5306A"), 2.5)
            p.beginPath(); p.moveTo(0, 0); p.lineTo(24, -14); p.lineTo(22, 14); p.closePath()
            p.fill(Color(hex: "FF5C9A")); p.stroke(Color(hex: "B5306A"), 2.5)
            p.circ(0, 0, 6.5); p.fill(Color(hex: "FF8DBA")); p.stroke(Color(hex: "B5306A"), 2.5)
            p.restore()
        case "flowers":
            let cols = [Color(hex: "FF8FB1"), Color(hex: "FFD166"), Color.white, Color(hex: "C3A6FF")]
            for i in 0..<7 {
                let a = CGFloat.pi * 1.1 + CGFloat(i) * (CGFloat.pi * 0.8 / 6)
                let x = cos(a) * 54, y = sin(a) * 42 - 4
                p.ell(x + 7, y + 3, 7, 3.5, a); p.fill(Color(hex: "6BBF59"))
                p.fillColor = cols[i % 4]
                for j in 0..<5 {
                    let b = CGFloat(j) * .pi * 2 / 5
                    p.circ(x + cos(b) * 5.5, y + sin(b) * 5.5, 5); p.fill()
                }
                p.circ(x, y, 3.6); p.fill(Color(hex: "F4A300"))
            }
        case "hat":
            p.rr(-29, -106, 58, 66, 7); p.fill(Color(hex: "2B2B36")); p.stroke(Color(hex: "111118"), 2.5)
            p.fillColor = Color(hex: "E63946"); p.fillRect(-29, -56, 58, 11)
            p.ell(0, -40, 48, 10); p.fill(Color(hex: "2B2B36")); p.stroke(Color(hex: "111118"), 2.5)
            p.fillColor = .rgba(255, 255, 255, 0.18); p.fillRect(-21, -100, 7, 40)
        case "crown":
            p.beginPath()
            p.moveTo(-32, -40); p.lineTo(-34, -84); p.lineTo(-16, -62); p.lineTo(0, -92); p.lineTo(16, -62); p.lineTo(34, -84); p.lineTo(32, -40)
            p.closePath()
            p.fill(Color(hex: "F7C531")); p.stroke(Color(hex: "B07A06"), 2.5)
            p.circ(0, -51, 5.5); p.fill(Color(hex: "E63946"))
            p.circ(-19, -50, 4.5); p.fill(Color(hex: "3A86FF"))
            p.circ(19, -50, 4.5); p.fill(Color(hex: "2EC4B6"))
            p.fillColor = Color(hex: "FFE680")
            p.circ(-34, -86, 4); p.fill(); p.circ(0, -94, 4); p.fill(); p.circ(34, -86, 4); p.fill()
        default:
            break
        }
    }

    static func drawFace(_ p: Pen, _ id: String) {
        guard id == "glasses" else { return }
        let lens = Color.rgba(28, 28, 44, 0.94), frame = Color(hex: "0E0E16")
        p.rr(-41, -19, 35, 26, 10); p.fill(lens); p.stroke(frame, 2.5)
        p.rr(6, -19, 35, 26, 10); p.fill(lens); p.stroke(frame, 2.5)
        p.beginPath(); p.moveTo(-6, -10); p.quadTo(0, -15, 6, -10); p.stroke(frame, 2.5)
        p.beginPath(); p.moveTo(-41, -12); p.lineTo(-58, -18); p.moveTo(41, -12); p.lineTo(58, -18); p.stroke(frame, 2.5)
        p.beginPath(); p.moveTo(-34, -12); p.lineTo(-26, -4); p.moveTo(13, -12); p.lineTo(21, -4)
        p.stroke(.rgba(255, 255, 255, 0.55), 3)
    }

    static func drawNeck(_ p: Pen, _ id: String, _ y: CGFloat, _ bs: CGFloat) {
        let rx = 27 * bs + 4
        switch id {
        case "bell":
            p.beginPath(); p.ellipse(0, y - 5, rx, 9, from: 0.12 * .pi, to: 0.88 * .pi); p.stroke(Color(hex: "E63946"), 7)
            p.circ(0, y + 9, 8); p.fill(Color(hex: "FFD23F")); p.stroke(Color(hex: "B8860B"), 2)
            p.beginPath(); p.moveTo(-5, y + 10); p.lineTo(5, y + 10); p.stroke(Color(hex: "B8860B"), 2)
            p.circ(0, y + 13, 1.8); p.fill(Color(hex: "8A6508"))
        case "scarf":
            let blue = Color(hex: "3FA7D6")
            p.beginPath(); p.ellipse(0, y - 6, rx + 2, 10, from: 0.05 * .pi, to: 0.95 * .pi); p.stroke(blue, 13)
            p.save(); p.translate(rx * 0.45, y + 1); p.rotate(0.22)
            p.rr(-7, 0, 15, 36, 4); p.fill(blue)
            p.fillColor = .white; p.fillRect(-7, 11, 15, 4); p.fillRect(-7, 23, 15, 4)
            p.restore()
        default:
            break
        }
    }

    static func drawSleepingCat(_ p: Pen, x: CGFloat, y: CGFloat, s: CGFloat, coat k: Coat, stage: Stage,
                                wear: Wear, t: CGFloat, dirt: CGFloat) {
        let bs = stage.body
        let br = 1 + sin(t * 2.2) * 0.03
        p.save()
        p.translate(x, y)
        p.scale(s, s)
        p.save()
        p.scale(bs, bs)
        p.save()
        p.translate(0, -32); p.scale(1, br)
        p.ell(10, 0, 74, 34); p.fill(k.fur)
        if let pattern = k.pattern {
            p.save()
            p.ell(10, 0, 74, 34); p.clip()
            switch pattern {
            case .stripes:
                p.strokeColor = k.dark; p.lineWidth = 6
                for i in 0..<4 {
                    let sx = CGFloat(i) * 20
                    p.beginPath(); p.moveTo(sx, -36); p.quadTo(sx + 8, -22, sx + 4, -12); p.stroke()
                }
            case .calico:
                p.ell(40, -14, 30, 22); p.fill(k.p1)
                p.ell(-6, 14, 22, 16); p.fill(k.p2)
            case .bicolor: // the white chest, under the head
                p.ell(-38, 14, 34, 22); p.fill(k.p1)
            case .points:
                p.ell(10, 30, 74, 16); p.fill(k.p2.opacity(0.3))
            }
            p.restore()
        }
        p.ell(10, 0, 74, 34); p.stroke(k.line, 3.2)
        p.restore()
        p.beginPath(); p.moveTo(78, -26); p.quadTo(92, 2, 30, 0); p.quadTo(0, -1, -16, -6)
        p.stroke(k.line, 20)
        p.stroke(k.tail, 14)
        paw(p, k, 24, -6)
        p.restore()
        p.save()
        p.translate(-50 * bs, -50 * bs); p.rotate(-0.15); p.scale(stage.head * 0.88, stage.head * 0.88)
        drawHead(p, k, CatPose(coat: k, stage: stage, eyes: .closed, mouth: .smile, blush: true, wear: wear, dirt: dirt))
        p.restore()
        p.restore()
    }

    static func pawPrint(_ p: Pen, _ x: CGFloat, _ y: CGFloat, _ r: CGFloat) {
        p.ell(x, y, r, r * 0.85); p.fill()
        p.circ(x - r, y - r * 1.2, r * 0.42); p.fill()
        p.circ(x - r * 0.35, y - r * 1.6, r * 0.42); p.fill()
        p.circ(x + r * 0.35, y - r * 1.6, r * 0.42); p.fill()
        p.circ(x + r, y - r * 1.2, r * 0.42); p.fill()
    }

    static func poo(_ p: Pen, _ x: CGFloat, _ y: CGFloat) {
        let fill = Color(hex: "8B5A2B"), line = Color(hex: "5A3A1A")
        p.ell(x, y, 13, 6); p.fill(fill); p.stroke(line, 2)
        p.ell(x, y - 6, 9, 5); p.fill(fill); p.stroke(line, 2)
        p.ell(x + 1, y - 11, 5, 4); p.fill(fill); p.stroke(line, 2)
        p.circ(x - 4, y - 7, 1.8); p.fill(.rgba(255, 255, 255, 0.35))
    }
}
