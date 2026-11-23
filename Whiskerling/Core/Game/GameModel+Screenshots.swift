#if DEBUG
import Foundation

/// App Store screenshots, the pattern from `DESIGN.md` (debug builds only): launch with
/// `-screenshots -screen <scene>` and `-debugSky day|night`, then `xcrun simctl io <device>
/// screenshot`. Scenes: `room`, `gate`, `fish`, `wardrobe`, `night`, `party` and `nap` for
/// checking the grown-up cat, `decor` and `decornight` for the room with everything put up, and
/// `hide` for hide and seek: the cat hidden at `-hideSpot <id>` (basket, litter, rug or curtain
/// indoors; tree, fenceLeft, fenceRight or pond in the garden), or `-hideSpot count` for the
/// counting. The sample cat lives in its own UserDefaults suite, so a real cat is
/// never touched, and Pro is shown as bought.
extension GameModel {
    static var screenshotScene: String? {
        guard ProcessInfo.processInfo.arguments.contains("-screenshots") else { return nil }
        return UserDefaults.standard.string(forKey: "screen") ?? "room"
    }

    func setUpScreenshot(_ scene: String) {
        world.defaults = UserDefaults(suiteName: "whiskerling.screenshots") ?? .standard
        let coats = ["room": "orange", "gate": "orange", "fish": "tabby", "wardrobe": "calico", "night": "white",
                     "decor": "tabby", "decornight": "tabby"]
        var s = SaveState(name: "Luna", coat: coats[scene] ?? "orange")
        s.needs = Needs(food: 88, fun: 92, energy: 84, clean: 96)
        s.hearts = 140
        s.seenHearts = 140
        switch scene {
        case "fish":
            s.room = Room.garden.rawValue
            s.wear = Wear(head: "hat")
        case "wardrobe":
            s.wear = Wear(head: "flowers", neck: "bell")
        case "hide": // hide and seek (#20)
            let spot = UserDefaults.standard.string(forKey: "hideSpot") ?? "basket"
            if ["tree", "fenceLeft", "fenceRight", "pond"].contains(spot) { s.room = Room.garden.rawValue }
            s.wear = Wear(head: "bow")
        case "night":
            s.lightsOff = true
            s.needs.energy = 46
            s.wear = Wear(neck: "scarf")
        case "party", "nap": // a grown-up cat (#17), a year old for its first birthday
            s.stage = Catalog.stages.count - 1
            s.born = Date().addingTimeInterval(-(scene == "party" ? 366 : 30) * 86_400)
            s.birthdays = scene == "party" ? 1 : nil
            s.grownUpParty = true
            s.wear = Wear(head: "bow")
        case "decor", "decornight": // everything for the room put up (#18)
            s.hearts = 520; s.seenHearts = 520
            s.decor = Catalog.decor.map(\.id)
            if scene == "decornight" { s.lightsOff = true; s.needs.energy = 46 } // tired, so the lights stay off
            s.wear = Wear(head: "bow")
        default:
            s.wear = Wear(head: "bow")
        }
        forcedPro = true
        world.isPro = true
        sound.enabled = false
        world.save = s
        world.screenshotScene = scene
        hasCat = true
        switch scene {
        case "fish":
            world.setMode(.fish)
            mode = .fish
            modeHint = L10n.fishHint
        case "wardrobe":
            overlay = .wardrobe
        case "gate":
            adult = .menu
        case "hide":
            mode = .hide
            modeHint = L10n.hideHint(s.name)
        default:
            break
        }
    }
}
#endif
