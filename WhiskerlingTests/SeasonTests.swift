import SwiftUI
import XCTest
@testable import Whiskerling

/// The season comes from the date alone, the other way round south of the equator (#16).
final class SeasonTests: XCTestCase {
    private let calendar: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "UTC")!
        return c
    }()

    private func season(month: Int, region: String?) -> Season {
        let date = calendar.date(from: DateComponents(year: 2027, month: month, day: 15, hour: 12))!
        return Season.at(date, region: region, calendar: calendar)
    }

    func testTheNorthernYear() {
        let expected: [Int: Season] = [12: .winter, 1: .winter, 2: .winter, 3: .spring, 4: .spring, 5: .spring,
                                       6: .summer, 7: .summer, 8: .summer, 9: .autumn, 10: .autumn, 11: .autumn]
        for (month, s) in expected {
            XCTAssertEqual(season(month: month, region: "DK"), s, "month \(month) in Denmark")
            XCTAssertEqual(season(month: month, region: "US"), s, "month \(month) in the US")
            XCTAssertEqual(season(month: month, region: nil), s, "month \(month) with no region")
        }
    }

    func testTheSouthernYearIsTheOtherWayRound() {
        XCTAssertEqual(season(month: 1, region: "AU"), .summer)
        XCTAssertEqual(season(month: 4, region: "NZ"), .autumn)
        XCTAssertEqual(season(month: 7, region: "ZA"), .winter)
        XCTAssertEqual(season(month: 10, region: "AR"), .spring)
        XCTAssertEqual(season(month: 12, region: "CL"), .summer)
    }

    func testWinterGroundIsLighterAndSummerIsUnchanged() {
        let grass = Color(hex: "7DC461")
        let env = EnvironmentValues()
        let snowy = Season.winter.ground(grass, night: false).resolve(in: env)
        let base = grass.resolve(in: env)
        XCTAssertGreaterThan(snowy.red + snowy.green + snowy.blue, base.red + base.green + base.blue)
        let summer = Season.summer.ground(grass, night: false).resolve(in: env)
        XCTAssertEqual(summer.red, base.red, accuracy: 0.001)
        XCTAssertEqual(summer.green, base.green, accuracy: 0.001)
    }
}
