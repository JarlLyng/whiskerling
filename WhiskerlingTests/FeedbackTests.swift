import XCTest
@testable import Whiskerling

final class FeedbackTests: XCTestCase {
    func testTheMailGoesToSupportWithTheVersionsFilledIn() throws {
        let url = Feedback.mailURL(marketingVersion: "1.0", appVersion: "1.0 (7)", systemVersion: "27.1")
        let parts = try XCTUnwrap(URLComponents(url: url, resolvingAgainstBaseURL: false))
        XCTAssertEqual(parts.scheme, "mailto")
        XCTAssertEqual(parts.path, "support@iamjarl.com")
        let query = Dictionary(uniqueKeysWithValues: (parts.queryItems ?? []).map { ($0.name, $0.value ?? "") })
        XCTAssertEqual(query["subject"], "Whiskerling 1.0 feedback")
        XCTAssertTrue(query["body"]?.contains("Whiskerling 1.0 (7)") == true)
        XCTAssertTrue(query["body"]?.contains("iPadOS 27.1") == true)
    }

    func testRateOpensWhiskerlingsReviewPage() throws {
        let parts = try XCTUnwrap(URLComponents(url: Feedback.reviewURL, resolvingAgainstBaseURL: false))
        XCTAssertEqual(parts.scheme, "https")
        XCTAssertEqual(parts.host, "apps.apple.com")
        XCTAssertEqual(parts.path, "/app/id6835849162")
        XCTAssertEqual(parts.queryItems, [URLQueryItem(name: "action", value: "write-review")])
    }
}
