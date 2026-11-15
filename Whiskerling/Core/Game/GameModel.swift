import SwiftUI

/// What the buttons and bars show. Copied from the world a few times a second.
struct HUD: Equatable {
    var name = ""
    var needs = Needs()
    var hearts = 0
    var stageLabel = ""
    var lightsOff = false
    var sound = true
    var hasNewItems = false
    var room = Room.living
}

enum Overlay { case food, wardrobe, games }

enum AdultRoute: String, Identifiable {
    case paywall, menu
    var id: String { rawValue }
}

/// The bridge between the game world (drawn every frame) and the SwiftUI screens.
@MainActor
@Observable
final class GameModel {
    @ObservationIgnored let sound = SoundEngine()
    @ObservationIgnored let world: World
    let store = Store()

    var hasCat = false
    var hud = HUD()
    var mode: GameMode = .normal
    var modeHint = ""
    var overlay: Overlay?
    var adult: AdultRoute?
    var toast: String?

    @ObservationIgnored private var toastQueue: [String] = []
    @ObservationIgnored private var syncScheduled = false

    init() {
        world = World(sound: sound)
        if let saved = SaveStore.load() {
            world.loadExisting(saved)
            sound.enabled = saved.sound
            hasCat = true
        }
        sync()
    }

    var isPro: Bool { store.isPro }

    // MARK: World hand-over

    /// Called from the canvas while it draws; the actual update happens right after.
    func scheduleSync() {
        guard !syncScheduled else { return }
        syncScheduled = true
        DispatchQueue.main.async { [weak self] in self?.sync() }
    }

    func sync() {
        syncScheduled = false
        for event in world.takeEvents() {
            switch event {
            case .toast(let text): showToast(text)
            case .modeEnded: mode = .normal
            case .openFood: if mode == .normal { overlay = .food }
            case .itemsChanged: break
            case .fishingStarted: mode = .fish; modeHint = L10n.fishHint
            }
        }
        guard let s = world.save else { return }
        let stage = Catalog.stages[s.stage]
        let day = Int(Date().timeIntervalSince(s.born) / 86_400) + 1
        let newItems = Catalog.items.contains { $0.cost > s.seenHearts && $0.cost <= s.hearts && ($0.isFree || isPro) }
        let next = HUD(name: s.name, needs: s.needs, hearts: s.hearts, stageLabel: L10n.stageDay(stage.name, day),
                       lightsOff: s.lightsOff, sound: s.sound, hasNewItems: newItems, room: world.room)
        if next != hud { hud = next }
    }

    // MARK: Toasts

    func showToast(_ text: String) {
        toastQueue.append(text)
        if toast == nil { nextToast() }
    }

    private func nextToast() {
        guard !toastQueue.isEmpty else { toast = nil; return }
        toast = toastQueue.removeFirst()
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(2.6))
            toast = nil
            try? await Task.sleep(for: .seconds(0.35))
            nextToast()
        }
    }

    // MARK: Actions

    func startNewCat(name: String, coat: String) {
        world.startNewCat(name: name, coat: coat)
        sound.enabled = true
        hasCat = true
        mode = .normal
        sync()
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(4.5))
            showToast(L10n.petTip(name))
        }
    }

    func tapFeed() {
        sound.click()
        if hud.lightsOff { showToast(L10n.asleep(hud.name)); return }
        overlay = .food
    }

    func feed(_ food: Food) {
        sound.click()
        overlay = nil
        world.feed(food)
    }

    /// Play opens a choice of games: the feather (free) and Catch the fish (Pro).
    func tapPlay() {
        sound.click()
        if hud.lightsOff { showToast(L10n.asleep(hud.name)); return }
        overlay = .games
    }

    func playFeather() {
        sound.click()
        overlay = nil
        if world.startPlay() { mode = .play; modeHint = L10n.playHint(hud.name) }
    }

    func playFish() {
        sound.click()
        overlay = nil
        if !isPro { adult = .paywall; return }
        if world.startFishing() { mode = .fish; modeHint = L10n.fishHint }
        sync()
    }

    /// Out to the garden (Pro) or back into the living room.
    func tapRoom() {
        sound.click()
        if hud.lightsOff { showToast(L10n.asleep(hud.name)); return }
        if world.room == .garden {
            world.comeInside()
        } else if !isPro {
            adult = .paywall
        } else {
            world.goOutside()
        }
        sync()
    }

    func tapWash() {
        sound.click()
        if hud.lightsOff { showToast(L10n.asleep(hud.name)); return }
        if world.startWash() {
            mode = .wash
            let litter = (world.save?.poop ?? 0) > 0 && world.room == .living
            modeHint = litter ? L10n.washLitterHint(hud.name) : L10n.washHint(hud.name)
        }
    }

    func tapSleep() {
        sound.click()
        world.toggleLights()
        sync()
    }

    func tapDone() {
        sound.click()
        world.setMode(.normal)
        mode = .normal
    }

    func openWardrobe() {
        sound.click()
        guard mode == .normal else { return }
        if var s = world.save { s.seenHearts = max(s.seenHearts, s.hearts); world.save = s }
        overlay = .wardrobe
        sync()
    }

    func toggleSound() {
        guard world.save != nil else { return }
        world.save!.sound.toggle()
        sound.enabled = world.save!.sound
        sound.click()
        world.persist()
        sync()
    }

    /// Free items, or Pro items once Pro is bought. Hearts still decide when they unlock.
    func choose(item: Item) {
        guard let s = world.save else { return }
        sound.click()
        if !item.isFree && !isPro { adult = .paywall; return }
        if s.hearts < item.cost { showToast(L10n.needHearts(item.cost)); return }
        let wearing = s.wear[item.slot] == item.id
        world.save!.wear[item.slot] = wearing ? nil : item.id
        world.dressed(!wearing)
        sync()
    }

    func choose(coat: Coat) {
        sound.click()
        if !coat.isFree && !isPro { adult = .paywall; return }
        guard world.save != nil, world.save!.coat != coat.id else { return }
        world.save!.coat = coat.id
        world.dressed(true)
        sync()
    }

    func toggleSoundFromMenu() { toggleSound() }

    func startOver() {
        world.removeCat()
        hasCat = false
        overlay = nil
        adult = nil
        mode = .normal
        hud = HUD()
    }

    /// Called when StoreKit has an answer. Before the first answer Pro is unknown, so the cat
    /// stays where it was saved; after it, losing Pro (a refund) brings the cat inside.
    func proChanged() {
        world.isPro = store.isPro
        if store.entitlementChecked && !store.isPro { world.proLost() }
        sync()
    }

    // MARK: App lifecycle

    func didBecomeActive() {
        world.resume()
        sync()
    }

    func willResignActive() {
        sound.stopPurr()
        world.persist()
    }
}
