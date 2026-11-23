import SwiftUI

/// The second cat (#21). It lives alongside the cat shown in the top bar: it comes to the bowl and
/// the basket, uses the litter box, joins the games, and now and then does something together with
/// the first cat. A tap on it shows it in the top bar instead, which swaps the two (`switchCats`).
extension World {
    var hasCompanion: Bool { save?.companion != nil }
    var buddyStage: Stage { Catalog.stages[save?.companion?.stage ?? 0] }
    var buddyCoat: Coat { Catalog.coat(save?.companion?.coat ?? "orange") }
    var buddyScale: CGFloat { objScale(buddy.y) * buddyStage.size }

    /// Whether the cat can get a friend: it has to be grown up, and alone. Pro is checked by the model.
    var canAdopt: Bool {
        guard let s = save else { return false }
        return s.companion == nil && s.stage == Catalog.stages.count - 1
    }

    /// Two cats visit the litter box a little more often between them than one cat does.
    var poopEveryNow: CGFloat { hasCompanion ? World.poopEvery * 0.75 : World.poopEvery }

    /// In the basket with the other cat, curled up the other way round, head to tail.
    var buddyBedSpot: CGPoint { CGPoint(x: G.bed.x + 40 * objScale(G.bed.y), y: G.bed.y - 26 * objScale(G.bed.y)) }
    private var buddyBowlSpot: CGPoint { CGPoint(x: G.bowl.x - 78 * objScale(G.catY), y: G.catY) }

    // MARK: Adopting and switching

    func adopt(name: String, coat: String) {
        guard save != nil, canAdopt else { return }
        if mode != .normal { setMode(.normal) }
        if room != .living { enterRoom(.living) }
        let friend = save!.name
        save!.companion = CatRecord(name: name, coat: coat, born: Date())
        // the kitten comes in from the side, and is the one shown
        buddy = CatState()
        buddy.x = min(max(cat.x + 200 * U, G.minX), G.maxX); buddy.y = G.catY
        switchCats()
        cat.x = G.maxX + 80 * U
        goTo(min(max(buddy.x + 150 * U, G.minX), G.maxX), G.catY, speed: 0.9)
        buddy.happyT = 2; buddy.look = 0.8
        buddySay(L10n.newFriend(name), 3)
        burst(.sparkle, buddy.x, buddy.y - 150 * U, count: 14, speed: 180 * U, life: 1, size: 9 * U)
        sound.fanfare()
        post(.toast(L10n.adopted(name, friend)))
        persist()
        hudDue = true
    }

    /// Shows the other cat in the top bar. What either was on its way to do (the bowl, the litter
    /// box) is dropped, since the swap changes which cat does it.
    func switchCats() {
        guard save?.companion != nil else { return }
        settle(&cat); settle(&buddy)
        save!.swapCats()
        swap(&cat, &buddy)
        if var b = bubble { b.buddy.toggle(); bubble = b }
        sound.stopPurr(); cat.petT = 0
        hudDue = true
        persist()
    }

    private func settle(_ c: inout CatState) {
        if [.eat, .poop, .stretch].contains(c.activity) || (c.activity == .walk && c.walk?.tag != nil) {
            c.walk = nil; c.activity = .idle; c.timer = 1.5
        }
        c.jump = nil
    }

    func buddySay(_ text: String, _ dur: CGFloat = 3.2) {
        bubble = Bubble(text: text, t: dur, d: dur, buddy: true)
        buddy.mouthT = 0.45
        sound.meow(pitch: buddyStage.pitch * Float.random(in: 0.95...1.08))
    }

    // MARK: Growing (each from its own adoption date)

    func checkBuddyStage() {
        guard let rec = save?.companion else { return }
        let st = Catalog.stage(born: rec.born, at: Date())
        guard st > rec.stage else { return }
        save!.companion!.stage = st
        post(.toast(st == 1 ? L10n.grewYoung(rec.name) : L10n.grewAdult(rec.name)))
        sound.fanfare()
        addHearts(5, at: CGPoint(x: buddy.x, y: buddy.y - 160 * U))
        burst(.sparkle, buddy.x, buddy.y - 150 * U, count: 20, speed: 220 * U, life: 1.2, size: 10 * U)
        if st == Catalog.stages.count - 1 {
            party = Party(kind: .grownUp)
            save!.companion!.grownUpParty = true
            buddySay(L10n.partyForMe, 4)
        }
    }

    func checkBuddyBirthday(now: Date = Date()) {
        guard let rec = save?.companion else { return }
        let passed = SaveState.birthdaysPassed(born: rec.born, at: now)
        guard passed > (rec.birthdays ?? 0) else { return }
        save!.companion!.birthdays = passed
        post(.toast(L10n.happyBirthday(rec.name)))
        sound.fanfare()
        addHearts(5, at: CGPoint(x: buddy.x, y: buddy.y - 160 * U))
        party = Party(kind: .birthday(passed))
        buddySay(L10n.birthdayAge(passed), 4)
        persist()
    }

    // MARK: Behaviour

    func placeBuddy() {
        guard hasCompanion else { return }
        buddy = CatState()
        if save!.lightsOff {
            buddy.x = buddyBedSpot.x; buddy.y = buddyBedSpot.y; buddy.activity = .sleep; buddy.zT = 1.4
        } else {
            buddy.x = min(max(cat.x - 180 * U, G.minX), G.maxX); buddy.y = G.catY
        }
    }

    /// The other cat follows into the room the first one went to.
    func buddyFollows(into r: Room) {
        guard hasCompanion else { return }
        buddy.walk = nil; buddy.jump = nil; buddy.activity = .idle
        buddy.x = r == .living ? G.maxX + 40 * U : G.minX - 40 * U
        buddy.y = G.catY
        buddyGo(W * (r == .living ? 0.7 : 0.35), G.catY, speed: 0.9)
    }

    func buddyGo(_ x: CGFloat, _ y: CGFloat, speed: CGFloat = 1, tag: String? = nil) {
        buddy.walk = Walk(x: x, y: y, speed: speed, tag: tag, after: nil)
        buddy.activity = .walk
    }

    func snapBuddy() {
        guard hasCompanion else { return }
        if buddy.activity == .sleep { buddy.x = buddyBedSpot.x; buddy.y = buddyBedSpot.y; return }
        buddy.x = min(max(buddy.x == 0 ? W * 0.4 : buddy.x, G.minX), G.maxX)
        buddy.y = G.catY
        if var w = buddy.walk {
            switch w.tag {
            case "bed": w.x = buddyBedSpot.x; w.y = buddyBedSpot.y
            case "bowl": w.x = buddyBowlSpot.x; w.y = G.catY
            case "litter": w.x = G.litter.x; w.y = G.litter.y
            default: w.x = min(max(w.x, G.minX), G.maxX); w.y = G.catY
            }
            buddy.walk = w
        }
    }

    /// The bowl was just filled: the other cat comes too, if it isn't full or asleep.
    func callBuddyToBowl() {
        guard let rec = save?.companion, rec.needs.food < 96, buddy.activity != .sleep, buddy.activity != .nap else { return }
        buddyServing = bowlServing
        buddyGo(buddyBowlSpot.x, buddyBowlSpot.y, speed: 1.1, tag: "bowl")
    }

    func updateBuddy(_ dt: CGFloat) {
        guard let rec = save?.companion else { return }
        buddy.t += dt
        buddy.tail += dt * ((buddy.activity == .walk || buddy.moving) ? 5 : 1.8)
        buddy.blinkT -= dt
        if buddy.blinkT <= 0 { buddy.blink = 0.15; buddy.blinkT = .random(in: 2.5...5.5) }
        for kp in [\CatState.blink, \.hop, \.happyT, \.scrubT, \.mouthT, \.petT] where buddy[keyPath: kp] > 0 {
            buddy[keyPath: kp] -= dt
        }
        if togetherT > 0 { togetherT -= dt }

        // the light is off: into the basket beside the other cat
        if save!.lightsOff {
            if buddy.activity != .sleep && buddy.walk?.tag != "bed" {
                buddy.jump = nil
                buddyGo(buddyBedSpot.x, buddyBedSpot.y, speed: 1, tag: "bed")
            }
        } else if buddy.activity == .sleep {
            buddy.activity = .idle
            buddyGo(G.bed.x - 240 * U, G.catY, speed: 0.8)
        }

        switch mode {
        case .play:
            // after the feather too, from the other side
            if buddy.activity != .walk || buddy.walk?.tag == nil { glide(toward: feather.x + (feather.x > W / 2 ? -1 : 1) * 170 * U, dt) }
            buddy.activity = .play
            return
        case .fish:
            glide(toward: clampToPond(cat.x + (cat.x > G.pond.x ? -1 : 1) * 170 * U), dt)
            buddy.activity = .fish
            return
        case .hide, .wash, .bake:
            // watches the game or the bath, and stays put
            if buddy.activity == .walk { stepBuddy(dt) } else if buddy.activity != .sleep { buddy.activity = .idle }
            return
        case .normal:
            if [.play, .fish, .hide, .wash].contains(buddy.activity) { buddy.activity = .idle; buddy.timer = 1; buddy.moving = false }
        }

        switch buddy.activity {
        case .walk:
            stepBuddy(dt)
        case .idle:
            buddy.timer -= dt
            if buddy.timer <= 0 && buddy.petT <= 0 { decide(rec) }
        case .eat:
            buddy.timer -= dt
            buddy.eatT -= dt
            if bowl != nil && cat.activity != .eat { bowl!.amount = min(max(buddy.timer / 3.2, 0), 1) }
            if buddy.eatT <= 0 {
                buddy.eatT = 0.45
                sound.nom()
                spawn(.text, buddy.x + 50 * U, buddy.y - 120 * U, vx: .random(in: -10...20), vy: -40, life: 0.9,
                      size: 16 * U, text: L10n.nomWords.randomElement()!)
            }
            if buddy.timer <= 0 { buddyAte() }
        case .poop:
            buddy.timer -= dt
            if buddy.timer <= 0 {
                if save!.poop < 3 { save!.poop += 1 }
                sound.plop()
                buddyGo(G.litter.x + 220 * U, G.catY, speed: 0.9)
            }
        case .sleep:
            buddy.x = buddyBedSpot.x; buddy.y = buddyBedSpot.y
            buddy.zT -= dt
            if buddy.zT <= 0 {
                buddy.zT = 1.6
                spawn(.zzz, buddy.x + 50 * buddyScale, buddy.y - 90 * buddyScale, vx: 12, vy: -24, life: 2.2, size: 15 * U)
            }
        case .nap:
            buddy.timer -= dt
            buddy.zT -= dt
            if buddy.zT <= 0 {
                buddy.zT = 1.8
                spawn(.zzz, buddy.x - 36 * buddyScale, buddy.y - 70 * buddyScale, vx: -12, vy: -22, life: 2, size: 14 * U)
            }
            if buddy.timer <= 0 { buddy.activity = .idle; buddy.timer = .random(in: 2...4) }
        default:
            buddy.activity = .idle
        }
    }

    /// Eases sideways toward `x`, like the cat after the fish.
    private func glide(toward x: CGFloat, _ dt: CGFloat) {
        let tx = min(max(x, G.minX), G.maxX)
        let want = min(max((tx - buddy.x) * 2.2, -220 * U), 220 * U)
        buddy.vx += (want - buddy.vx) * min(1, dt * 8)
        buddy.x = min(max(buddy.x + buddy.vx * dt, G.minX), G.maxX)
        buddy.y += (G.catY - buddy.y) * min(1, dt * 6)
        buddy.moving = abs(buddy.vx) > (buddy.moving ? 8 : 20) * U
        buddy.look = buddy.vx > 0 ? 0.8 : (buddy.vx < 0 ? -0.8 : buddy.look)
    }

    private func stepBuddy(_ dt: CGFloat) {
        guard let w = buddy.walk else { buddy.activity = .idle; return }
        let dx = w.x - buddy.x, dy = w.y - buddy.y, d = sqrt(dx * dx + dy * dy)
        let sp = 170 * U * w.speed * dt
        if d > sp {
            buddy.x += dx / d * sp; buddy.y += dy / d * sp
            buddy.look = dx > 0 ? 0.8 : -0.8
            return
        }
        buddy.x = w.x; buddy.y = w.y; buddy.walk = nil
        buddy.activity = .idle; buddy.timer = .random(in: 2...5)
        arrived(w.tag)
    }

    private func arrived(_ tag: String?) {
        switch tag {
        case "bed":
            if save!.lightsOff { buddy.activity = .sleep; buddy.zT = 0.8 }
        case "bowl":
            guard bowl != nil else { break }
            buddy.activity = .eat; buddy.timer = 3.2; buddy.eatT = 0; buddy.look = 0.8
        case "litter":
            guard mode == .normal, !save!.lightsOff else { break }
            buddy.activity = .poop; buddy.timer = 2.6
        case "groom":
            // the two give each other a wash
            guard cat.activity == .idle || cat.activity == .walk else { break }
            if cat.activity == .walk && cat.walk?.tag == nil { cat.walk = nil; cat.activity = .idle }
            cat.timer = max(cat.timer, 3); buddy.timer = 3
            cat.happyT = 2.6; buddy.happyT = 2.6
            buddy.look = cat.x > buddy.x ? 0.8 : -0.8; cat.look = -buddy.look
            let mid = CGPoint(x: (cat.x + buddy.x) / 2, y: cat.y - 140 * catScale)
            for i in 0..<3 {
                spawn(.heart, mid.x + CGFloat(i - 1) * 24 * U, mid.y, vx: .random(in: -15...15), vy: -60, life: 1.4, size: 11 * U)
            }
        case "nap":
            if cat.activity == .nap { buddy.activity = .nap; buddy.timer = max(cat.timer, 6); buddy.zT = 1 }
        case "chase":
            buddy.hop = 0.35; buddy.happyT = 1.5
        case "window":
            buddy.happyT = 3; buddy.timer = 4; buddy.look = 0
        default:
            break
        }
    }

    private func buddyAte() {
        buddy.activity = .idle; buddy.timer = .random(in: 2...4)
        guard let b = bowl ?? lastBowl else { return }
        let needed = save!.companion!.needs.food < 85
        save!.companion!.needs.food += b.food.food
        save!.companion!.needs.fun += b.food.fun
        save!.companion!.needs.clamp()
        if needed || b.food.isTreat { addHearts(1, at: CGPoint(x: buddy.x, y: buddy.y - 150 * U)) }
        // the bowl is put away once both have eaten
        if cat.activity != .eat && cat.walk?.tag != "bowl" { bowl = nil }
        buddySay(L10n.ateLines.randomElement()!, 2)
    }

    /// What the other cat does next: its share of the bowl and the litter box first, then now and
    /// then something together with the first cat, otherwise a stroll.
    private func decide(_ rec: CatRecord) {
        if bowl != nil && buddyServing != bowlServing && rec.needs.food < 96 {
            buddyServing = bowlServing
            buddyGo(buddyBowlSpot.x, buddyBowlSpot.y, speed: 1.1, tag: "bowl")
            return
        }
        if room == .living && litterTurnBuddy && save!.poop < 3 && poopClock >= poopEveryNow && rec.needs.food > 20 {
            poopClock = 0; litterTurnBuddy = false
            buddyGo(G.litter.x, G.litter.y, speed: 0.9, tag: "litter")
            return
        }
        if cat.activity == .nap && room == .living {
            buddyGo(min(max(cat.x - 150 * U, G.minX), G.maxX), G.catY, speed: 0.7, tag: "nap")
            return
        }
        if startTogether(rec) { return }
        if Double.random(in: 0...1) < 0.5 {
            buddyGo(.random(in: G.minX...max(G.minX, G.maxX)), G.catY, speed: 0.55)
        } else {
            buddy.timer = .random(in: 2...5)
            buddy.look = .random(in: -1...1)
        }
    }

    /// When both cats are content: a wash for each other, a chase, or a look out of the window.
    private func startTogether(_ rec: CatRecord) -> Bool {
        guard togetherT <= 0, mood == "happy", World.moodOf(rec.needs, poop: save!.poop) == "happy",
              cat.activity == .idle || (cat.activity == .walk && cat.walk?.tag == nil),
              Double.random(in: 0...1) < 0.4 else { return false }
        togetherT = .random(in: 35...70)
        let side: CGFloat = cat.x > W / 2 ? -1 : 1
        switch Int.random(in: 0..<(room == .living ? 3 : 2)) {
        case 0:
            buddyGo(min(max(cat.x + side * 95 * catScale, G.minX), G.maxX), G.catY, speed: 0.8, tag: "groom")
        case 1:
            // a chase across the room: the first runs off, the other after it
            let far = side > 0 ? G.maxX : G.minX
            goTo(far, G.catY, speed: 1.5)
            cat.happyT = 1.5
            buddyGo(min(max(far - side * 110 * U, G.minX), G.maxX), G.catY, speed: 1.6, tag: "chase")
        default:
            // side by side under the window
            goTo(min(max(G.win.midX + 70 * U, G.minX), G.maxX), G.catY, speed: 0.8)
            buddyGo(min(max(G.win.midX - 70 * U, G.minX), G.maxX), G.catY, speed: 0.8, tag: "window")
        }
        return true
    }

    // MARK: Touch and care

    func hitBuddy(_ p: CGPoint) -> Bool {
        guard hasCompanion else { return false }
        let s = buddyScale
        if buddy.activity == .sleep || buddy.activity == .nap {
            let ax = (p.x - buddy.x) / (95 * s), ay = (p.y - (buddy.y - 40 * s)) / (60 * s)
            return ax * ax + ay * ay < 1
        }
        let top = (118 * buddyStage.body + 60 * buddyStage.head) * s
        let cy = buddy.y - buddyLift() - top / 2, ry = top / 2 + 10 * s, rx = 72 * s
        let dx = (p.x - buddy.x) / rx, dy = (p.y - cy) / ry
        return dx * dx + dy * dy < 1
    }

    func buddyLift() -> CGFloat {
        if buddy.hop > 0 { return sin((1 - buddy.hop / 0.35) * .pi) * (reduceMotion ? 6 : 16) * U }
        if buddy.activity == .walk || buddy.moving { return abs(sin(buddy.t * 11)) * 4 * U }
        return 0
    }

    func buddyHeadPos() -> CGPoint {
        CGPoint(x: buddy.x, y: buddy.y - buddyLift() - 118 * buddyStage.body * buddyScale)
    }

    /// The sponge washes the cat it touches (#21).
    func scrubBuddy(_ p: CGPoint, _ d: CGFloat) {
        guard hasCompanion else { return }
        buddy.scrubT = 0.4
        let before = save!.companion!.needs.clean
        save!.companion!.needs.clean = min(100, before + Double(d) * 0.07)
        washGain += save!.companion!.needs.clean - before
        if washGain >= 25 { washGain -= 25; addHearts(1, at: CGPoint(x: p.x, y: p.y - 30)) }
        bubAcc += d
        while bubAcc > 14 {
            bubAcc -= 14
            spawn(.bubble, p.x + .random(in: -26...26) * U, p.y + .random(in: -18...18) * U,
                  vx: .random(in: -20...20), vy: .random(in: -45 ... -10), life: .random(in: 0.7...1.5), size: .random(in: 5...12) * U)
            if Double.random(in: 0...1) < 0.25 { sound.pop() }
        }
        if save!.companion!.needs.clean >= 100 && before < 100 {
            buddySay(L10n.squeakyClean, 2.6)
            burst(.sparkle, buddy.x, buddy.y - 120 * U, count: 14, speed: 160 * U, life: 1, size: 9 * U)
            checkWashDone()
        }
    }

    /// Both cats clean (and the box, indoors): the bath is over.
    var buddyClean: Bool { (save?.companion?.needs.clean ?? 100) >= 99 }

    func checkWashDone() {
        guard mode == .wash, save!.needs.clean >= 99, buddyClean, save!.poop == 0 || room != .living else { return }
        modeEndT = 1.8
    }

    /// Whichever cat needs something most says so, so a need is never hidden behind the other cat.
    func buddyNeedsMore() -> Bool {
        guard let rec = save?.companion, buddy.activity == .idle || buddy.activity == .walk else { return false }
        return rec.needs.lowest < 40 && rec.needs.lowest < save!.needs.lowest
    }

    // MARK: Drawing

    func buddyProps() -> [(CGFloat, (Pen) -> Void)] {
        guard hasCompanion else { return [] }
        // asleep it lies in the basket, between its back and front, behind the other cat
        return [(buddy.activity == .sleep ? G.bed.y - 0.1 : buddy.y, drawBuddy)]
    }

    func drawBuddy(_ p: Pen) {
        guard let rec = save?.companion else { return }
        let s = buddyScale, k = buddyCoat, st = buddyStage
        let dirt = CGFloat(min(max((45 - rec.needs.clean) / 45, 0), 1))
        if buddy.activity == .sleep || buddy.activity == .nap {
            let y = buddy.activity == .sleep ? buddy.y - 24 * objScale(buddy.y) : buddy.y
            // asleep in the basket it lies the other way round from the first cat
            p.save()
            if buddy.activity == .sleep { p.translate(buddy.x, 0); p.scale(-1, 1); p.translate(-buddy.x, 0) }
            CatArt.drawSleepingCat(p, x: buddy.x + 6 * U, y: y, s: s, coat: k, stage: st, wear: rec.wear, t: T + 1.3, dirt: dirt)
            p.restore()
            return
        }
        var pose = CatPose(coat: k, stage: st)
        pose.x = buddy.x; pose.y = buddy.y; pose.s = s
        let m = World.moodOf(rec.needs, poop: save!.poop)
        pose.blush = m == "happy"
        pose.lookX = buddy.look
        pose.tilt = sin(buddy.t * 1.3) * 0.04
        if m == "sad" { pose.eyes = .sad; pose.mouth = .sad } else if m == "meh" { pose.mouth = .flat }
        if rec.needs.energy < 25 { pose.lid = 0.45 }
        if buddy.happyT > 0 || buddy.scrubT > 0 { pose.eyes = .happy; pose.mouth = .smile; pose.blush = true; pose.lid = 0 }
        switch buddy.activity {
        case .eat:
            pose.eyes = .happy; pose.mouth = Int(buddy.t * 6) % 2 == 1 ? .open : .smile; pose.tilt = 0.22; pose.lookX = 1
        case .poop:
            pose.eyes = .closed; pose.mouth = .flat
        case .play:
            pose.eyes = .wide; pose.lid = 0
            let hp = buddyHeadPos()
            pose.lookX = min(max((feather.x - hp.x) / (120 * U), -1), 1)
            pose.lookY = min(max((feather.y - hp.y) / (120 * U), -1), 1)
        case .fish:
            pose.eyes = .wide; pose.lid = 0
            if let f = watchedFish() {
                let hp = buddyHeadPos()
                pose.lookX = min(max((f.x - hp.x) / (120 * U), -1), 1)
                pose.lookY = min(max((f.y - hp.y) / (120 * U), -1), 1)
            }
        default:
            break
        }
        if buddy.mouthT > 0 { pose.mouth = .open }
        if buddy.blink > 0 && (pose.eyes == .open || pose.eyes == .wide || pose.eyes == .sad) { pose.eyes = .blink }
        let walking = buddy.activity == .walk || buddy.moving
        if walking { pose.tilt += sin(buddy.t * 10) * 0.05 }
        pose.tail = buddy.tail
        pose.wear = rec.wear
        pose.dirt = dirt
        pose.lift = buddyLift()
        pose.step = walking ? sin(buddy.t * 10) : 0
        CatArt.drawCat(p, pose)
    }
}
