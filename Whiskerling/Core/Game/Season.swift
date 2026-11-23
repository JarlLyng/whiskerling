import SwiftUI

/// The time of year, from the iPad's date only: no weather and no network (#16). Regions south
/// of the equator get it the other way round, worked out offline from the device's region.
enum Season: String, CaseIterable {
    case winter, spring, summer, autumn

    /// Regions that lie mostly south of the equator, where December is summer.
    static let southernRegions: Set<String> = [
        "AR", "AU", "BO", "BR", "BW", "CL", "FJ", "LS", "MG", "MU", "MZ", "NA", "NC", "NZ", "PE", "PG",
        "PY", "SZ", "UY", "ZA", "ZW",
    ]

    static func at(_ date: Date, region: String? = Locale.current.region?.identifier,
                   calendar: Calendar = .current) -> Season {
        #if DEBUG
        // For checking and screenshots: launch with `-debugSeason winter` (or spring, summer, autumn).
        if let forced = UserDefaults.standard.string(forKey: "debugSeason").flatMap(Season.init) { return forced }
        #endif
        let north: Season = switch calendar.component(.month, from: date) {
        case 12, 1, 2: .winter
        case 3...5: .spring
        case 6...8: .summer
        default: .autumn
        }
        guard let region, southernRegions.contains(region) else { return north }
        return switch north {
        case .winter: .summer
        case .spring: .autumn
        case .summer: .winter
        case .autumn: .spring
        }
    }

    /// The lawn and the hills: snowy in winter, golden in autumn, as they are the rest of the year.
    func ground(_ color: Color, night: Bool) -> Color {
        switch self {
        case .winter: color.mixed(with: night ? Color(hex: "C4D0E6") : Color(hex: "F4F8FC"), night ? 0.75 : 0.78)
        case .autumn: color.mixed(with: Color(hex: "D9A441"), night ? 0.15 : 0.3)
        case .spring, .summer: color
        }
    }

    /// Leaves on the tree and the bushes: orange in autumn.
    func leaves(_ color: Color) -> Color {
        self == .autumn ? color.mixed(with: Color(hex: "E07B39"), 0.8) : color
    }
}

extension Color {
    /// This colour `t` of the way towards `other`.
    func mixed(with other: Color, _ t: Double) -> Color {
        let env = EnvironmentValues()
        let a = resolve(in: env), b = other.resolve(in: env)
        let t = Float(min(max(t, 0), 1))
        return Color(red: Double(a.red + (b.red - a.red) * t), green: Double(a.green + (b.green - a.green) * t),
                     blue: Double(a.blue + (b.blue - a.blue) * t))
    }
}
