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

/// Everything about the cat that survives the app closing. Stored as JSON on the device only.
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

    /// The cat sleeps from 20:00 to 07:00, so a morning cat is rested.
    static func isNight(_ date: Date) -> Bool {
        let h = Calendar.current.component(.hour, from: date)
        return h >= 20 || h < 7
    }

    // MARK: Time passing

    /// While the game is open. Sleeping in the basket restores energy quickly.
    mutating func liveTick(seconds: Double, sleeping: Bool) {
        let h = seconds / 3600
        if sleeping {
            needs.food -= 2 * h; needs.fun -= 1 * h; needs.clean -= 1 * h; needs.energy += 0.5 * seconds
        } else {
            needs.food -= 6 * h; needs.fun -= 6 * h; needs.energy -= 5 * h
            needs.clean -= (3.5 + 3 * Double(poop)) * h
        }
        needs.clamp()
    }

    /// While the game is closed. Every 4 awake hours the cat visits the litter box.
    mutating func offlineTick(seconds: Double, sleeping: Bool) {
        let h = seconds / 3600
        if sleeping {
            needs.food -= 2 * h; needs.fun -= 1 * h; needs.clean -= 1 * h; needs.energy += 25 * h
        } else {
            needs.food -= 6 * h; needs.fun -= 6 * h; needs.energy -= 5 * h
            needs.clean -= (3.5 + 3 * Double(poop)) * h
            awakeMinutes += seconds / 60
            if awakeMinutes >= 240 {
                awakeMinutes -= 240
                if poop < 3 { poop += 1 }
            }
        }
        needs.clamp()
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
