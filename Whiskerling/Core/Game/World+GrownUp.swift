import SwiftUI

/// A party with balloons and a cake, for growing up or for a birthday (#17).
struct Party {
    enum Kind: Equatable { case grownUp, birthday(Int) }
    static let length: CGFloat = 30
    var kind: Kind
    var t: CGFloat = Party.length
}

/// The ball of yarn a grown-up cat brings over to the child (#17).
struct Toy {
    var x: CGFloat, y: CGFloat
    var carried = false
    var t: CGFloat = 40
}

/// The grown-up cat (#17): a party when it grows up and on each birthday, and habits a kitten
/// doesn't have. None of it asks for anything, and nothing is missed if the child isn't there.
extension World {
    // MARK: Parties

    func startParty(_ kind: Party.Kind) {
        party = Party(kind: kind)
        save?.grownUpParty = true
        cat.happyT = 2
        if kind == .grownUp { say(L10n.partyForMe, 4) }
    }

    /// A cat that grew up before there were parties, in 1.0, gets its party late: on the first
    /// visit after the update, once, when the lights are on and the cat is in the living room,
    /// where the party is.
    func checkLateParty() {
        guard let s = save, s.stage == Catalog.stages.count - 1, s.grownUpParty != true,
              !s.lightsOff, room == .living, mode == .normal else { return }
        if party == nil {
            sound.fanfare()
            startParty(.grownUp)
        } else {
            save!.grownUpParty = true // a birthday party is on already
        }
        persist()
    }

    /// One birthday a year on the adoption date, celebrated once, also on the next visit when the
    /// app wasn't open on the day itself.
    func checkBirthday(now: Date = Date()) {
        guard let s = save else { return }
        let passed = SaveState.birthdaysPassed(born: s.born, at: now)
        guard passed > (s.birthdays ?? 0) else { return }
        save!.birthdays = passed
        post(.toast(L10n.happyBirthday(s.name)))
        sound.fanfare()
        addHearts(5)
        burst(.sparkle, cat.x, cat.y - 150 * U, count: 20, speed: 220 * U, life: 1.2, size: 10 * U)
        startParty(.birthday(passed))
        meowSay(L10n.birthdayAge(passed), 4)
        persist()
    }

    /// Back on the floor between the litter box and the basket, clear of the bowl and the rug.
    var partySpot: CGPoint { CGPoint(x: min(max(W * 0.42, G.minX), G.maxX), y: H * 0.7) }

    func updateGrownUp(_ dt: CGFloat) {
        if var p = party { p.t -= dt; party = p.t > 0 ? p : nil }
        if var t = toy {
            if t.carried && cat.walk?.tag != "toy" { t.carried = false; t.x = cat.x; t.y = G.catY } // interrupted: dropped
            if t.carried {
                let hp = catHeadPos()
                t.x = hp.x + cat.look * 26 * catScale; t.y = hp.y + 58 * stage.head * catScale
            } else {
                t.t -= dt
            }
            toy = t.t > 0 ? t : nil
        }
        if habitT > 0 { habitT -= dt }
    }

    // MARK: Habits

    /// Now and then a content grown-up cat naps on the rug, stretches with a yawn, or brings the
    /// child a ball of yarn. Called when the idle cat decides what to do next.
    func startHabit() -> Bool {
        guard let s = save, s.stage == Catalog.stages.count - 1, habitT <= 0, mode == .normal, !s.lightsOff,
              room == .living, mood == "happy", bubble == nil, Double.random(in: 0...1) < 0.35 else { return false }
        habitT = .random(in: 60...120)
        switch Int.random(in: 0..<3) {
        case 0:
            cat.activity = .nap; cat.timer = .random(in: 14...22); cat.zT = 1
        case 1:
            cat.activity = .stretch; cat.timer = World.stretchTime
        default:
            fetchToy()
        }
        return true
    }

    static let stretchTime: CGFloat = 1.8

    func fetchToy() {
        toy = Toy(x: G.bed.x - 20 * U, y: G.catY)
        goTo(G.bed.x - 70 * U, G.catY, speed: 0.8, tag: "fetch") { [weak self] in
            guard let self, var t = self.toy else { return }
            t.carried = true
            self.toy = t
            self.goTo(min(max(self.W * 0.48, self.G.minX), self.G.maxX), self.G.catY, speed: 0.7, tag: "toy") { [weak self] in
                guard let self, var t = self.toy else { return }
                t.carried = false
                t.x = self.cat.x + 56 * self.catScale; t.y = self.G.catY + 4 * self.U
                self.toy = t
                self.cat.happyT = 1.2
                self.meowSay(L10n.toyForYou, 2.8)
            }
        }
    }

    func updateHabit(_ dt: CGFloat) {
        cat.timer -= dt
        if cat.activity == .nap {
            cat.zT -= dt
            if cat.zT <= 0 {
                cat.zT = 1.6
                spawn(.zzz, cat.x - 40 * catScale, cat.y - 80 * catScale, vx: 12, vy: -22, life: 2.2, size: 16 * U)
            }
        }
        guard cat.timer <= 0 else { return }
        if cat.activity == .stretch { say(L10n.stretchLine, 2.2) }
        cat.activity = .idle; cat.timer = .random(in: 2...4)
    }

    /// A tap or a stroke wakes a napping cat.
    func wakeFromNap() -> Bool {
        guard cat.activity == .nap else { return false }
        cat.activity = .idle; cat.timer = 3; cat.happyT = 0.8
        meowSay(L10n.napWake, 2.2)
        return true
    }

    // MARK: Drawing

    func drawParty(_ p: Pen) {
        guard let party else { return }
        let spot = partySpot, s = objScale(spot.y)
        p.save()
        p.alpha = Double(max(0, min(party.t / 1.5, 1, (Party.length - party.t) / 0.6)))
        // three balloons on strings, tied to the cake
        let colors = [Color(hex: "FF8FB1"), Color(hex: "FFD84D"), Color(hex: "7FB7D9")]
        for i in 0..<3 {
            let fi = CGFloat(i - 1)
            let sway = reduceMotion ? 0 : sin(T * 0.9 + CGFloat(i) * 1.7) * 6
            let bx = spot.x + (fi * 36 + sway) * s, by = spot.y - (200 + CGFloat(i % 2) * 36) * s
            p.beginPath(); p.moveTo(spot.x + fi * 10 * s, spot.y - 70 * s)
            p.quadTo(bx - 6 * s, by + 70 * s, bx, by + 30 * s); p.stroke(.rgba(120, 90, 70, 0.6), 1.5)
            p.ell(bx, by, 22 * s, 28 * s); p.fill(colors[i])
            p.ell(bx - 7 * s, by - 9 * s, 6 * s, 9 * s, -0.4); p.fill(.rgba(255, 255, 255, 0.45))
            p.beginPath(); p.moveTo(bx - 4 * s, by + 31 * s); p.lineTo(bx + 4 * s, by + 31 * s); p.lineTo(bx, by + 25 * s)
            p.closePath(); p.fill(colors[i])
        }
        // the cake on a plate, with a candle for each year (one for growing up)
        p.translate(spot.x, spot.y); p.scale(s, s)
        p.ell(0, 0, 60, 12); p.fill(.white); p.stroke(Color(hex: "E6D5C3"), 2)
        p.rr(-46, -46, 92, 44, 10); p.fill(Color(hex: "F6C28B")); p.stroke(Color(hex: "C98B4F"), 2)
        p.rr(-32, -72, 64, 28, 8); p.fill(Color(hex: "FFE0EA")); p.stroke(Color(hex: "E6A1B6"), 2)
        p.fillColor = Color(hex: "FFE0EA")
        p.rr(-46, -48, 92, 10, 5); p.fill()
        for k in 0..<5 { p.ell(-36 + CGFloat(k) * 18, -38, 5, 7); p.fill() }
        let candles: Int
        if case .birthday(let n) = party.kind { candles = min(max(n, 1), 5) } else { candles = 1 }
        for k in 0..<candles {
            let cx = CGFloat(k) * 12 - CGFloat(candles - 1) * 6
            p.rr(cx - 2.5, -92, 5, 20, 2); p.fill(k % 2 == 0 ? Color(hex: "7FB7D9") : Color(hex: "FF8FB1"))
            let flicker = reduceMotion ? 1 : 1 + sin(T * 14 + CGFloat(k)) * 0.12
            p.ell(cx, -98, 3.5 * flicker, 6 * flicker); p.fill(Color(hex: "FFC94D"))
        }
        p.restore()
    }

    func drawToy(_ p: Pen) {
        guard let toy else { return }
        let s = toy.carried ? catScale * 0.9 : objScale(toy.y)
        p.save()
        p.alpha = Double(min(toy.t / 1.5, 1))
        p.translate(toy.x, toy.y - 12 * s); p.scale(s, s)
        if !toy.carried { p.ell(0, 12, 16, 4); p.fill(.rgba(90, 55, 30, 0.18)) }
        p.circ(0, 0, 13); p.fill(Color(hex: "E5484D"))
        p.beginPath()
        p.moveTo(-10, -6); p.quadTo(0, 2, 9, -8)
        p.moveTo(-12, 3); p.quadTo(0, 10, 12, 1)
        p.moveTo(-4, -12); p.quadTo(2, 0, -2, 12)
        p.stroke(Color(hex: "B8323A"), 2)
        p.beginPath(); p.moveTo(10, 8); p.quadTo(22, 14, 26, 6); p.stroke(Color(hex: "E5484D"), 2)
        p.restore()
    }
}
