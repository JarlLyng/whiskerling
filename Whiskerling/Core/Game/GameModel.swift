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
    /// The other cat, shown small next to the name (#21).
    var otherName: String?
    var otherCoat: String?
    var otherWear = Wear()
    /// The first cat is grown up and alone: a "+" offers a kitten.
    var canAdopt = false
    /// Fish cookies in the kitchen's jar (#38).
    var cookies = 0
}

enum Overlay { case food, wardrobe, games, rooms }

enum AdultRoute: String, Identifiable {
    case paywall, menu
    var id: String { rawValue }
}

/// The locked thing a child tapped on the way to the paywall. Once Pro is bought (or restored),
/// the paywall closes by itself and the tap is finished, so the child doesn't have to tap again.
enum ProUnlock: Equatable {
    case garden, kitchen, fish, hide, adopt, coat(String), item(String), startCoat(String), decor(String)
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
    /// A Pro coat bought from the start screen, for the start screen to pick.
    var startCoat: String?
    /// The start screen is open for a second kitten (#21).
    var adopting = false

    @ObservationIgnored private var toastQueue: [String] = []
    @ObservationIgnored private var syncScheduled = false
    @ObservationIgnored private(set) var pendingUnlock: ProUnlock?
    /// Screenshots show Pro as bought (debug builds only).
    @ObservationIgnored var forcedPro = false

    /// `defaults` is where the cat is saved; the tests pass their own, so a real cat is never touched.
    init(defaults: UserDefaults = .standard) {
        world = World(sound: sound)
        world.defaults = defaults
        #if DEBUG
        if let scene = GameModel.screenshotScene {
            setUpScreenshot(scene)
            sync()
            return
        }
        #endif
        if let saved = SaveStore.load(from: defaults) {
            world.loadExisting(saved)
            sound.enabled = saved.sound
            hasCat = true
        }
        sync()
    }

    var isPro: Bool { store.isPro || forcedPro }

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
            case .bakeStarted: mode = .bake; overlay = nil
            case .hint(let text): modeHint = text
            }
        }
        guard let s = world.save else { return }
        let stage = Catalog.stages[s.stage]
        let day = Int(Date().timeIntervalSince(s.born) / 86_400) + 1
        let newItems = Catalog.items.contains { $0.cost > s.seenHearts && $0.cost <= s.hearts && ($0.isFree || isPro) }
        let next = HUD(name: s.name, needs: s.needs, hearts: s.hearts, stageLabel: L10n.stageDay(stage.name, day),
                       lightsOff: s.lightsOff, sound: s.sound, hasNewItems: newItems, room: world.room,
                       otherName: s.companion?.name, otherCoat: s.companion?.coat, otherWear: s.companion?.wear ?? Wear(),
                       canAdopt: world.canAdopt, cookies: s.cookies ?? 0)
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

    /// Play opens a choice of games: the feather (free), and Catch the fish and hide and seek (Pro).
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
        if !isPro { askForPro(.fish); return }
        startFishing()
        sync()
    }

    private func startFishing() {
        if world.startFishing() { mode = .fish; modeHint = L10n.fishHint }
    }

    /// Hide and seek (#20, Pro), in whichever room the cat is in.
    func playHide() {
        sound.click()
        overlay = nil
        if !isPro { askForPro(.hide); return }
        startHide()
        sync()
    }

    private func startHide() {
        if world.startHide() { mode = .hide; modeHint = L10n.hideHint(hud.name) }
    }

    /// Out to the garden (Pro) or back into the living room.
    /// "Go to…": a choice of the living room, the kitchen (#38) and the garden.
    func tapRoom() {
        sound.click()
        if hud.lightsOff { showToast(L10n.asleep(hud.name)); return }
        overlay = .rooms
    }

    /// The garden and the kitchen need Pro: locked, the gate and the paywall open, and the move is
    /// finished after buying.
    func go(to r: Room) {
        sound.click()
        overlay = nil
        guard world.room != r else { return }
        if r != .living && !isPro { askForPro(r == .garden ? .garden : .kitchen); return }
        world.go(to: r)
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

    // MARK: Two cats (#21)

    /// The "+" next to a grown-up cat's name: a kitten to live with it, with Pro.
    func tapAdopt() {
        sound.click()
        guard world.canAdopt, mode == .normal else { return }
        if !isPro { askForPro(.adopt); return }
        adopting = true
    }

    func adopt(name: String, coat: String) {
        world.adopt(name: name, coat: coat)
        adopting = false
        overlay = nil
        sync()
    }

    func cancelAdopt() {
        sound.click()
        adopting = false
    }

    /// The other cat's picture next to the name: show that cat instead.
    func switchCats() {
        sound.click()
        guard mode == .normal else { return }
        world.switchCats()
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
        if !item.isFree && !isPro { askForPro(.item(item.id)); return }
        if s.hearts < item.cost { showToast(L10n.needHearts(item.cost)); return }
        let wearing = s.wear[item.slot] == item.id
        world.save!.wear[item.slot] = wearing ? nil : item.id
        world.dressed(!wearing)
        sync()
    }

    /// A decoration for the room (#18): free ones, or Pro ones once Pro is bought, when enough
    /// hearts have been collected. Choosing it again takes it away.
    func choose(decor: Decor) {
        guard let s = world.save else { return }
        sound.click()
        if !decor.isFree && !isPro { askForPro(.decor(decor.id)); return }
        if s.hearts < decor.cost { showToast(L10n.needHearts(decor.cost)); return }
        world.toggleDecor(decor.id)
        sync()
    }

    func choose(coat: Coat) {
        sound.click()
        if !coat.isFree && !isPro { askForPro(.coat(coat.id)); return }
        guard world.save != nil, world.save!.coat != coat.id else { return }
        world.save!.coat = coat.id
        world.dressed(true)
        sync()
    }

    func toggleSoundFromMenu() { toggleSound() }

    func startOver() {
        world.removeCat()
        hasCat = false
        adopting = false
        overlay = nil
        adult = nil
        mode = .normal
        hud = HUD()
    }

    // MARK: Pro

    /// A lock was tapped: open the paywall (behind the gate) and remember what the tap was for.
    func askForPro(_ unlock: ProUnlock) {
        pendingUnlock = unlock
        adult = .paywall
    }

    /// The grown-ups' sheet closed without Pro being bought: the tap is forgotten.
    func adultClosed() {
        pendingUnlock = nil
    }

    /// Called when StoreKit has an answer. Before the first answer Pro is unknown, so the cat
    /// stays where it was saved; after it, losing Pro (a refund) brings the cat inside.
    func proChanged() {
        world.isPro = isPro
        if store.entitlementChecked && !isPro { world.proLost() }
        if isPro, let unlock = pendingUnlock { finish(unlock) }
        sync()
    }

    /// Pro arrived while the paywall was open from a lock: close it and do what the tap asked for.
    /// Hearts still decide whether an accessory can be worn.
    private func finish(_ unlock: ProUnlock) {
        pendingUnlock = nil
        adult = nil
        switch unlock {
        case .garden: world.go(to: .garden)
        case .kitchen: world.go(to: .kitchen)
        case .fish: startFishing()
        case .hide: startHide()
        case .coat(let id): choose(coat: Catalog.coat(id))
        case .item(let id): if let item = Catalog.items.first(where: { $0.id == id }) { choose(item: item) }
        case .startCoat(let id): startCoat = id
        case .adopt: if world.canAdopt { adopting = true }
        case .decor(let id): if let decor = Catalog.decor.first(where: { $0.id == id }) { choose(decor: decor) }
        }
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
