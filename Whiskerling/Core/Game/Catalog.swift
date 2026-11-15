import SwiftUI

enum CoatPattern { case stripes, calico }

struct Coat: Identifiable {
    let id: String
    let fur: Color, dark: Color, light: Color, inner: Color, eye: Color, line: Color, nose: Color, whisker: Color
    var pattern: CoatPattern? = nil
    var p1: Color = .clear
    var p2: Color = .clear
    /// Free coats can be chosen without Pro.
    var isFree: Bool = false

    var name: String { L10n.coatName(id) }
}

struct Stage {
    let index: Int
    let size: CGFloat
    let body: CGFloat
    let head: CGFloat
    let pitch: Float

    var name: String { L10n.stageName(index) }
}

enum ItemSlot: String, Codable { case head, face, neck }

struct Item: Identifiable {
    let id: String
    let slot: ItemSlot
    let icon: String
    /// Hearts collected in total before it unlocks. Hearts are never spent.
    let cost: Int
    var isFree: Bool = false

    var name: String { L10n.itemName(id) }
}

enum Food: String, CaseIterable, Identifiable {
    case kibble, fish, shrimp
    var id: String { rawValue }
    var food: Double { switch self { case .kibble: 25; case .fish: 40; case .shrimp: 8 } }
    var fun: Double { switch self { case .kibble: 0; case .fish: 5; case .shrimp: 15 } }
    var isTreat: Bool { self == .shrimp }
    var icon: String { switch self { case .kibble: "🥣"; case .fish: "🐟"; case .shrimp: "🦐" } }
}

enum Catalog {
    static let coats: [Coat] = [
        Coat(id: "orange", fur: Color(hex: "F6A35B"), dark: Color(hex: "E07F2C"), light: Color(hex: "FFE9CF"),
             inner: Color(hex: "F8B4B0"), eye: Color(hex: "73C24A"), line: Color(hex: "7A4317"), nose: Color(hex: "F28B9B"),
             whisker: .rgba(90, 50, 30, 0.5), pattern: .stripes, isFree: true),
        Coat(id: "gray", fur: Color(hex: "A3AEBB"), dark: Color(hex: "748291"), light: Color(hex: "E8EDF2"),
             inner: Color(hex: "F2B6C1"), eye: Color(hex: "EDB93C"), line: Color(hex: "46505B"), nose: Color(hex: "EE8C9E"),
             whisker: .rgba(50, 55, 65, 0.5), isFree: true),
        Coat(id: "black", fur: Color(hex: "3C3B47"), dark: Color(hex: "24232B"), light: Color(hex: "5E5D6C"),
             inner: Color(hex: "C98394"), eye: Color(hex: "F4C430"), line: Color(hex: "141318"), nose: Color(hex: "C9707F"),
             whisker: .rgba(255, 255, 255, 0.55)),
        Coat(id: "white", fur: Color(hex: "FCFBF7"), dark: Color(hex: "E2DED3"), light: Color(hex: "FFFFFF"),
             inner: Color(hex: "F8B9C6"), eye: Color(hex: "52A8E8"), line: Color(hex: "8F897E"), nose: Color(hex: "F49AAA"),
             whisker: .rgba(120, 110, 100, 0.5)),
        Coat(id: "tabby", fur: Color(hex: "BC9168"), dark: Color(hex: "6F4C2D"), light: Color(hex: "EEDFCA"),
             inner: Color(hex: "EBAA9F"), eye: Color(hex: "7FBF5E"), line: Color(hex: "4B321D"), nose: Color(hex: "E58A8A"),
             whisker: .rgba(70, 45, 25, 0.5), pattern: .stripes),
        Coat(id: "calico", fur: Color(hex: "FCF8F1"), dark: Color(hex: "3C3B47"), light: Color(hex: "FFFFFF"),
             inner: Color(hex: "F8B9C6"), eye: Color(hex: "73C24A"), line: Color(hex: "6E5E50"), nose: Color(hex: "F49AAA"),
             whisker: .rgba(110, 94, 80, 0.5), pattern: .calico, p1: Color(hex: "EE9A4D"), p2: Color(hex: "3C3B47"))
    ]

    static func coat(_ id: String) -> Coat { coats.first { $0.id == id } ?? coats[0] }

    /// Kitten for the first 2 days, young cat until day 6, then grown up.
    static let stages: [Stage] = [
        Stage(index: 0, size: 0.95, body: 0.8, head: 1.18, pitch: 1.35),
        Stage(index: 1, size: 1.08, body: 0.92, head: 1.07, pitch: 1.15),
        Stage(index: 2, size: 1.22, body: 1, head: 1, pitch: 1)
    ]

    static func stage(born: Date, at now: Date) -> Int {
        let days = now.timeIntervalSince(born) / 86_400
        return days < 2 ? 0 : (days < 6 ? 1 : 2)
    }

    static let items: [Item] = [
        Item(id: "bow", slot: .head, icon: "🎀", cost: 0, isFree: true),
        Item(id: "bell", slot: .neck, icon: "🔔", cost: 15, isFree: true),
        Item(id: "flowers", slot: .head, icon: "🌸", cost: 35),
        Item(id: "glasses", slot: .face, icon: "🕶️", cost: 60),
        Item(id: "hat", slot: .head, icon: "🎩", cost: 90),
        Item(id: "scarf", slot: .neck, icon: "🧣", cost: 130),
        Item(id: "crown", slot: .head, icon: "👑", cost: 180)
    ]
}
