import SwiftUI

/// Drawing the room and everything in it, ported from the web version.
extension World {
    static let skies: [SkyPhase: [Color]] = [
        .night: [Color(hex: "141B45"), Color(hex: "2C3A7A")], .dawn: [Color(hex: "A9D4F5"), Color(hex: "FFB59A")],
        .day: [Color(hex: "6EC3F4"), Color(hex: "CDEFFF")], .dusk: [Color(hex: "5A5BA8"), Color(hex: "F7945E")]
    ]
    static let hills: [SkyPhase: [Color]] = [
        .night: [Color(hex: "24365A"), Color(hex: "1C2C4C")], .dawn: [Color(hex: "9CC98A"), Color(hex: "7FB874")],
        .day: [Color(hex: "8BD17C"), Color(hex: "6CC05F")], .dusk: [Color(hex: "6E8F6A"), Color(hex: "5A7A5C")]
    ]

    func draw(_ p: Pen) {
        let garden = room == .garden
        if garden {
            drawGardenScenery(p)
        } else {
            drawRoom(p)
            drawSky(p)
            drawClouds(p)
            if let pic = G.pic { drawPicture(p, pic) }
            drawWindow(p)
            drawClock(p)
        }
        guard save != nil else { return }
        var list: [(CGFloat, (Pen) -> Void)] = garden ? gardenProps() : [
            (G.litter.y - 0.5, drawLitterBack), (G.litter.y + 0.5, drawLitterFront),
            (G.bowl.y, drawBowl),
            (G.bed.y - 0.5, drawBedBack), (G.bed.y + 0.5, drawBedFront)
        ]
        list.append((cat.y, drawTheCat))
        list.sort { $0.0 < $1.0 }
        for item in list { item.1(p) }
        if mode == .play { drawFeather(p) }
        if mode == .wash { drawSponge(p) }
        if garden { drawGardenAir(p) }
        if save!.lightsOff { drawDark(p) }
        drawParts(p)
        drawBubble(p)
        drawRoomFade(p)
    }

    // MARK: Room

    private func drawRoom(_ p: Pen) {
        let fy = G.floorY
        p.fillColor = Color(hex: "FDF0DD"); p.fillRect(0, 0, W, fy)
        p.fillColor = Color(hex: "FAE4C8")
        let sw = 24 * U
        var x: CGFloat = 0
        while x < W { p.fillRect(x, 0, sw, fy); x += sw * 2 }
        p.fillGradient([Color(hex: "D99A5B"), Color(hex: "E9B47A")], from: CGPoint(x: 0, y: fy), to: CGPoint(x: 0, y: H))
        p.fillRect(0, fy, W, H - fy)
        p.strokeColor = .rgba(140, 80, 30, 0.22); p.lineWidth = 2
        var y = fy, ph = 14 * U, row = 0
        while y < H {
            let y2 = y + ph
            p.beginPath(); p.moveTo(0, y2); p.lineTo(W, y2)
            var jx = CGFloat(row % 2) * 90 * U + 40 * U
            while jx < W { p.moveTo(jx, y); p.lineTo(jx, y2); jx += 180 * U }
            p.stroke()
            y = y2; ph *= 1.18; row += 1
        }
        p.fillColor = Color(hex: "FFF7EA"); p.fillRect(0, fy - 12 * U, W, 12 * U)
        p.fillColor = .rgba(140, 90, 40, 0.25); p.fillRect(0, fy - 1, W, 2)
        p.ell(W * 0.55, H * 0.885, W * 0.3, H * 0.075); p.fill(Color(hex: "A9DCD7"))
        p.dash = [10 * U, 8 * U]
        p.ell(W * 0.55, H * 0.885, W * 0.27, H * 0.058); p.stroke(.white, 3 * U)
        p.dash = []
    }

    private func drawSky(_ p: Pen) {
        let w = G.win, cols = World.skies[sky]!, hill = World.hills[sky]!
        p.fillGradient(cols, from: CGPoint(x: 0, y: w.minY), to: CGPoint(x: 0, y: w.maxY))
        p.fillRect(w.minX, w.minY, w.width, w.height)
        p.save()
        p.beginPath(); p.rect(w.minX, w.minY, w.width, w.height); p.clip()
        switch sky {
        case .night:
            p.fillColor = .white
            for i in 0..<26 {
                let fx = abs(sin(Double(i) * 12.9898) * 43758.5453).truncatingRemainder(dividingBy: 1)
                let fy = abs(sin(Double(i) * 78.233) * 12345.678).truncatingRemainder(dividingBy: 1)
                p.alpha = 0.5 + Double(i % 3) * 0.2
                p.circ(w.minX + CGFloat(fx) * w.width, w.minY + CGFloat(fy) * w.height * 0.7, (1 + CGFloat(i % 3) * 0.6) * U); p.fill()
            }
            p.alpha = 1
            let mx = w.minX + w.width * 0.72, my = w.minY + w.height * 0.26
            p.circ(mx, my, 30 * U); p.fill(.rgba(255, 244, 194, 0.18))
            p.circ(mx, my, 19 * U); p.fill(Color(hex: "FFF4C2"))
            p.fillColor = .rgba(220, 200, 140, 0.5)
            p.circ(mx - 6 * U, my - 4 * U, 4 * U); p.fill(); p.circ(mx + 6 * U, my + 6 * U, 3 * U); p.fill()
        case .day:
            let sx = w.minX + w.width * 0.78, sy = w.minY + w.height * 0.25
            p.circ(sx, sy, 32 * U); p.fill(.rgba(255, 216, 77, 0.35))
            p.circ(sx, sy, 21 * U); p.fill(Color(hex: "FFD84D"))
        case .dawn, .dusk:
            p.circ(w.minX + w.width * (sky == .dawn ? 0.25 : 0.75), w.minY + w.height * 0.74, 22 * U); p.fill(Color(hex: "FFB347"))
        }
        p.ell(w.minX + w.width * 0.25, w.minY + w.height * 1.05, w.width * 0.55, w.height * 0.32); p.fill(hill[0])
        p.ell(w.minX + w.width * 0.8, w.minY + w.height * 1.1, w.width * 0.6, w.height * 0.36); p.fill(hill[1])
        p.restore()
    }

    private func drawClouds(_ p: Pen) {
        guard sky != .night else { return }
        let w = G.win
        p.save()
        p.beginPath(); p.rect(w.minX, w.minY, w.width, w.height); p.clip()
        p.fillColor = sky == .day ? .rgba(255, 255, 255, 0.95) : .rgba(255, 235, 225, 0.85)
        for i in 0..<3 {
            let span = w.width + 160 * U
            let x = w.minX - 80 * U + (T * (8 + CGFloat(i) * 3) * U + CGFloat(i) * span / 3).truncatingRemainder(dividingBy: span)
            let s = U * (0.8 + CGFloat(i) * 0.15), y = w.minY + w.height * (0.2 + CGFloat(i) * 0.18)
            p.circ(x, y, 16 * s); p.fill()
            p.circ(x + 18 * s, y - 6 * s, 20 * s); p.fill()
            p.circ(x + 38 * s, y, 15 * s); p.fill()
            p.ell(x + 18 * s, y + 6 * s, 32 * s, 10 * s); p.fill()
        }
        p.restore()
    }

    private func drawPicture(_ p: Pen, _ r: CGRect) {
        p.beginPath()
        p.moveTo(r.minX + r.width * 0.3, r.minY - 7 * U); p.lineTo(r.midX, r.minY - 26 * U); p.lineTo(r.minX + r.width * 0.7, r.minY - 7 * U)
        p.stroke(Color(hex: "8B5A2B"), 2)
        p.circ(r.midX, r.minY - 26 * U, 3 * U); p.fill(Color(hex: "8B5A2B"))
        p.rr(r.minX - 7 * U, r.minY - 7 * U, r.width + 14 * U, r.height + 14 * U, 6 * U); p.fill(Color(hex: "C98B4F"))
        p.fillColor = Color(hex: "DFF3FF"); p.fillRect(r.minX, r.minY, r.width, r.height)
        p.save()
        p.translate(r.midX + 6 * U, r.midY + 4 * U); p.scale(U, U)
        p.ell(0, 0, 28, 15); p.fill(Color(hex: "F4A259"))
        p.beginPath(); p.moveTo(-24, 0); p.lineTo(-44, -14); p.lineTo(-44, 14); p.closePath(); p.fill()
        p.circ(14, -4, 5); p.fill(.white)
        p.circ(15, -4, 2.6); p.fill(Color(hex: "2B2027"))
        p.circ(34, -18, 4); p.stroke(.rgba(80, 150, 200, 0.7), 2)
        p.circ(40, -30, 3); p.stroke()
        p.restore()
    }

    /// `shade` fills the curtain with the night overlay instead, for the part that hangs in
    /// front of the window glass (which the overlay itself leaves bright).
    private func curtain(_ p: Pen, _ w: CGRect, _ ry: CGFloat, shade: Color? = nil) {
        let sway = sin(T * 0.8) * 3 * U
        let x0 = w.minX - 38 * U, x1 = w.minX + w.width * 0.2, bot = w.maxY + 26 * U
        let tieY = w.minY + w.height * 0.55, tieX = w.minX + w.width * 0.04
        p.beginPath()
        p.moveTo(x0, ry)
        p.lineTo(x1, ry)
        p.quadTo(x1 - w.width * 0.04 + sway, tieY - w.height * 0.25, tieX, tieY)
        p.quadTo(tieX + w.width * 0.12 + sway, tieY + w.height * 0.25, x1 - w.width * 0.04, bot)
        p.lineTo(x0, bot)
        p.closePath()
        if let shade {
            p.fill(shade)
            p.ell(tieX + 4 * U, tieY, 9 * U, 6 * U); p.fill(shade)
            return
        }
        p.fill(Color(hex: "F6A9B8")); p.stroke(Color(hex: "D9798F"), 2)
        p.beginPath()
        p.moveTo(x0 + 14 * U, ry + 6 * U); p.lineTo(x0 + 14 * U, bot - 6 * U)
        p.moveTo(x0 + 30 * U, ry + 6 * U); p.lineTo(x0 + 30 * U, bot - 6 * U)
        p.stroke(.rgba(255, 255, 255, 0.35), 3 * U)
        p.ell(tieX + 4 * U, tieY, 9 * U, 6 * U); p.fill(Color(hex: "E56B86"))
    }

    private func drawWindow(_ p: Pen) {
        let w = G.win, f = 9 * U
        p.strokeColor = .white; p.lineWidth = f
        p.strokeRect(w.minX, w.minY, w.width, w.height)
        p.beginPath()
        p.moveTo(w.midX, w.minY); p.lineTo(w.midX, w.maxY)
        p.moveTo(w.minX, w.minY + w.height * 0.45); p.lineTo(w.maxX, w.minY + w.height * 0.45)
        p.stroke(.white, f * 0.55)
        p.strokeColor = .rgba(160, 120, 80, 0.35); p.lineWidth = 1.5
        p.strokeRect(w.minX - f / 2, w.minY - f / 2, w.width + f, w.height + f)
        p.rr(w.minX - 16 * U, w.maxY + f / 2 - 2, w.width + 32 * U, 12 * U, 4 * U); p.fill(.white); p.stroke()
        let ry = w.minY - 24 * U
        p.beginPath(); p.moveTo(w.minX - 46 * U, ry); p.lineTo(w.maxX + 46 * U, ry); p.stroke(Color(hex: "B07D4F"), 6 * U)
        p.fillColor = Color(hex: "B07D4F")
        p.circ(w.minX - 48 * U, ry, 7 * U); p.fill(); p.circ(w.maxX + 48 * U, ry, 7 * U); p.fill()
        curtain(p, w, ry)
        p.save(); p.translate(2 * w.minX + w.width, 0); p.scale(-1, 1); curtain(p, w, ry); p.restore()
    }

    /// A cat clock that shows the real time.
    private func drawClock(_ p: Pen) {
        let r = G.clockR
        let c = Calendar.current.dateComponents([.hour, .minute, .second], from: Date())
        let h = CGFloat((c.hour ?? 0) % 12) + CGFloat(c.minute ?? 0) / 60
        let m = CGFloat(c.minute ?? 0) + CGFloat(c.second ?? 0) / 60
        p.save()
        p.translate(G.clock.x, G.clock.y)
        p.fillColor = Color(hex: "E07A5F")
        for s: CGFloat in [-1, 1] {
            p.beginPath(); p.moveTo(s * r * 0.85, -r * 0.45); p.lineTo(s * r * 0.78, -r * 1.28); p.lineTo(s * r * 0.2, -r * 0.92); p.closePath(); p.fill()
        }
        p.circ(0, 0, r); p.fill(.white); p.stroke(Color(hex: "E07A5F"), 5 * U)
        p.fillColor = Color(hex: "C9B8A8")
        for i in 0..<12 {
            let a = CGFloat(i) * .pi * 2 / 12
            p.circ(sin(a) * r * 0.78, -cos(a) * r * 0.78, (i % 3 == 0 ? 2.8 : 1.6) * U); p.fill()
        }
        p.save(); p.rotate(h / 12 * .pi * 2); p.beginPath(); p.moveTo(0, 0); p.lineTo(0, -r * 0.48); p.stroke(Color(hex: "4A3B35"), 4 * U); p.restore()
        p.save(); p.rotate(m / 60 * .pi * 2); p.beginPath(); p.moveTo(0, 0); p.lineTo(0, -r * 0.72); p.stroke(Color(hex: "4A3B35"), 2.6 * U); p.restore()
        p.circ(0, 0, 3.5 * U); p.fill(Color(hex: "E07A5F"))
        p.restore()
    }

    // MARK: Things on the floor

    private func drawLitterBack(_ p: Pen) {
        let s = objScale(G.litter.y)
        p.save(); p.translate(G.litter.x, G.litter.y); p.scale(s, s)
        p.ell(0, 0, 88, 12); p.fill(.rgba(90, 55, 30, 0.15))
        p.rr(-76, -74, 152, 40, 10); p.fill(Color(hex: "5FB48F")); p.stroke(Color(hex: "2F7A5A"), 3)
        p.ell(0, -44, 70, 13); p.fill(Color(hex: "EAD9A6"))
        p.fillColor = .rgba(180, 150, 90, 0.5)
        for i in 0..<9 { p.circ(-56 + CGFloat(i) * 14, -44 + CGFloat((i * 7) % 5) - 2, 1.6); p.fill() }
        let px: [CGFloat] = [-36, 4, 36], py: [CGFloat] = [-46, -50, -44]
        for i in 0..<min(save!.poop, 3) { CatArt.poo(p, px[i], py[i]) }
        p.restore()
    }

    private func drawLitterFront(_ p: Pen) {
        let s = objScale(G.litter.y)
        p.save(); p.translate(G.litter.x, G.litter.y); p.scale(s, s)
        p.rr(-82, -42, 164, 42, 10); p.fill(Color(hex: "7CCBA6")); p.stroke(Color(hex: "2F7A5A"), 3)
        p.rr(-70, -36, 60, 6, 3); p.fill(.rgba(255, 255, 255, 0.35))
        p.fillColor = .rgba(47, 122, 90, 0.45); CatArt.pawPrint(p, 50, -16, 7)
        if save!.poop > 0 {
            for i in 0..<min(3, save!.poop + 1) {
                let x0 = -30 + CGFloat(i) * 30
                let ph = (T * 0.8 + CGFloat(i) * 0.33).truncatingRemainder(dividingBy: 1)
                p.alpha = Double(0.8 * (1 - ph))
                p.beginPath()
                for j in 0...10 {
                    let yy = -60 - CGFloat(j) * 5 - ph * 30, xx = x0 + sin(CGFloat(j) * 0.9 + T * 4 + CGFloat(i)) * 5
                    if j == 0 { p.moveTo(xx, yy) } else { p.lineTo(xx, yy) }
                }
                p.stroke(.rgba(130, 175, 70, 1), 3)
            }
            p.alpha = 1
        }
        p.restore()
    }

    private func drawBowl(_ p: Pen) {
        let s = objScale(G.bowl.y)
        p.save(); p.translate(G.bowl.x, G.bowl.y); p.scale(s, s)
        p.ell(0, 0, 56, 9); p.fill(.rgba(90, 55, 30, 0.16))
        p.beginPath()
        p.moveTo(-50, -32); p.lineTo(50, -32); p.quadTo(46, -2, 34, 0); p.lineTo(-34, 0); p.quadTo(-46, -2, -50, -32)
        p.closePath(); p.fill(Color(hex: "4FA3E0")); p.stroke(Color(hex: "2B6A9A"), 3)
        p.text(String(name.uppercased().prefix(10)), 0, -15, size: 12, weight: .heavy, color: .white)
        p.ell(0, -32, 50, 10); p.fill(Color(hex: "86C7F2")); p.stroke()
        p.ell(0, -32, 42, 7); p.fill(Color(hex: "2D6E9E"))
        if let b = bowl, b.amount > 0.02 {
            switch b.food {
            case .kibble:
                let n = Int(ceil(14 * b.amount))
                for i in 0..<n {
                    p.circ(-32 + CGFloat((i * 37) % 64), -34 - CGFloat(i % 3) * 4, 5)
                    p.fill(i % 2 == 0 ? Color(hex: "C47B3E") : Color(hex: "A0612F"))
                }
            case .fish:
                p.save(); p.translate(0, -38)
                p.beginPath(); p.rect(-46, -30, 92 * b.amount, 60); p.clip()
                p.ell(4, 0, 26, 10); p.fill(Color(hex: "9FB7C9")); p.stroke(Color(hex: "5E7A90"), 2)
                p.beginPath(); p.moveTo(-20, 0); p.lineTo(-36, -10); p.lineTo(-36, 10); p.closePath(); p.fill(); p.stroke()
                p.circ(20, -2, 2.4); p.fill(Color(hex: "2B2027"))
                p.restore()
            case .shrimp:
                for i in 0..<Int(ceil(3 * b.amount)) {
                    p.beginPath(); p.arc(-20 + CGFloat(i) * 20, -40, 8, 0.2 * .pi, 1.4 * .pi); p.stroke(Color(hex: "FF8A80"), 7)
                }
            }
        }
        p.restore()
    }

    private func drawBedBack(_ p: Pen) {
        let s = objScale(G.bed.y)
        p.save(); p.translate(G.bed.x, G.bed.y); p.scale(s, s)
        p.ell(0, 0, 116, 16); p.fill(.rgba(90, 55, 30, 0.15))
        p.ell(0, -36, 112, 42); p.fill(Color(hex: "D29A5E")); p.stroke(Color(hex: "8B5A2B"), 3)
        p.ell(0, -38, 94, 28); p.fill(Color(hex: "F4A6C6"))
        p.ell(0, -38, 70, 18); p.stroke(.rgba(200, 100, 140, 0.5), 2)
        p.restore()
    }

    private func drawBedFront(_ p: Pen) {
        let s = objScale(G.bed.y)
        p.save(); p.translate(G.bed.x, G.bed.y); p.scale(s, s)
        p.beginPath()
        p.ellipse(0, -36, 112, 42, from: 0, to: .pi)
        p.ellipse(0, -30, 98, 22, from: .pi, to: 0, ccw: true)
        p.closePath()
        p.fill(Color(hex: "D9A468")); p.stroke(Color(hex: "8B5A2B"), 3)
        p.beginPath()
        var a: CGFloat = 0.12
        while a < 0.9 {
            let ang = a * .pi
            p.moveTo(cos(ang) * 99, -30 + sin(ang) * 23)
            p.lineTo(cos(ang) * 111, -36 + sin(ang) * 41)
            a += 0.07
        }
        p.stroke(.rgba(139, 90, 43, 0.45), 2)
        p.restore()
    }

    // MARK: The cat

    private func drawTheCat(_ p: Pen) {
        let s = catScale
        let dirt = CGFloat(min(max((45 - save!.needs.clean) / 45, 0), 1))
        if cat.activity == .sleep {
            CatArt.drawSleepingCat(p, x: cat.x + 6 * U, y: cat.y - 24 * objScale(cat.y), s: s, coat: coat, stage: stage,
                                   wear: save!.wear, t: T, dirt: dirt)
            return
        }
        var pose = CatPose(coat: coat, stage: stage)
        pose.x = cat.x; pose.y = cat.y; pose.s = s
        let walking = cat.activity == .walk || ((cat.activity == .play || cat.activity == .fish) && cat.moving)
        let m = mood
        pose.blush = m == "happy"
        pose.lookX = cat.look
        pose.tilt = sin(cat.t * 1.4) * 0.04
        if m == "sad" { pose.eyes = .sad; pose.mouth = .sad; pose.tear = save!.needs.lowest < 6 } else if m == "meh" { pose.mouth = .flat }
        if save!.needs.energy < 25 { pose.lid = 0.45 }
        if cat.petT > 0 || cat.scrubT > 0 || cat.happyT > 0 { pose.eyes = .happy; pose.mouth = .smile; pose.blush = true; pose.lid = 0; pose.tear = false }
        switch cat.activity {
        case .eat:
            pose.eyes = .happy; pose.mouth = Int(cat.t * 6) % 2 == 1 ? .open : .smile; pose.tilt = -0.22; pose.lookX = -1
        case .poop:
            pose.eyes = .closed; pose.mouth = .flat
        case .play:
            pose.eyes = .wide; pose.lid = 0; pose.mouth = cat.jump != nil ? .open : .smile
            let hp = catHeadPos()
            pose.lookX = min(max((feather.x - hp.x) / (120 * U), -1), 1)
            pose.lookY = min(max((feather.y - hp.y) / (120 * U), -1), 1)
            pose.tilt = min(max((feather.x - cat.x) / (600 * U), -0.25), 0.25)
        case .fish:
            pose.eyes = .wide; pose.lid = 0; pose.mouth = cat.jump != nil ? .open : .smile
            if let f = watchedFish() {
                let hp = catHeadPos()
                pose.lookX = min(max((f.x - hp.x) / (120 * U), -1), 1)
                pose.lookY = min(max((f.y - hp.y) / (120 * U), -1), 1)
            }
        default:
            break
        }
        if cat.mouthT > 0 { pose.mouth = .open }
        if cat.blink > 0 && (pose.eyes == .open || pose.eyes == .wide || pose.eyes == .sad) { pose.eyes = .blink }
        if walking { pose.tilt += sin(cat.t * 10) * 0.05 }
        pose.tail = cat.tail
        pose.wear = save!.wear
        pose.dirt = dirt
        pose.pawsUp = cat.jump != nil
        pose.lift = catLift()
        pose.step = walking ? sin(cat.t * 10) : 0
        CatArt.drawCat(p, pose)
        if save!.needs.clean < 20 { drawFlies(p, catHeadPos(), s) }
    }

    private func drawFlies(_ p: Pen, _ h: CGPoint, _ s: CGFloat) {
        for i in 0..<2 {
            let a = T * (3 + CGFloat(i)) + CGFloat(i) * 2
            let x = h.x + cos(a) * 70 * s, y = h.y + sin(a * 1.3) * 40 * s - 20 * s
            p.ell(x - 3, y - 4, 4, 2.5, -0.5); p.fill(.rgba(255, 255, 255, 0.75))
            p.ell(x + 3, y - 4, 4, 2.5, 0.5); p.fill()
            p.circ(x, y, 3); p.fill(Color(hex: "222222"))
        }
    }

    // MARK: Toys and overlays

    private func drawFeather(_ p: Pen) {
        let tipX = feather.x + 60 * U, tipY = max(20 * U, feather.y - 180 * U)
        p.beginPath(); p.moveTo(min(max(feather.x + 200 * U, 0), W + 40), -10); p.lineTo(tipX, tipY); p.stroke(Color(hex: "B07D4F"), 7 * U)
        p.beginPath(); p.moveTo(tipX, tipY)
        p.quadTo((tipX + feather.x) / 2 + 10 * U, (tipY + feather.y) / 2 + 30 * U, feather.x, feather.y)
        p.stroke(.rgba(80, 60, 50, 0.7), 2)
        p.save()
        p.translate(feather.x, feather.y); p.rotate(feather.ang); p.scale(U, U)
        p.ell(0, 26, 11, 30); p.fill(Color(hex: "FF7EB6"))
        p.fillColor = Color(hex: "7AD3F0")
        p.ell(-10, 30, 7, 22, 0.35); p.fill()
        p.ell(10, 30, 7, 22, -0.35); p.fill()
        p.beginPath(); p.moveTo(0, -2); p.lineTo(0, 54); p.stroke(.white, 2)
        p.circ(0, -2, 6); p.fill(Color(hex: "FFD23F"))
        p.restore()
    }

    private func drawSponge(_ p: Pen) {
        p.save()
        p.translate(sponge.x, sponge.y)
        p.rotate(-0.25 + (cat.scrubT > 0 ? sin(T * 30) * 0.12 : 0))
        p.scale(U, U)
        p.rr(-34, -22, 68, 44, 12); p.fill(Color(hex: "FFD84D")); p.stroke(Color(hex: "C9A21E"), 3)
        p.rr(-34, -22, 68, 14, 8); p.fill(Color(hex: "5BC57A")); p.stroke()
        p.fillColor = Color(hex: "E8BE2E")
        p.circ(-16, 4, 4); p.fill(); p.circ(4, 10, 3); p.fill(); p.circ(18, 2, 4.5); p.fill(); p.circ(-4, -2, 2.5); p.fill()
        p.restore()
    }

    private func drawDark(_ p: Pen) {
        let w = G.win
        let night = Color.rgba(14, 18, 48, 0.62)
        p.beginPath(); p.rect(0, 0, W, H); p.rect(w.minX, w.minY, w.width, w.height)
        p.fillColor = night; p.fill(evenOdd: true)
        // the curtains in front of the glass get the same shade as the rest of the room
        p.save()
        p.beginPath(); p.rect(w.minX, w.minY, w.width, w.height); p.clip()
        let ry = w.minY - 24 * U
        curtain(p, w, ry, shade: night)
        p.save(); p.translate(2 * w.minX + w.width, 0); p.scale(-1, 1); curtain(p, w, ry, shade: night); p.restore()
        p.restore()
        p.beginPath()
        p.moveTo(w.minX, w.maxY); p.lineTo(w.maxX, w.maxY); p.lineTo(w.minX + w.width * 1.5, H); p.lineTo(w.minX + w.width * 0.1, H)
        p.closePath(); p.fill(.rgba(200, 210, 255, 0.06))
    }

    private func drawParts(_ p: Pen) {
        for q in parts {
            p.alpha = Double(min(max(q.life / q.max * 1.6, 0), 1))
            switch q.kind {
            case .heart:
                heart(p, q.x, q.y, q.size); p.fill(Color(hex: "FF4F86"))
                p.circ(q.x - q.size * 0.45, q.y - q.size * 0.55, q.size * 0.2); p.fill(.rgba(255, 255, 255, 0.6))
            case .bubble:
                p.circ(q.x, q.y, q.size); p.fill(.rgba(255, 255, 255, 0.45)); p.stroke(.rgba(110, 170, 230, 0.9), 2)
                p.circ(q.x - q.size * 0.35, q.y - q.size * 0.35, q.size * 0.25); p.fill(.rgba(255, 255, 255, 0.9))
            case .sparkle:
                star(p, q.x, q.y, q.size * (0.6 + 0.4 * sin(q.ph + q.life * 10))); p.fill(Color(hex: "FFD84D"))
            case .zzz:
                p.text("Z", q.x, q.y, size: q.size * (1.6 - q.life / q.max * 0.6), weight: .heavy, color: Color(hex: "C9D2FF"))
            case .text:
                p.text(q.text, q.x, q.y, size: q.size, weight: .heavy, color: Color(hex: "8A5A3C"))
            }
        }
        p.alpha = 1
    }

    private func heart(_ p: Pen, _ x: CGFloat, _ y: CGFloat, _ r: CGFloat) {
        p.beginPath()
        p.moveTo(x, y + r * 0.95)
        p.bezierTo(x - r * 1.7, y - r * 0.2, x - r * 0.65, y - r * 1.45, x, y - r * 0.45)
        p.bezierTo(x + r * 0.65, y - r * 1.45, x + r * 1.7, y - r * 0.2, x, y + r * 0.95)
        p.closePath()
    }

    private func star(_ p: Pen, _ x: CGFloat, _ y: CGFloat, _ r: CGFloat) {
        p.beginPath()
        for i in 0..<8 {
            let a = CGFloat(i) * .pi / 4 - .pi / 2, d = i % 2 == 1 ? r * 0.38 : r
            if i == 0 { p.moveTo(x + cos(a) * d, y + sin(a) * d) } else { p.lineTo(x + cos(a) * d, y + sin(a) * d) }
        }
        p.closePath()
    }

    private func drawBubble(_ p: Pen) {
        guard let b = bubble else { return }
        let s = catScale
        var ax: CGFloat, ay: CGFloat
        if cat.activity == .sleep { ax = cat.x - 40 * s; ay = cat.y - 120 * s } else {
            let hp = catHeadPos(); ax = hp.x; ay = hp.y - 72 * stage.head * s
        }
        let fs = min(max(22 * U, 17), 30)
        let tw = p.measure(b.text, size: fs).width
        let bw = tw + fs * 1.4, bh = fs * 2
        let bx = min(max(ax - bw / 2, 8), W - bw - 8)
        let by = max(6, ay - bh - 16)
        let age = b.d - b.t
        let pop = reduceMotion ? 1 : 0.85 + 0.15 * min(max(age * 6, 0), 1)
        p.save()
        p.alpha = Double(min(max(min(age * 6, b.t * 3), 0), 1))
        p.translate(ax, by + bh); p.scale(pop, pop); p.translate(-ax, -(by + bh))
        let tx = min(max(ax, bx + 18), bx + bw - 18), r: CGFloat = 16
        p.beginPath()
        p.moveTo(bx + r, by)
        p.lineTo(bx + bw - r, by); p.quadTo(bx + bw, by, bx + bw, by + r)
        p.lineTo(bx + bw, by + bh - r); p.quadTo(bx + bw, by + bh, bx + bw - r, by + bh)
        p.lineTo(tx + 11, by + bh); p.lineTo(tx, by + bh + 14); p.lineTo(tx - 11, by + bh)
        p.lineTo(bx + r, by + bh); p.quadTo(bx, by + bh, bx, by + bh - r)
        p.lineTo(bx, by + r); p.quadTo(bx, by, bx + r, by)
        p.closePath()
        p.fill(.white); p.stroke(Color(hex: "5A4A42"), 2.5)
        p.text(b.text, bx + bw / 2, by + bh / 2 + 1, size: fs, color: Color(hex: "4A3B35"))
        p.restore()
    }
}
