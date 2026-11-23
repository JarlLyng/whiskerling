import SwiftUI

/// The living room's decorations (#18): where they stand and when they are drawn. The care places
/// (the bowl, the basket and the litter box) and their tap areas never move.
extension World {
    func shows(_ decor: String) -> Bool { save?.decor?.contains(decor) == true }

    /// Puts a decoration up or takes it away, and saves.
    func toggleDecor(_ id: String) {
        guard save != nil else { return }
        var list = save!.decor ?? []
        let adding = !list.contains(id)
        if adding { list.append(id) } else { list.removeAll { $0 == id } }
        save!.decor = list
        if adding {
            let spot = decorSpot(id)
            burst(.sparkle, spot.x, spot.y, count: 12, speed: 160 * U, life: 1, size: 9 * U)
            sound.chime()
            cat.happyT = 1
        }
        persist()
        hudDue = true
    }

    /// On the floor right of the window, at the back, behind everything the cat walks past.
    var plantSpot: CGPoint { CGPoint(x: G.win.maxX + 50 * U, y: G.floorY + 24 * U) }
    /// At the back on the right, under the space between the picture and the clock.
    var catTreeSpot: CGPoint {
        CGPoint(x: max(G.clock.x - 130 * U, plantSpot.x + 130 * U), y: G.floorY + 30 * U)
    }

    /// Where the sparkles go when something is put up.
    func decorSpot(_ id: String) -> CGPoint {
        switch id {
        case "plant": return CGPoint(x: plantSpot.x, y: plantSpot.y - 100 * objScale(plantSpot.y))
        case "cattree": return CGPoint(x: catTreeSpot.x, y: catTreeSpot.y - 170 * objScale(catTreeSpot.y))
        case "rug": return CGPoint(x: W * 0.55, y: H * 0.885)
        case "portrait": return G.pic.map { CGPoint(x: $0.midX, y: $0.midY) } ?? CGPoint(x: W / 2, y: G.floorY / 2)
        case "lights": return CGPoint(x: G.win.midX, y: G.win.minY - 10 * U)
        default: return CGPoint(x: W / 2, y: G.floorY / 2)
        }
    }

    /// The floor-standing decorations, for the depth-sorted list of things in the room.
    func decorProps() -> [(CGFloat, (Pen) -> Void)] {
        var list: [(CGFloat, (Pen) -> Void)] = []
        if shows("plant") { list.append((plantSpot.y, drawPlant)) }
        if shows("cattree") { list.append((catTreeSpot.y, drawCatTree)) }
        return list
    }

    func drawPlant(_ p: Pen) {
        let sway = reduceMotion ? 0 : sin(T * 0.7) * 0.03
        DecorArt.plant(p, plantSpot.x, plantSpot.y, objScale(plantSpot.y) * 1.1, sway: sway)
    }

    func drawCatTree(_ p: Pen) {
        // a little larger than the room's scale, so it stands taller than a grown-up cat
        DecorArt.catTree(p, catTreeSpot.x, catTreeSpot.y, objScale(catTreeSpot.y) * 1.3, swing: reduceMotion ? 0 : sin(T * 1.3))
    }

    /// Hung along the curtain rod. `glow` is for a dark room, drawn over the dark.
    func drawLights(_ p: Pen, glow: Bool) {
        let w = G.win, ry = w.minY - 24 * U
        DecorArt.lights(p, from: CGPoint(x: w.minX - 40 * U, y: ry + 3 * U), to: CGPoint(x: w.maxX + 40 * U, y: ry + 3 * U),
                        sag: 13 * U, bulb: 5 * U, glow: glow, t: reduceMotion ? 0 : T)
    }

    /// Small hearts in rows on the wall instead of the stripes.
    func drawHeartWallpaper(_ p: Pen) {
        let gap = 48 * U, r = 6 * U
        p.fillColor = DecorArt.wallHeart
        var row = 0, y = gap * 0.6
        while y < G.floorY - 14 * U {
            var x = row % 2 == 0 ? gap * 0.5 : gap
            while x < W + r {
                DecorArt.heart(p, x, y, r); p.fill()
                x += gap
            }
            y += gap * 0.8; row += 1
        }
    }

    /// The cat's own head, in its coat and with what it wears, for the picture on the wall.
    var portraitPose: CatPose? {
        guard let s = save else { return nil }
        return CatPose(coat: Catalog.coat(s.coat), stage: stage, eyes: .open, blush: true, wear: s.wear)
    }
}
