import Foundation

struct Needs: Codable, Equatable {
    var food: Double = 75
    var fun: Double = 80
    var energy: Double = 90
    var clean: Double = 95

    var lowest: Double { min(food, fun, energy, clean) }
    var average: Double { (food + fun + energy + clean) / 4 }

    mutating func clamp() {
        food = Swift.min(Swift.max(food, 0), 100)
        fun = Swift.min(Swift.max(fun, 0), 100)
        energy = Swift.min(Swift.max(energy, 0), 100)
        clean = Swift.min(Swift.max(clean, 0), 100)
    }
}

/// What is a cat's own, as opposed to the household's (#21): a second cat keeps these here.
struct CatRecord: Codable, Equatable {
    var name: String
    var coat: String
    var born: Date
    var needs = Needs()
    var wear = Wear(head: "bow")
    var stage = 0
    var awakeMinutes: Double = 0
    var birthdays: Int?
    var grownUpParty: Bool?
}

/// Everything about the cat that survives the app closing. Stored as JSON on the device only.
///
/// The cat shown in the top bar keeps its own fields (`name` through `grownUpParty` below) right
/// here, and a second cat keeps them in `companion` (#21). Switching which cat is shown swaps the
/// two, so everything that looks at "the cat" looks at the one shown. The rest (hearts, the room,
/// the light, the litter box, decorations) belongs to the household.
struct SaveState: Codable, Equatable {
    var version = 1
    var name: String
    var coat: String
    var born: Date
    var last: Date
    var needs = Needs()
    var poop = 0
    var awakeMinutes: Double = 0
    var hearts = 0
    var seenHearts = 0
    var wear = Wear(head: "bow")
    var lightsOff = false
    var sound = true
    var treats: [Date] = []
    var stage = 0
    var bonusDay: String
    /// `Room` raw value; nil is the living room. Optional, so saves from before the garden load.
    var room: String?
    /// How many birthdays have been celebrated (#17). Optional, so older saves load; nil is none.
    var birthdays: Int?
    /// Whether the cat has had its grown-up party (#17). Optional, so older saves load; a cat that
    /// had already grown up in one gets its party late, once.
    var grownUpParty: Bool?
    /// The living room's decorations that are put up (#18), by `Decor` id. Optional, so older saves
    /// load; nil or empty is the room as it always was.
    var decor: [String]?
    /// A second cat that lives with the first (#21). Optional, so older saves load as one cat.
    var companion: CatRecord?
    /// Fish cookies in the kitchen's jar (#38). Optional, so older saves load; nil is none.
    var cookies: Int?

    init(name: String, coat: String, now: Date = Date()) {
        self.name = name
        self.coat = coat
        born = now
        last = now
        bonusDay = SaveState.dayKey(now)
    }

    static func dayKey(_ date: Date) -> String {
        let c = Calendar.current.dateComponents([.year, .month, .day], from: date)
        return "\(c.year ?? 0)-\(c.month ?? 0)-\(c.day ?? 0)"
    }

    /// How many birthdays a cat adopted on `born` has had by `now`: one on the adoption date each
    /// year. A cat adopted on 29 February has its birthday on 28 February in other years (#17).
    static func birthdaysPassed(born: Date, at now: Date, calendar: Calendar = .current) -> Int {
        let b = calendar.dateComponents([.year, .month, .day], from: born)
        let today = calendar.startOfDay(for: now)
        guard let by = b.year, let bm = b.month, let bd = b.day, let ny = calendar.dateComponents([.year], from: now).year,
              ny > by else { return 0 }
        var count = 0
        for year in (by + 1)...ny {
            var day = DateComponents(year: year, month: bm, day: bd)
            if bm == 2 && bd == 29, calendar.date(from: DateComponents(year: year, month: 2, day: 29))
                .map({ calendar.component(.month, from: $0) }) != 2 {
                day.day = 28 // not a leap year
            }
            if let date = calendar.date(from: day), date <= today { count += 1 }
        }
        return count
    }

    /// The cat sleeps from 20:00 to 07:00, so a morning cat is rested.
    static func isNight(_ date: Date) -> Bool {
        let h = Calendar.current.component(.hour, from: date)
        return h >= 20 || h < 7
    }

    // MARK: Two cats (#21)

    /// The cat shown, as a record of its own.
    var shown: CatRecord {
        get {
            CatRecord(name: name, coat: coat, born: born, needs: needs, wear: wear, stage: stage,
                      awakeMinutes: awakeMinutes, birthdays: birthdays, grownUpParty: grownUpParty)
        }
        set {
            name = newValue.name; coat = newValue.coat; born = newValue.born; needs = newValue.needs
            wear = newValue.wear; stage = newValue.stage; awakeMinutes = newValue.awakeMinutes
            birthdays = newValue.birthdays; grownUpParty = newValue.grownUpParty
        }
    }

    /// Shows the other cat: its fields and the shown cat's change places.
    mutating func swapCats() {
        guard let other = companion else { return }
        companion = shown
        shown = other
    }

    /// Two cats keep each other busy and groom each other, so fun and clean fall at two thirds of
    /// the speed, and each visits the litter box every six awake hours instead of four.
    static let companyFactor = 2.0 / 3
    var litterMinutes: Double { companion == nil ? 240 : 360 }

    // MARK: Time passing

    /// One cat's needs over `seconds`. `restPerHour` is the energy sleep gives back.
    private static func tick(_ n: inout Needs, poop: Int, seconds: Double, sleeping: Bool, restPerHour: Double,
                             company: Bool) {
        let h = seconds / 3600, c = company ? companyFactor : 1
        if sleeping {
            n.food -= 2 * h; n.fun -= 1 * h * c; n.clean -= 1 * h * c; n.energy += restPerHour * h
        } else {
            n.food -= 6 * h; n.fun -= 6 * h * c; n.energy -= 5 * h
            n.clean -= (3.5 + 3 * Double(poop)) * h * c
        }
        n.clamp()
    }

    /// While the game is open. Sleeping in the basket restores energy quickly.
    mutating func liveTick(seconds: Double, sleeping: Bool, companionSleeping: Bool = false) {
        let two = companion != nil
        SaveState.tick(&needs, poop: poop, seconds: seconds, sleeping: sleeping, restPerHour: 1800, company: two)
        if two {
            SaveState.tick(&companion!.needs, poop: poop, seconds: seconds, sleeping: companionSleeping,
                           restPerHour: 1800, company: true)
        }
    }

    /// While the game is closed. Every 4 awake hours (6 with two cats) a cat visits the litter box.
    mutating func offlineTick(seconds: Double, sleeping: Bool) {
        let two = companion != nil
        SaveState.tick(&needs, poop: poop, seconds: seconds, sleeping: sleeping, restPerHour: 25, company: two)
        let every = litterMinutes
        if !sleeping { SaveState.visitLitter(&awakeMinutes, &poop, seconds: seconds, every: every) }
        if two {
            SaveState.tick(&companion!.needs, poop: poop, seconds: seconds, sleeping: sleeping, restPerHour: 25, company: true)
            if !sleeping { SaveState.visitLitter(&companion!.awakeMinutes, &poop, seconds: seconds, every: every) }
        }
    }

    private static func visitLitter(_ minutes: inout Double, _ poop: inout Int, seconds: Double, every: Double) {
        minutes += seconds / 60
        if minutes >= every {
            minutes -= every
            if poop < 3 { poop += 1 }
        }
    }

    /// Applies the time since `last` in 10-minute steps (at most 3 days) and returns how long
    /// the player was away.
    @discardableResult
    mutating func catchUp(to now: Date = Date()) -> TimeInterval {
        let from = min(last, now)
        let away = now.timeIntervalSince(from)
        var left = min(away, 3 * 86_400)
        var cursor = now.addingTimeInterval(-left)
        while left > 0 {
            let chunk = min(600, left)
            offlineTick(seconds: chunk, sleeping: lightsOff || SaveState.isNight(cursor))
            cursor = cursor.addingTimeInterval(chunk)
            left -= chunk
        }
        last = now
        return away
    }
}

/// Saves the cat in UserDefaults (on this device only).
enum SaveStore {
    static let key = "whiskerling.save.v1"

    static func load(from defaults: UserDefaults = .standard) -> SaveState? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(SaveState.self, from: data)
    }

    static func save(_ state: SaveState?, to defaults: UserDefaults = .standard) {
        guard let state else { defaults.removeObject(forKey: key); return }
        if let data = try? JSONEncoder().encode(state) { defaults.set(data, forKey: key) }
    }
}
