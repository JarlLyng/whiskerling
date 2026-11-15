import SwiftUI

/// A fish that leaps out of the pond in an arc. Once caught it flips back into the water.
struct LeapingFish {
    var x0: CGFloat, x1: CGFloat, y0: CGFloat, h: CGFloat
    var t: CGFloat = 0
    var dur: CGFloat
    var hue: Int
    var caughtAt: CGPoint?
    var fallT: CGFloat = 0

    static let fallTime: CGFloat = 0.55
    var progress: CGFloat { min(max(t / dur, 0), 1) }
    /// Above the water and in reach of a finger.
    var catchable: Bool { caughtAt == nil && progress > 0.04 && progress < 0.97 }
}

/// One round of Catch the fish: a fixed number of leaps, no way to lose.
struct FishGame {
    static let leaps = 12
    var fish: [LeapingFish] = []
    var spawnT: CGFloat = 1.1
    var leapsLeft = FishGame.leaps
    var caught = 0
    var finished = false
}

struct Ripple { var x: CGFloat, y: CGFloat, t: CGFloat = 0 }

/// The garden (an extra room with Pro) and the game at its pond.
extension World {
    static func hash01(_ i: Int, _ salt: Double) -> CGFloat {
        let v = sin(Double(i) * 12.9898 + salt * 78.233) * 43758.5453
        return CGFloat(v - floor(v))
    }

    // MARK: Rooms

    /// Moves the cat to `r`, entering from the side, with a short fade.
    func enterRoom(_ r: Room) {
        guard save != nil, room != r else { return }
        save!.room = r == .living ? nil : r.rawValue
        roomFade = 0.45
        bowl = nil; cat.jump = nil; cat.walk = nil; cat.petT = 0
        sound.stopPurr()
        cat.activity = .idle; cat.timer = 2
        cat.x = r == .garden ? G.minX : G.maxX
        cat.y = G.catY
        goTo(W * 0.55, G.catY, speed: 0.9)
        ripples.removeAll()
        hudDue = true
        persist()
    }

    /// The garden button. Needs Pro, the light on, and no game going on.
    @discardableResult
    func goOutside() -> Bool {
        guard let s = save, !s.lightsOff, mode == .normal, isPro, room == .living else { return false }
        enterRoom(.garden)
        meowSay(sky == .night ? L10n.gardenNight : L10n.gardenLines.randomElement()!, 2.8)
        return true
    }

    func comeInside() {
        guard save != nil, room == .garden else { return }
        if mode != .normal { setMode(.normal) }
        enterRoom(.living)
        meowSay(L10n.homeAgain, 2.2)
    }

    /// Pro went away (a refund): leave the garden and stop the game.
    func proLost() {
        guard save != nil else { return }
        if mode == .fish { setMode(.normal); post(.modeEnded) }
        if room == .garden { enterRoom(.living) }
    }

    func updateGarden(_ dt: CGFloat) {
        guard room == .garden else { return }
        for i in ripples.indices { ripples[i].t += dt }
        ripples.removeAll { $0.t > 1.4 }
        // now and then a fish breaks the surface on its own
        if mode == .normal && Double.random(in: 0...1) < Double(dt) * 0.35 {
            ripples.append(Ripple(x: G.pond.x + .random(in: -0.7...0.7) * G.pondRX,
                                  y: G.pond.y + .random(in: -0.5...0.5) * G.pondRY))
        }
    }

    // MARK: Catch the fish

    func clampToPond(_ x: CGFloat) -> CGFloat {
        min(max(x, max(G.pond.x - G.pondRX * 0.9, G.minX)), min(G.pond.x + G.pondRX * 0.9, G.maxX))
    }

    @discardableResult
    func startFishing() -> Bool {
        guard let s = save, !s.lightsOff, mode == .normal, isPro else { return false }
        if s.needs.energy < 12 { meowSay(L10n.tooTiredToPlay); return false }
        if room == .living {
            enterRoom(.garden)
            cat.walk = nil
            cat.x = clampToPond(G.pond.x + G.pondRX * 0.5)
        }
        setMode(.fish)
        bowl = nil
        cat.walk = nil; cat.jump = nil; cat.activity = .fish; cat.petT = 0
        sound.stopPurr()
        fishing = FishGame()
        meowSay(L10n.fishStart, 2.2)
        return true
    }

    func fishPoint(_ f: LeapingFish) -> CGPoint {
        if let c = f.caughtAt {
            // a little hop of joy, then back into the water
            let p = min(f.fallT / LeapingFish.fallTime, 1)
            return CGPoint(x: c.x, y: c.y + (f.y0 - c.y) * p * p - sin(p * .pi) * 30 * U)
        }
        let p = f.progress
        return CGPoint(x: f.x0 + (f.x1 - f.x0) * p, y: f.y0 - f.h * 4 * p * (1 - p))
    }

    func fishAngle(_ f: LeapingFish) -> CGFloat {
        if f.caughtAt != nil { return f.fallT * 12 }
        let dx = (f.x1 - f.x0) / f.dur, dy = -f.h * 4 * (1 - 2 * f.progress) / f.dur
        return atan2(dy, dx)
    }

    /// The fish the cat is watching: the nearest one still in the air.
    func watchedFish() -> CGPoint? {
        guard let g = fishing else { return nil }
        return g.fish.filter(\.catchable).map(fishPoint).min { abs($0.x - cat.x) < abs($1.x - cat.x) }
    }

    func updateFishing(_ dt: CGFloat) {
        guard var g = fishing else { return }
        if !g.finished {
            g.spawnT -= dt
            if g.spawnT <= 0 && g.leapsLeft > 0 {
                g.leapsLeft -= 1
                g.spawnT = .random(in: 1.05...1.6)
                let span = G.pondRX * 0.7, edge = G.pondRX * 0.8
                let x0 = G.pond.x + .random(in: -span...span)
                let x1 = min(max(x0 + (Bool.random() ? 1 : -1) * .random(in: 50...130) * U, G.pond.x - edge), G.pond.x + edge)
                g.fish.append(LeapingFish(x0: x0, x1: x1, y0: G.pond.y - 2 * U, h: .random(in: 130...210) * U,
                                          dur: .random(in: 1.7...2.2), hue: .random(in: 0..<4)))
                ripples.append(Ripple(x: x0, y: G.pond.y))
                sound.pop()
            }
        }
        var i = g.fish.count - 1
        while i >= 0 {
            if g.fish[i].caughtAt != nil {
                g.fish[i].fallT += dt
                if g.fish[i].fallT >= LeapingFish.fallTime { splash(fishPoint(g.fish[i]).x); g.fish.remove(at: i) }
            } else {
                g.fish[i].t += dt
                if g.fish[i].t >= g.fish[i].dur { splash(g.fish[i].x1); g.fish.remove(at: i) }
            }
            i -= 1
        }
        fishing = g

        // the cat follows the fish along the edge of the pond and leaps when one is caught
        if var j = cat.jump {
            j.t += dt
            cat.x = clampToPond(cat.x + j.vx * dt)
            cat.jump = j.t >= j.dur ? nil : j
            cat.moving = false
        } else {
            let tx = clampToPond(watchedFish()?.x ?? (G.pond.x + G.pondRX * 0.5))
            let dx = tx - cat.x, sp = 260 * U * dt
            cat.moving = abs(dx) > 6
            if cat.moving { cat.x += min(max(dx, -sp), sp) }
        }
        cat.y += (G.catY - cat.y) * min(1, dt * 6)

        if !g.finished && g.leapsLeft == 0 && g.fish.isEmpty {
            fishing?.finished = true
            finishFishing(g.caught)
        }
    }

    private func splash(_ x: CGFloat) {
        ripples.append(Ripple(x: x, y: G.pond.y))
        for _ in 0..<6 {
            spawn(.bubble, x + .random(in: -14...14) * U, G.pond.y - 4 * U, vx: .random(in: -60...60) * U,
                  vy: -.random(in: 60...120) * U, life: .random(in: 0.4...0.7), size: .random(in: 3...6) * U)
        }
        sound.plop()
    }

    func tapFish(_ p: CGPoint) {
        guard var g = fishing, !g.finished else { return }
        var best: Int?
        var bestD = 80 * U // generous: small fingers, moving targets
        for (i, f) in g.fish.enumerated() where f.catchable {
            let fp = fishPoint(f), d = hypot(fp.x - p.x, fp.y - p.y)
            if d < bestD { bestD = d; best = i }
        }
        guard let i = best else { return }
        let fp = fishPoint(g.fish[i])
        g.fish[i].caughtAt = fp
        g.caught += 1
        fishing = g
        save!.needs.fun = min(100, save!.needs.fun + 2.5)
        save!.needs.energy = max(0, save!.needs.energy - 0.6)
        burst(.sparkle, fp.x, fp.y, count: 10, speed: 170 * U, life: 0.8, size: 9 * U)
        if g.caught % 3 == 0 { addHearts(1, at: CGPoint(x: fp.x, y: fp.y - 30 * U)) } else { sound.chime() }
        if Double.random(in: 0...1) < 0.45 { say(L10n.caughtLines.randomElement()!, 1.3) }
        if cat.jump == nil {
            cat.jump = Jump(h: 70 * U, vx: min(max((fp.x - cat.x) / 0.62, -300 * U), 300 * U))
            sound.jump()
        }
        cat.happyT = 0.6
        hudDue = true
    }

    private func finishFishing(_ caught: Int) {
        save!.needs.energy = max(0, save!.needs.energy - 3)
        if caught == FishGame.leaps {
            addHearts(1)
            burst(.sparkle, cat.x, cat.y - 150 * U, count: 18, speed: 220 * U, life: 1.1, size: 10 * U)
            sound.fanfare()
            meowSay(L10n.fishPerfect, 2.6)
        } else {
            meowSay(L10n.fishBye, 2.6)
        }
        post(.toast(L10n.fishResult(name, caught)))
        modeEndT = 2.4
        hudDue = true
    }
}
