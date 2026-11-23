import SwiftUI

enum GameMode { case normal, play, wash, fish }

/// Where the cat is. The living room is free; the garden comes with Pro.
enum Room: String, Codable { case living, garden }

/// Something the world wants the SwiftUI layer to show. Collected per frame and handed over
/// after drawing, so no observable state changes while a view is being drawn.
enum WorldEvent {
    case toast(String)
    case modeEnded
    case openFood
    case itemsChanged
    case fishingStarted
}

struct Bubble { var text: String; var t: CGFloat; var d: CGFloat }

enum ParticleKind { case heart, bubble, sparkle, zzz, text }

struct Particle {
    var kind: ParticleKind
    var x: CGFloat, y: CGFloat, vx: CGFloat, vy: CGFloat
    var life: CGFloat, max: CGFloat, size: CGFloat
    var text = ""
    var ph = CGFloat.random(in: 0...(2 * .pi))
}

enum CatActivity { case idle, walk, eat, poop, sleep, play, wash, fish }

struct Walk {
    var x: CGFloat, y: CGFloat
    var speed: CGFloat
    var tag: String?
    var after: (() -> Void)?
}

struct Jump { var t: CGFloat = 0; var dur: CGFloat = 0.62; var h: CGFloat; var vx: CGFloat; var checked = false }

struct CatState {
    var x: CGFloat = 0, y: CGFloat = 0
    var activity: CatActivity = .idle
    var timer: CGFloat = 2, t: CGFloat = 0, tail: CGFloat = 0
    var blink: CGFloat = 0, blinkT: CGFloat = 3, look: CGFloat = 0
    var walk: Walk?
    var jump: Jump?
    var hop: CGFloat = 0, petT: CGFloat = 0, scrubT: CGFloat = 0, happyT: CGFloat = 0, mouthT: CGFloat = 0
    var needT: CGFloat = 10, cool: CGFloat = 0, zT: CGFloat = 0, eatT: CGFloat = 0
    var moving = false, sleepHeart = false
    /// Sideways speed, used where the cat glides after something (the leaping fish).
    var vx: CGFloat = 0
}

struct Feather { var x: CGFloat = 0, y: CGFloat = 0, tx: CGFloat = 0, ty: CGFloat = 0, ang: CGFloat = 0, held: CGFloat = 0, catches = 0 }

struct Flower { var x: CGFloat, y: CGFloat, kind: Int }

struct Geometry {
    var floorY: CGFloat = 0, catY: CGFloat = 0, minX: CGFloat = 0, maxX: CGFloat = 0
    var litter = CGPoint.zero, bowl = CGPoint.zero, bed = CGPoint.zero
    var win = CGRect.zero
    var clock = CGPoint.zero, clockR: CGFloat = 0
    var pic: CGRect?
    // the garden
    var pond = CGPoint.zero, pondRX: CGFloat = 0, pondRY: CGFloat = 0
    var tree = CGPoint.zero
    var flowers: [Flower] = []
}

enum SkyPhase: String { case night, dawn, day, dusk
    static func at(_ date: Date) -> SkyPhase {
        #if DEBUG
        // For checking and screenshots: launch with `-debugSky night` (or dawn, day, dusk).
        if let forced = UserDefaults.standard.string(forKey: "debugSky").flatMap(SkyPhase.init) { return forced }
        #endif
        let c = Calendar.current.dateComponents([.hour, .minute], from: date)
        let h = Double(c.hour ?? 12) + Double(c.minute ?? 0) / 60
        if h >= 21 || h < 6 { return .night }
        if h < 8 { return .dawn }
        if h < 18 { return .day }
        return .dusk
    }
}

/// The whole game: the cat, the room and everything that moves. Drawn once per frame by
/// `GameCanvas`. Not observable on purpose; the SwiftUI layer reads a snapshot a few times a
/// second instead of redrawing the buttons 60 times a second.
@MainActor
final class World {
    var save: SaveState?
    var isPro = false
    let sound: SoundEngine
    /// Where the cat is saved. The tests use their own suite so they never touch a real cat.
    var defaults: UserDefaults = .standard
    private(set) var events: [WorldEvent] = []

    private(set) var mode: GameMode = .normal
    var T: CGFloat = 0
    var bubble: Bubble?
    var parts: [Particle] = []
    var cat = CatState()
    var feather = Feather()
    var sponge = CGPoint.zero
    var bowl: (food: Food, amount: CGFloat)?
    var poopClock: CGFloat = 0, modeEndT: CGFloat = 0, washDone = false, washGain: Double = 0
    var petAcc: CGFloat = 0, heartAcc: CGFloat = 0, bubAcc: CGFloat = 0
    var stageT: CGFloat = 0, saveT: CGFloat = 5, hudT: CGFloat = 0
    var hudDue = true
    // the garden and Catch the fish
    var fishing: FishGame?
    var ripples: [Ripple] = []
    var roomFade: CGFloat = 0
    #if DEBUG
    /// Set for App Store screenshots: the scene is staged and the world stands still.
    var screenshotScene: String?
    #endif
    var sky = SkyPhase.at(Date())
    /// The system's Reduce Motion, set by the game view (#14). Hearts and sparkles then fade where
    /// they appear, jumps become small hops, and fish leap low and slow. The game and its rewards
    /// stay the same.
    var reduceMotion = false
    var W: CGFloat = 0, H: CGFloat = 0, U: CGFloat = 1
    var G = Geometry()
    private var lastFrame: Date?

    // pointer
    private var ptrDown = false, ptrLast = CGPoint.zero, ptrStart = Date(), ptrMoved: CGFloat = 0, ptrOnCat = false

    static let poopEvery: CGFloat = 420

    init(sound: SoundEngine) {
        self.sound = sound
    }

    // MARK: Hand-over to SwiftUI

    func takeEvents() -> [WorldEvent] {
        let e = events
        events.removeAll()
        hudDue = false
        return e
    }
    var wantsSync: Bool { hudDue || !events.isEmpty }

    func post(_ e: WorldEvent) { events.append(e) }

    // MARK: Helpers

    var room: Room { Room(rawValue: save?.room ?? "") ?? .living }
    var stage: Stage { Catalog.stages[save?.stage ?? 0] }
    var coat: Coat { Catalog.coat(save?.coat ?? "orange") }
    var name: String { save?.name ?? "" }

    func objScale(_ y: CGFloat) -> CGFloat {
        let d = min(max((y - G.floorY) / (H - G.floorY), 0), 1)
        return U * (0.72 + 0.32 * d)
    }
    var catScale: CGFloat { objScale(cat.y) * stage.size }

    func say(_ text: String, _ dur: CGFloat = 3.2) { bubble = Bubble(text: text, t: dur, d: dur) }
    func meowSay(_ text: String, _ dur: CGFloat = 3.2) {
        say(text, dur)
        cat.mouthT = 0.45
        sound.meow(pitch: stage.pitch * Float.random(in: 0.95...1.08))
    }

    func spawn(_ kind: ParticleKind, _ x: CGFloat, _ y: CGFloat, vx: CGFloat = 0, vy: CGFloat = 0,
               life: CGFloat = 1, size: CGFloat = 10, text: String = "") {
        // With Reduce Motion nothing flies sideways, and what rises only drifts up a little.
        let vx = reduceMotion ? 0 : vx, vy = reduceMotion ? vy * 0.2 : vy
        parts.append(Particle(kind: kind, x: x, y: y, vx: vx, vy: vy, life: life, max: life, size: size, text: text))
        if parts.count > 140 { parts.removeFirst() }
    }
    func burst(_ kind: ParticleKind, _ x: CGFloat, _ y: CGFloat, count: Int, speed: CGFloat, life: CGFloat, size: CGFloat) {
        if reduceMotion {
            // A few sparkles that fade where they are, instead of bursting outwards.
            for _ in 0..<min(count, 5) {
                let a = CGFloat.random(in: 0...(2 * .pi)), r = CGFloat.random(in: 0...(speed * 0.2))
                spawn(kind, x + cos(a) * r, y + sin(a) * r, life: life, size: size)
            }
            return
        }
        for _ in 0..<count {
            let a = CGFloat.random(in: 0...(2 * .pi)), v = CGFloat.random(in: (speed * 0.4)...speed)
            spawn(kind, x, y, vx: cos(a) * v, vy: sin(a) * v, life: life, size: size)
        }
    }

    func addHearts(_ n: Int, at point: CGPoint? = nil) {
        guard save != nil else { return }
        let before = save!.hearts
        save!.hearts += n
        let hx = point?.x ?? cat.x, hy = point?.y ?? cat.y - 160 * U
        for _ in 0..<n {
            spawn(.heart, hx + .random(in: -20...20) * U, hy + .random(in: -10...10) * U,
                  vx: .random(in: -20...20), vy: -70 - .random(in: 0...30), life: 1.4, size: 14 * U)
        }
        sound.chime()
        for item in Catalog.items where item.cost > before && item.cost <= save!.hearts && (item.isFree || isPro) {
            post(.toast(L10n.itemUnlocked(item.icon + " " + item.name)))
        }
        hudDue = true
    }

    // MARK: Lifecycle

    func startNewCat(name: String, coat: String) {
        save = SaveState(name: name, coat: coat)
        SaveStore.save(save, to: defaults)
        resetCat()
        meowSay(L10n.hello(name), 4)
        hudDue = true
    }

    func loadExisting(_ s: SaveState) {
        save = s
        resetCat()
        afterAway(save!.catchUp())
        SaveStore.save(save, to: defaults)
    }

    func removeCat() {
        save = nil
        SaveStore.save(nil, to: defaults)
        bubble = nil; bowl = nil; parts.removeAll(); ripples.removeAll()
        setMode(.normal)
        sound.stopPurr()
    }

    private func resetCat() {
        cat = CatState()
        cat.x = W * 0.55; cat.y = G.catY
        if save?.lightsOff == true {
            save?.room = nil // the basket is indoors
            cat.x = G.bed.x; cat.y = G.bed.y; cat.activity = .sleep; cat.zT = 1
        }
    }

    func persist() { SaveStore.save(save, to: defaults) }

    /// Called when the app comes back to the foreground.
    func resume() {
        guard save != nil else { return }
        afterAway(save!.catchUp())
        lastFrame = nil
    }

    private func afterAway(_ away: TimeInterval) {
        checkStage(celebrate: true)
        dailyBonus()
        if save!.lightsOff && !SaveState.isNight(Date()) && save!.needs.energy >= 60 {
            save!.lightsOff = false
            if cat.activity == .sleep { wakeUp(rested: true) }
        }
        if away > 6 * 3600 { meowSay(L10n.missedYou, 3.5) } else if away > 20 * 60 { meowSay(L10n.welcomeBackLines.randomElement()!) }
        hudDue = true
    }

    private func checkStage(celebrate: Bool) {
        guard let s = save else { return }
        let st = Catalog.stage(born: s.born, at: Date())
        guard st > s.stage else { return }
        save!.stage = st
        if celebrate {
            post(.toast(st == 1 ? L10n.grewYoung(s.name) : L10n.grewAdult(s.name)))
            say(L10n.grewBigger, 4)
            sound.fanfare()
            addHearts(5)
            burst(.sparkle, cat.x, cat.y - 150 * U, count: 20, speed: 220 * U, life: 1.2, size: 10 * U)
        }
    }

    private func dailyBonus() {
        let k = SaveState.dayKey(Date())
        if save!.bonusDay != k {
            save!.bonusDay = k
            post(.toast(L10n.dailyGift))
            addHearts(3)
        }
    }

    // MARK: Frame

    func frame(_ ctx: GraphicsContext, size: CGSize, date: Date) {
        if abs(size.width - W) > 0.5 || abs(size.height - H) > 0.5 { layout(size) }
        var dt = CGFloat(lastFrame.map { date.timeIntervalSince($0) } ?? 0)
        lastFrame = date
        dt = min(max(dt, 0), 0.1)
        if save != nil { update(dt) }
        let pen = Pen(ctx)
        draw(pen)
    }

    /// Advances the game by `dt` seconds. Also used by the tests.
    func update(_ dt: CGFloat) {
        guard save != nil else { return }
        T += dt
        #if DEBUG
        if screenshotScene != nil { return }
        #endif
        let now = Date()
        let gap = now.timeIntervalSince(save!.last)
        if gap > 8 { afterAway(save!.catchUp(to: now)) } else if gap > 0 {
            save!.liveTick(seconds: gap, sleeping: cat.activity == .sleep)
            save!.last = now
        }
        stageT -= dt
        if stageT <= 0 { stageT = 5; checkStage(celebrate: true); dailyBonus() }
        let phase = SkyPhase.at(now)
        if phase != sky { sky = phase }
        updateCat(dt)
        updateParts(dt)
        updateGarden(dt)
        if roomFade > 0 { roomFade -= dt }
        if var b = bubble { b.t -= dt; bubble = b.t > 0 ? b : nil }
        saveT -= dt
        if saveT <= 0 { saveT = 5; persist() }
        hudT -= dt
        if hudT <= 0 { hudT = 0.25; hudDue = true }
    }

    func layout(_ size: CGSize) {
        W = max(1, size.width); H = max(1, size.height)
        U = min(W / 760, H / 560)
        G.floorY = H * 0.56
        G.catY = H * 0.88
        G.litter = CGPoint(x: max(W * 0.11, 92 * U), y: H * 0.72)
        G.bowl = CGPoint(x: max(W * 0.28, G.litter.x + 172 * U), y: H * 0.905)
        G.bed = CGPoint(x: min(W * 0.83, W - 122 * U), y: H * 0.8)
        G.minX = max(W * 0.12, 90 * U)
        G.maxX = W - max(W * 0.1, 125 * U)
        let ww = min(W * 0.3, H * 0.55)
        G.win = CGRect(x: max(W * 0.16, 50 * U), y: H * 0.08, width: ww, height: H * 0.34)
        G.clock = CGPoint(x: min(W * 0.84, W - 60 * U), y: H * 0.19)
        G.clockR = 34 * U
        let pic = CGRect(x: G.win.maxX + max(60 * U, W * 0.07), y: H * 0.12, width: 110 * U, height: 84 * U)
        G.pic = pic.maxX > G.clock.x - G.clockR - 16 * U ? nil : pic
        layoutGarden()
        if save != nil { snapCat() }
        #if DEBUG
        if let scene = screenshotScene { stageScreenshot(scene) }
        #endif
    }

    /// The pond sits on the lawn behind the path the cat walks along, the tree on the right.
    private func layoutGarden() {
        let py = H * 0.74, ps = objScale(py)
        G.pond = CGPoint(x: max(W * 0.38, 250 * U), y: py)
        G.pondRX = min(W * 0.25, 215 * ps)
        G.pondRY = 46 * ps
        G.tree = CGPoint(x: min(W * 0.84, W - 110 * U), y: H * 0.66)
        var flowers: [Flower] = []
        for i in 0..<26 where flowers.count < 11 {
            let x = 24 * U + World.hash01(i, 1) * (W - 48 * U)
            let y = G.floorY + 26 * U + World.hash01(i, 2) * (H - G.floorY - 34 * U)
            let dx = (x - G.pond.x) / (G.pondRX + 40 * U), dy = (y - G.pond.y) / (G.pondRY + 40 * U)
            if dx * dx + dy * dy < 1 { continue }
            if abs(x - G.tree.x) < 90 * U && y < G.tree.y + 30 * U { continue }
            flowers.append(Flower(x: x, y: y, kind: i % 4))
        }
        G.flowers = flowers
    }

    /// After a resize, put the cat back where it belongs.
    private func snapCat() {
        switch cat.activity {
        case .sleep: cat.x = G.bed.x; cat.y = G.bed.y; return
        case .eat: cat.x = G.bowl.x + 78 * objScale(G.catY); cat.y = G.catY; return
        case .poop: cat.x = G.litter.x; cat.y = G.litter.y; return
        case .fish: cat.jump = nil; cat.x = clampToPond(cat.x); cat.y = G.catY; return
        default: break
        }
        cat.x = min(max(cat.x == 0 ? W * 0.55 : cat.x, G.minX), G.maxX)
        cat.y = G.catY
        if var w = cat.walk {
            switch w.tag {
            case "bed": w.x = G.bed.x; w.y = G.bed.y
            case "bowl": w.x = G.bowl.x + 78 * objScale(G.catY); w.y = G.catY
            case "litter": w.x = G.litter.x; w.y = G.litter.y
            default: w.x = min(max(w.x, G.minX), G.maxX); w.y = G.catY
            }
            cat.walk = w
        }
    }

    // MARK: The cat's behaviour

    func goTo(_ x: CGFloat, _ y: CGFloat, speed: CGFloat = 1, tag: String? = nil, after: (() -> Void)? = nil) {
        cat.walk = Walk(x: x, y: y, speed: speed, tag: tag, after: after)
        cat.activity = .walk
    }

    var mood: String {
        guard let n = save?.needs else { return "ok" }
        if n.lowest < 15 { return "sad" }
        if n.lowest < 35 { return "meh" }
        if n.average >= 65 { return "happy" }
        return "ok"
    }

    func needLine() -> String? {
        guard let s = save else { return nil }
        if s.poop >= 2 { return L10n.litterSmells }
        let list: [(Double, String)] = [(s.needs.food, L10n.hungry), (s.needs.energy, L10n.tired),
                                        (s.needs.clean, L10n.dirty), (s.needs.fun, L10n.bored)]
        if let lowest = list.min(by: { $0.0 < $1.0 }), lowest.0 < 40 { return lowest.1 }
        if SaveState.isNight(Date()) && !s.lightsOff { return L10n.bedtime }
        return nil
    }

    private func updateCat(_ dt: CGFloat) {
        cat.t += dt
        cat.tail += dt * ((cat.activity == .walk || cat.activity == .play || cat.activity == .fish) ? 5 : 1.8)
        cat.blinkT -= dt
        if cat.blinkT <= 0 { cat.blink = 0.15; cat.blinkT = .random(in: 2.5...5.5) }
        if cat.blink > 0 { cat.blink -= dt }
        if cat.hop > 0 { cat.hop -= dt }
        if cat.happyT > 0 { cat.happyT -= dt }
        if cat.scrubT > 0 { cat.scrubT -= dt }
        if cat.mouthT > 0 { cat.mouthT -= dt }
        if cat.petT > 0 { cat.petT -= dt; if cat.petT <= 0 { sound.stopPurr() } }

        // the light is off: the cat goes to bed
        if save!.lightsOff && cat.activity != .sleep && cat.walk?.tag != "bed" {
            cat.jump = nil; bowl = nil
            goTo(G.bed.x, G.bed.y, tag: "bed") { [weak self] in
                guard let self, self.save?.lightsOff == true else { return }
                self.cat.activity = .sleep; self.cat.zT = 0.5
            }
        }
        // the litter box is indoors, so the clock only runs there
        if mode == .normal && cat.activity != .sleep && room == .living { poopClock += dt }

        switch cat.activity {
        case .walk:
            guard let w = cat.walk else { cat.activity = .idle; break }
            let dx = w.x - cat.x, dy = w.y - cat.y
            let d = sqrt(dx * dx + dy * dy)
            let sp = 170 * U * w.speed * dt
            if d <= sp {
                cat.x = w.x; cat.y = w.y; cat.walk = nil
                cat.activity = .idle; cat.timer = .random(in: 2...5)
                w.after?()
            } else {
                cat.x += dx / d * sp; cat.y += dy / d * sp
                cat.look = dx > 0 ? 0.8 : -0.8
            }
        case .idle:
            cat.timer -= dt
            if mode == .normal && cat.timer <= 0 && cat.petT <= 0 {
                if save!.poop < 3 && poopClock >= World.poopEvery && save!.needs.food > 20 {
                    poopClock = 0
                    goTo(G.litter.x, G.litter.y, speed: 0.9, tag: "litter") { [weak self] in
                        guard let self, self.mode == .normal, self.save?.lightsOff == false else { return }
                        self.cat.activity = .poop; self.cat.timer = 2.6
                    }
                } else if Double.random(in: 0...1) < 0.55 {
                    goTo(.random(in: G.minX...max(G.minX, G.maxX)), G.catY, speed: 0.55)
                } else {
                    cat.timer = .random(in: 2...5)
                    cat.look = .random(in: -1...1)
                }
            }
        case .eat:
            cat.timer -= dt
            cat.eatT -= dt
            if bowl != nil { bowl!.amount = min(max(cat.timer / 3.2, 0), 1) }
            if cat.eatT <= 0 {
                cat.eatT = 0.4
                sound.nom()
                spawn(.text, cat.x - 50 * U, cat.y - 130 * U, vx: .random(in: -20...10), vy: -40, life: 0.9,
                      size: 18 * U, text: L10n.nomWords.randomElement()!)
            }
            if cat.timer <= 0 { finishEating() }
        case .poop:
            cat.timer -= dt
            if cat.timer <= 0 {
                if save!.poop < 3 { save!.poop += 1 }
                sound.plop()
                say(L10n.poopLines.randomElement()!, 2)
                goTo(G.litter.x + 190 * U, G.catY, speed: 0.9)
            }
        case .sleep:
            cat.x = G.bed.x; cat.y = G.bed.y
            cat.zT -= dt
            if cat.zT <= 0 {
                cat.zT = 1.3
                let s = catScale
                spawn(.zzz, cat.x - 50 * s, cat.y - 100 * s, vx: 14, vy: -26, life: 2.4, size: 18 * U)
            }
            if !save!.lightsOff {
                wakeUp(rested: false)
            } else if save!.needs.energy >= 100 && !SaveState.isNight(Date()) {
                save!.lightsOff = false
                if cat.sleepHeart { cat.sleepHeart = false; addHearts(1) }
                wakeUp(rested: true)
                hudDue = true
            }
        case .play:
            updatePlay(dt)
        case .fish:
            updateFishing(dt)
        case .wash:
            break
        }

        // the cat says what it needs
        cat.needT -= dt
        if cat.needT <= 0 {
            cat.needT = .random(in: 16...28)
            if mode == .normal && !save!.lightsOff && bubble == nil && (cat.activity == .idle || cat.activity == .walk) {
                if let line = needLine() { meowSay(line) } else if Double.random(in: 0...1) < 0.4 { say(L10n.happyLines.randomElement()!, 2.6) }
            }
        }
        if modeEndT > 0 {
            modeEndT -= dt
            if modeEndT <= 0 && mode != .normal { setMode(.normal); post(.modeEnded) }
        }
    }

    private func wakeUp(rested: Bool) {
        cat.activity = .idle
        cat.x = G.bed.x; cat.y = G.bed.y
        goTo(G.bed.x - 160 * U, G.catY, speed: 0.8)
        meowSay(rested ? L10n.wakeRested : L10n.wakeLines.randomElement()!)
    }

    func tapCat() {
        guard let s = save else { return }
        if s.lightsOff { say(L10n.zzz, 1.5); return }
        if cat.activity == .idle || cat.activity == .walk { cat.hop = 0.35 }
        cat.happyT = 0.8
        meowSay(needLine() ?? L10n.tapLines.randomElement()!)
    }

    private func pet(_ p: CGPoint, _ d: CGFloat) {
        if cat.activity == .walk && cat.walk?.tag == nil { cat.walk = nil; cat.activity = .idle }
        guard cat.activity == .idle else { return }
        cat.petT = 0.5
        cat.timer = max(cat.timer, 2.5)
        sound.startPurr()
        if save!.needs.fun < 100 { save!.needs.fun = min(100, save!.needs.fun + Double(d) * 0.012) }
        heartAcc += d
        if heartAcc > 70 {
            heartAcc = 0
            spawn(.heart, p.x + .random(in: -10...10), p.y - 10, vx: .random(in: -15...15), vy: -70, life: 1.2, size: .random(in: 8...12) * U)
        }
        petAcc += d
        if petAcc > 900 { petAcc = 0; if save!.needs.fun < 99.9 { addHearts(1, at: CGPoint(x: p.x, y: p.y - 30)) } }
    }

    // MARK: Food

    func feed(_ food: Food) {
        guard save != nil else { return }
        if save!.needs.food >= 96 { meowSay(L10n.full); return }
        if food.isTreat {
            let now = Date()
            save!.treats = save!.treats.filter { now.timeIntervalSince($0) < 15 * 60 }
            if save!.treats.count >= 3 { meowSay(L10n.noMoreTreats); return }
            save!.treats.append(now)
        }
        enterRoom(.living) // the bowl is indoors
        bowl = (food, 1)
        cat.jump = nil
        goTo(G.bowl.x + 78 * objScale(G.catY), G.catY, speed: 1.2, tag: "bowl") { [weak self] in
            guard let self, self.bowl != nil else { return }
            self.cat.activity = .eat; self.cat.timer = 3.2; self.cat.eatT = 0
        }
    }

    private func finishEating() {
        cat.activity = .idle; cat.timer = .random(in: 2...4)
        guard let b = bowl else { return }
        let needed = save!.needs.food < 85
        save!.needs.food += b.food.food
        save!.needs.fun += b.food.fun
        save!.needs.clamp()
        bowl = nil
        if needed || b.food.isTreat { addHearts(1, at: CGPoint(x: G.bowl.x, y: G.bowl.y - 60 * U)) }
        meowSay(L10n.ateLines.randomElement()!)
    }

    // MARK: Play with the feather

    @discardableResult
    func startPlay() -> Bool {
        guard let s = save, !s.lightsOff else { return false }
        if s.needs.energy < 12 { meowSay(L10n.tooTiredToPlay); return false }
        setMode(.play)
        bowl = nil
        cat.walk = nil; cat.jump = nil; cat.activity = .play; cat.cool = 0.8
        feather.x = min(max(cat.x + 160 * U, 60), W - 60); feather.tx = feather.x
        feather.y = max(G.catY - 240 * U, featherTop); feather.ty = feather.y
        feather.held = 0; feather.catches = 0
        return true
    }

    private var featherCenter: CGPoint { CGPoint(x: feather.x, y: feather.y + 26 * U) }
    /// How high the feather can go. With Reduce Motion it stays low enough for a small hop to
    /// reach, so the cat still catches it as often without leaping.
    private var featherTop: CGFloat { reduceMotion ? G.catY - 220 * U : 20 * U }

    func catLift() -> CGFloat {
        if let j = cat.jump { let p = min(max(j.t / j.dur, 0), 1); return j.h * 4 * p * (1 - p) }
        if cat.hop > 0 { return sin((1 - cat.hop / 0.35) * .pi) * (reduceMotion ? 6 : 16) * U }
        if cat.activity == .walk || cat.moving { return abs(sin(cat.t * 11)) * 4 * U }
        return 0
    }
    func catHeadPos() -> CGPoint {
        CGPoint(x: cat.x, y: cat.y - catLift() - 118 * stage.body * catScale)
    }

    private func updatePlay(_ dt: CGFloat) {
        if feather.held > 0 {
            feather.held -= dt
            let hp = catHeadPos()
            feather.x = hp.x + 18 * U; feather.y = hp.y + 10 * U
            feather.ang = -0.5
            if feather.held <= 0 {
                feather.tx = min(max(cat.x + (Bool.random() ? -1 : 1) * 190 * U, 50), W - 50)
                feather.ty = max(G.catY - 300 * U, featherTop)
            }
        } else {
            let k = min(1, dt * 12), ox = feather.x
            feather.x += (feather.tx - feather.x) * k
            feather.y += (feather.ty - feather.y) * k
            let vx = (feather.x - ox) / max(dt, 0.001)
            let target = min(max(-vx * 0.0025, -0.9), 0.9) + sin(T * 3) * 0.15
            feather.ang += (target - feather.ang) * min(1, dt * 8)
        }
        let s = catScale
        cat.cool -= dt
        if var j = cat.jump {
            j.t += dt
            cat.x = min(max(cat.x + j.vx * dt, G.minX), G.maxX)
            if !j.checked && j.t >= j.dur / 2 {
                j.checked = true
                cat.jump = j
                let hp = catHeadPos(), fc = featherCenter
                let dist = hypot(fc.x - hp.x, fc.y - hp.y)
                if feather.held <= 0 && dist < 105 * s { caught() } else if Double.random(in: 0...1) < 0.35 { say(L10n.missLines.randomElement()!, 1.4) }
            }
            cat.jump = j.t >= j.dur ? nil : j
            if j.t >= j.dur { cat.cool = 0.9 }
            cat.moving = false
        } else {
            let tx = min(max(feather.x, G.minX), G.maxX), dx = tx - cat.x, sp = (reduceMotion ? 200 : 330) * U * dt
            cat.moving = abs(dx) > 6
            if cat.moving { cat.x += min(max(dx, -sp), sp) }
            cat.y += (G.catY - cat.y) * min(1, dt * 6)
            let fc = featherCenter
            if cat.cool <= 0 && feather.held <= 0 && abs(fc.x - cat.x) < 90 * U && fc.y < cat.y - 50 * s && fc.y > cat.y - 340 * s {
                let headY = cat.y - 118 * stage.body * s
                let h = min(max(headY - fc.y + 10 * s, 20 * U), (reduceMotion ? 36 : 170) * U)
                let reach: CGFloat = (reduceMotion ? 120 : 260) * U
                cat.jump = Jump(h: h, vx: min(max((fc.x - cat.x) / 0.31, -reach), reach))
                sound.jump()
            }
        }
    }

    private func caught() {
        feather.catches += 1
        feather.held = 0.7
        save!.needs.fun = min(100, save!.needs.fun + 7)
        save!.needs.energy = max(0, save!.needs.energy - 2.5)
        if feather.catches % 2 == 0 { addHearts(1, at: CGPoint(x: cat.x, y: cat.y - 220 * U)) } else { sound.chime() }
        burst(.sparkle, feather.x, feather.y + 20 * U, count: 8, speed: 160 * U, life: 0.8, size: 9 * U)
        say(L10n.caughtLines.randomElement()!, 1.6)
        if save!.needs.energy < 8 { modeEndT = 1.8; say(L10n.tiredAfterPlay, 2.5) }
    }

    // MARK: Washing

    @discardableResult
    func startWash() -> Bool {
        guard let s = save, !s.lightsOff else { return false }
        if s.needs.clean >= 97 && s.poop == 0 { meowSay(L10n.alreadyClean); return false }
        setMode(.wash)
        washGain = 0; washDone = false; bowl = nil; cat.jump = nil
        sponge = CGPoint(x: W * 0.55 - 170 * U, y: G.catY - 70 * U)
        goTo(W * 0.55, G.catY, speed: 1.1, tag: "wash") { [weak self] in
            guard let self, self.mode == .wash else { return }
            self.cat.activity = .wash
        }
        return true
    }

    private func scrub(_ p: CGPoint, _ d: CGFloat) {
        cat.scrubT = 0.4
        let before = save!.needs.clean
        save!.needs.clean = min(100, save!.needs.clean + Double(d) * 0.07)
        washGain += save!.needs.clean - before
        if washGain >= 25 { washGain -= 25; addHearts(1, at: CGPoint(x: p.x, y: p.y - 30)) }
        bubAcc += d
        while bubAcc > 14 {
            bubAcc -= 14
            spawn(.bubble, p.x + .random(in: -26...26) * U, p.y + .random(in: -18...18) * U,
                  vx: .random(in: -20...20), vy: .random(in: -45 ... -10), life: .random(in: 0.7...1.5), size: .random(in: 5...12) * U)
            if Double.random(in: 0...1) < 0.25 { sound.pop() }
        }
        if save!.needs.clean >= 100 && !washDone {
            washDone = true
            meowSay(L10n.squeakyClean, 2.6)
            burst(.sparkle, cat.x, cat.y - 120 * U, count: 14, speed: 160 * U, life: 1, size: 9 * U)
            // indoors the bath waits for the litter box too; it can't be reached from the garden
            if save!.poop == 0 || room == .garden { modeEndT = 1.8 }
        }
    }

    @discardableResult
    func scoop() -> Bool {
        guard save!.poop > 0 else { return false }
        save!.poop -= 1
        save!.needs.clean = min(100, save!.needs.clean + 4)
        sound.scoop()
        let s = objScale(G.litter.y)
        burst(.sparkle, G.litter.x, G.litter.y - 50 * s, count: 8, speed: 120 * U, life: 0.8, size: 8 * U)
        addHearts(1, at: CGPoint(x: G.litter.x, y: G.litter.y - 80 * s))
        if save!.poop == 0 {
            say(L10n.litterCleaned, 2.5)
            if mode == .wash && save!.needs.clean >= 99 { modeEndT = 1.8 }
        }
        hudDue = true
        return true
    }

    // MARK: Sleep

    func toggleLights() {
        guard mode == .normal, save != nil else { return }
        if !save!.lightsOff { enterRoom(.living) } // the basket is indoors
        save!.lightsOff.toggle()
        if save!.lightsOff {
            bowl = nil
            cat.sleepHeart = save!.needs.energy < 50
            if save!.needs.energy > 85 && !SaveState.isNight(Date()) { meowSay(L10n.notTired) } else { meowSay(L10n.goodNight) }
        } else if cat.activity == .sleep {
            wakeUp(rested: false)
        }
        hudDue = true
        persist()
    }

    // MARK: Modes

    func setMode(_ m: GameMode) {
        mode = m
        if m == .normal {
            cat.jump = nil; cat.moving = false; modeEndT = 0
            if cat.walk?.tag == "wash" { cat.walk = nil; cat.activity = .idle }
            if cat.activity == .play || cat.activity == .wash || cat.activity == .fish { cat.activity = .idle; cat.timer = 2 }
            fishing = nil
        }
    }

    func dressed(_ newItem: Bool) {
        cat.happyT = 1.2
        if newItem { meowSay(L10n.dressedLines.randomElement()!) }
        if !save!.lightsOff && (cat.activity == .idle || (cat.activity == .walk && cat.walk?.tag == nil)) {
            goTo(min(max(W * 0.68, G.minX), G.maxX), G.catY)
        }
        persist()
    }

    // MARK: Touch

    func hitCat(_ p: CGPoint) -> Bool {
        guard save != nil else { return false }
        let s = catScale
        if cat.activity == .sleep {
            let ax = (p.x - cat.x) / (95 * s), ay = (p.y - (cat.y - 40 * s)) / (60 * s)
            return ax * ax + ay * ay < 1
        }
        let top = (118 * stage.body + 60 * stage.head) * s
        let cy = cat.y - catLift() - top / 2, ry = top / 2 + 10 * s, rx = 72 * s
        let dx = (p.x - cat.x) / rx, dy = (p.y - cy) / ry
        return dx * dx + dy * dy < 1
    }
    private func hitBox(_ p: CGPoint, _ o: CGPoint, _ w: CGFloat, _ h: CGFloat) -> Bool {
        let s = objScale(o.y)
        return abs(p.x - o.x) < w * s && p.y > o.y - h * s && p.y < o.y + 12 * s
    }
    func hitLitter(_ p: CGPoint) -> Bool { room == .living && hitBox(p, G.litter, 88, 80) }
    func hitBowl(_ p: CGPoint) -> Bool { room == .living && hitBox(p, G.bowl, 60, 50) }
    func hitPond(_ p: CGPoint) -> Bool {
        guard room == .garden else { return false }
        let dx = (p.x - G.pond.x) / (G.pondRX + 12 * U), dy = (p.y - G.pond.y) / (G.pondRY + 16 * U)
        return dx * dx + dy * dy < 1
    }

    private func featherTo(_ p: CGPoint) {
        feather.tx = p.x
        feather.ty = min(max(p.y - 70 * U, featherTop), G.catY - 90 * U)
    }

    func pointerDown(_ p: CGPoint) {
        guard let s = save else { return }
        ptrDown = true; ptrLast = p; ptrStart = Date(); ptrMoved = 0
        ptrOnCat = hitCat(p)
        switch mode {
        case .play: featherTo(p); return
        case .wash: sponge = p; if hitLitter(p) { scoop() }; return
        case .fish: tapFish(p); return
        case .normal: break
        }
        if s.lightsOff || ptrOnCat { return }
        if hitLitter(p) { if !scoop() { say(L10n.litterAlreadyClean, 1.6) } } else if hitBowl(p) { post(.openFood) } else if hitPond(p) {
            if startFishing() { post(.fishingStarted) }
        }
    }

    func pointerMove(_ p: CGPoint) {
        guard let s = save else { return }
        let d = hypot(p.x - ptrLast.x, p.y - ptrLast.y)
        ptrLast = p; ptrMoved += d
        switch mode {
        case .play: featherTo(p); return
        case .wash:
            sponge = p
            if cat.activity == .wash && hitCat(p) { scrub(p, d) }
            return
        case .fish: return
        case .normal: break
        }
        if !s.lightsOff && ptrOnCat && ptrMoved > 10 && hitCat(p) { pet(p, d) }
    }

    func pointerUp() {
        guard save != nil, ptrDown else { return }
        ptrDown = false
        if mode == .normal && ptrOnCat && ptrMoved < 12 && Date().timeIntervalSince(ptrStart) < 0.45 { tapCat() }
    }

    // MARK: Particles

    private func updateParts(_ dt: CGFloat) {
        var i = parts.count - 1
        while i >= 0 {
            parts[i].life -= dt
            if parts[i].life <= 0 { parts.remove(at: i); i -= 1; continue }
            parts[i].x += parts[i].vx * dt
            parts[i].y += parts[i].vy * dt
            switch parts[i].kind {
            case .heart, .zzz, .bubble: if !reduceMotion { parts[i].x += sin(parts[i].ph + parts[i].life * 4) * 18 * dt }
            case .sparkle: parts[i].vx *= 0.93; parts[i].vy *= 0.93
            case .text: break
            }
            i -= 1
        }
    }
}
