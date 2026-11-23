import SwiftUI

/// Baking fish cookies in the kitchen (#38). Every tap moves it on and every batch turns out:
/// fish and flour into the bowl, a stir, six fish cut out, the oven, and the cookies go into the
/// jar, where Feed finds them.
struct BakeGame {
    enum Step { case ingredients, stir, cut, oven, baking, done }
    static let batch = 6
    static let slideTime: CGFloat = 0.6, bakeTime: CGFloat = 3.2, doneTime: CGFloat = 1.4
    var step = Step.ingredients
    var fishIn = false, flourIn = false
    /// 0 to 1.
    var stir: CGFloat = 0
    /// Which of the six places on the dough have been cut out.
    var cut: [Bool] = Array(repeating: false, count: BakeGame.batch)
    var t: CGFloat = 0
    var finished = false
}

extension World {
    // MARK: Where things are, on a board at the front

    var bakeBoard: CGRect {
        let w = min(W * 0.66, 640 * U), h = min(H * 0.3, 250 * U)
        return CGRect(x: W / 2 - w / 2, y: H - h - 14 * U, width: w, height: h)
    }
    var bakeBowlPoint: CGPoint { CGPoint(x: bakeBoard.midX, y: bakeBoard.midY + 6 * U) }
    var bakeFishPoint: CGPoint { CGPoint(x: bakeBoard.minX + bakeBoard.width * 0.16, y: bakeBoard.midY + 10 * U) }
    var bakeFlourPoint: CGPoint { CGPoint(x: bakeBoard.maxX - bakeBoard.width * 0.16, y: bakeBoard.midY + 4 * U) }
    /// The six cookies' places, on the dough and later the tray.
    func cookieSlot(_ i: Int) -> CGPoint {
        let b = bakeBoard, col = CGFloat(i % 3) - 1, row = CGFloat(i / 3) - 0.5
        return CGPoint(x: b.midX + col * 92 * U, y: b.midY + row * 62 * U + 4 * U)
    }

    /// The oven glows while it bakes: 0 to 1.
    var ovenGlow: CGFloat {
        guard let g = baking, g.step == .baking else { return 0 }
        return reduceMotion ? 1 : 0.75 + 0.25 * sin(T * 4)
    }

    // MARK: The game

    @discardableResult
    func startBake() -> Bool {
        guard let s = save, !s.lightsOff, mode == .normal, isPro, room == .kitchen else { return false }
        if cookieJar >= World.jarSize { meowSay(L10n.jarFull, 2.6); return false }
        setMode(.bake)
        cat.walk = nil; cat.jump = nil; cat.petT = 0
        // up onto the counter, to watch
        cat.x = kCounterSeat.x; cat.y = kCounterSeat.y; cat.activity = .bake; cat.hop = 0.35; cat.look = 0.6
        sound.jump()
        baking = BakeGame()
        meowSay(L10n.bakeStart, 2.4)
        post(.hint(L10n.bakeHintIngredients))
        return true
    }

    func tapBake(_ p: CGPoint) {
        guard var g = baking, !g.finished else { return }
        switch g.step {
        case .ingredients:
            // the one tapped, or else the next one missing: every tap moves it on
            let fish = hypot(p.x - bakeFishPoint.x, p.y - bakeFishPoint.y) < 80 * U
            let flour = hypot(p.x - bakeFlourPoint.x, p.y - bakeFlourPoint.y) < 80 * U
            if (fish || !g.fishIn) && !g.fishIn && !flour {
                g.fishIn = true
                fridgeOpenT = 1.4
                pour(from: bakeFishPoint, color: .sparkle)
            } else if !g.flourIn {
                g.flourIn = true
                pour(from: bakeFlourPoint, color: .bubble)
            } else if !g.fishIn {
                g.fishIn = true
                pour(from: bakeFishPoint, color: .sparkle)
            }
            if g.fishIn && g.flourIn { g.step = .stir; g.t = 0; post(.hint(L10n.bakeHintStir)) }
        case .stir:
            g = stirred(g, by: 0.12)
        case .cut:
            // the free place nearest the tap
            let free = (0..<BakeGame.batch).filter { !g.cut[$0] }
            guard let i = free.min(by: { hypot(cookieSlot($0).x - p.x, cookieSlot($0).y - p.y) < hypot(cookieSlot($1).x - p.x, cookieSlot($1).y - p.y) }) else { break }
            g.cut[i] = true
            let c = cookieSlot(i)
            burst(.sparkle, c.x, c.y, count: 6, speed: 110 * U, life: 0.6, size: 7 * U)
            sound.pop()
            if !g.cut.contains(false) { g.step = .oven; g.t = 0; post(.hint(L10n.bakeHintOven)); sound.chime() }
        case .oven:
            g.step = .baking; g.t = 0
            sound.jump()
            post(.hint(L10n.bakeHintBaking))
        case .baking, .done:
            break
        }
        baking = g
        cat.happyT = 0.6
        hudDue = true
    }

    /// Stirring with a finger going round in the bowl.
    func stirBake(_ p: CGPoint, _ d: CGFloat) {
        guard let g = baking, g.step == .stir, hypot(p.x - bakeBowlPoint.x, p.y - bakeBowlPoint.y) < 130 * U else { return }
        bakeFinger = p
        baking = stirred(g, by: d / (650 * U))
    }

    private func stirred(_ game: BakeGame, by amount: CGFloat) -> BakeGame {
        var g = game
        let before = g.stir
        g.stir = min(1, g.stir + amount)
        if Int(before * 6) != Int(g.stir * 6) { sound.pop() }
        if g.stir >= 1 {
            g.step = .cut; g.t = 0
            burst(.sparkle, bakeBowlPoint.x, bakeBowlPoint.y - 30 * U, count: 10, speed: 150 * U, life: 0.8, size: 8 * U)
            sound.chime()
            post(.hint(L10n.bakeHintCut))
        }
        return g
    }

    private func pour(from: CGPoint, color: ParticleKind) {
        sound.pop()
        for _ in 0..<8 {
            spawn(color, from.x + .random(in: -12...12) * U, from.y - 20 * U,
                  vx: (bakeBowlPoint.x - from.x) * 1.4, vy: -.random(in: 40...90) * U, life: 0.6, size: .random(in: 4...7) * U)
        }
    }

    func updateBake(_ dt: CGFloat) {
        guard var g = baking else { return }
        g.t += dt
        switch g.step {
        case .baking where g.t >= BakeGame.slideTime + BakeGame.bakeTime:
            g.step = .done; g.t = 0
            sound.chime()
            burst(.sparkle, kOven.midX, kOven.midY, count: 12, speed: 160 * U, life: 0.9, size: 8 * U)
            post(.hint(L10n.bakeHintDone))
        case .done where g.t >= BakeGame.doneTime && !g.finished:
            g.finished = true
            baking = g
            finishBake()
            return
        default:
            break
        }
        baking = g
    }

    /// The cookies go into the jar. Now and then the cat takes one first.
    private func finishBake() {
        var made = BakeGame.batch
        let stole = Double.random(in: 0...1) < 0.35
        if stole { made -= 1 }
        save!.cookies = min(World.jarSize, cookieJar + made)
        for i in 0..<BakeGame.batch {
            let c = cookieSlot(i)
            spawn(.sparkle, c.x, c.y, vx: (kJar.x - c.x) * 1.2, vy: (kJar.y - c.y) * 1.2, life: 0.8, size: 8 * U)
        }
        addHearts(1, at: CGPoint(x: kJar.x, y: kJar.y - 90 * U))
        sound.fanfare()
        cat.happyT = 2
        if stole {
            save!.needs.food = min(100, save!.needs.food + 4)
            meowSay(L10n.stoleCookie, 2.4)
        } else {
            meowSay(L10n.bakeBye, 2.4)
        }
        post(.toast(L10n.cookiesInJar(made)))
        modeEndT = 2.2
        hudDue = true
    }

    // MARK: Drawing

    func drawBake(_ p: Pen) {
        guard let g = baking else { return }
        let b = bakeBoard
        p.rr(b.minX, b.minY, b.width, b.height, 22 * U); p.fill(Color(hex: "E2B47E")); p.stroke(Color(hex: "A97B4B"), 3)
        p.rr(b.minX + 10 * U, b.minY + 10 * U, b.width - 20 * U, b.height - 20 * U, 16 * U); p.stroke(.rgba(255, 255, 255, 0.35), 2)
        switch g.step {
        case .ingredients, .stir:
            drawBigBowl(p, g)
            if !g.fishIn { drawFishDish(p, bakeFishPoint) }
            if !g.flourIn { drawFlourBag(p, bakeFlourPoint) }
            if g.step == .stir, let sp = bakeFinger {
                p.beginPath(); p.moveTo(sp.x, sp.y); p.lineTo(sp.x + 40 * U, sp.y - 70 * U); p.stroke(Color(hex: "C99A6B"), 8 * U)
                p.ell(sp.x, sp.y, 12 * U, 8 * U); p.fill(Color(hex: "C99A6B"))
            }
        case .cut:
            p.rr(b.midX - 150 * U, b.midY - 66 * U, 300 * U, 136 * U, 40 * U); p.fill(Color(hex: "F3DDB5")); p.stroke(Color(hex: "D6B98A"), 2)
            for i in 0..<BakeGame.batch {
                let c = cookieSlot(i)
                if g.cut[i] {
                    DecorArt.fishCookie(p, c.x, c.y, U * 1.6, golden: false)
                } else {
                    p.dash = [6 * U, 5 * U]
                    p.ell(c.x, c.y, 30 * U, 18 * U); p.stroke(.rgba(169, 123, 75, 0.45), 2)
                    p.dash = []
                }
            }
        case .oven, .baking, .done:
            // the tray: on the board, sliding into the oven, and back out with golden cookies
            var k: CGFloat = 0
            if g.step == .baking { k = reduceMotion ? 1 : min(g.t / BakeGame.slideTime, 1) }
            if g.step == .done { k = 0 }
            let from = CGPoint(x: b.midX, y: b.midY), to = CGPoint(x: kOven.midX, y: kOven.midY)
            let at = CGPoint(x: from.x + (to.x - from.x) * k, y: from.y + (to.y - from.y) * k), s = 1 - 0.7 * k
            if k < 1 {
                p.save(); p.translate(at.x, at.y); p.scale(s, s); p.translate(-from.x, -from.y)
                p.rr(b.midX - 160 * U, b.midY - 70 * U, 320 * U, 144 * U, 10 * U); p.fill(Color(hex: "C9CDD6")); p.stroke(Color(hex: "8E949F"), 3)
                for i in 0..<BakeGame.batch {
                    let c = cookieSlot(i)
                    DecorArt.fishCookie(p, c.x, c.y, U * 1.6, golden: g.step == .done)
                }
                p.restore()
            }
            if g.step == .baking && k >= 1 {
                let dots = Int(g.t * 2) % 4
                p.text(String(repeating: "•", count: dots), kOven.midX, kOven.minY - 18 * U, size: 26 * U, weight: .heavy,
                       color: Color(hex: "8A5A3C"))
            }
        }
    }

    private func drawBigBowl(_ p: Pen, _ g: BakeGame) {
        let c = bakeBowlPoint
        p.save(); p.translate(c.x, c.y); p.scale(U * 2.4, U * 2.4)
        p.beginPath(); p.moveTo(-40, -16); p.quadTo(-38, 30, 0, 30); p.quadTo(38, 30, 40, -16); p.closePath()
        p.fill(Color(hex: "F28FA8")); p.stroke(Color(hex: "C25B78"), 2)
        p.ell(0, -16, 40, 10); p.fill(Color(hex: "F8C3D0")); p.stroke(Color(hex: "C25B78"), 1.5)
        // what's inside: fish and flour apart, turning into dough as it's stirred
        if g.fishIn || g.flourIn {
            let dough = Color(hex: "F3DDB5")
            p.ell(0, -15, 33, 7); p.fill(dough.opacity(g.step == .stir ? Double(0.3 + 0.7 * g.stir) : 0.25))
            if g.fishIn && g.stir < 0.9 { p.ell(-12, -15, 12 * (1 - g.stir), 4 * (1 - g.stir)); p.fill(Color(hex: "F4A259")) }
            if g.flourIn && g.stir < 0.9 { p.ell(12, -15, 12 * (1 - g.stir), 4 * (1 - g.stir)); p.fill(.white) }
            if g.step == .stir {
                let a = g.stir * 14
                p.beginPath(); p.arc(0, -15, 20 * (1 - g.stir * 0.4), a, a + 2.2); p.stroke(.rgba(169, 123, 75, 0.5), 1.5)
            }
        }
        p.restore()
    }

    private func drawFishDish(_ p: Pen, _ at: CGPoint) {
        p.save(); p.translate(at.x, at.y); p.scale(U * 1.6, U * 1.6)
        p.ell(0, 6, 40, 12); p.fill(.white); p.stroke(Color(hex: "9CC3D6"), 2)
        p.ell(0, -4, 22, 10); p.fill(Color(hex: "F4A259"))
        p.beginPath(); p.moveTo(-18, -4); p.lineTo(-32, -14); p.lineTo(-32, 6); p.closePath(); p.fill()
        p.circ(10, -6, 2.5); p.fill(Color(hex: "2B2027"))
        p.restore()
    }

    private func drawFlourBag(_ p: Pen, _ at: CGPoint) {
        p.save(); p.translate(at.x, at.y); p.scale(U * 1.6, U * 1.6)
        p.rr(-26, -38, 52, 56, 8); p.fill(Color(hex: "FBF6EC")); p.stroke(Color(hex: "C9B79A"), 2)
        p.beginPath(); p.moveTo(-26, -30); p.quadTo(0, -44, 26, -30); p.stroke(Color(hex: "C9B79A"), 2)
        p.circ(0, -8, 10); p.fill(Color(hex: "F4D27A"))
        p.restore()
    }
}
