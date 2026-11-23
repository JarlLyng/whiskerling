import Foundation

/// The "Send feedback" mail in the grown-ups' menu, behind the parental gate. Whiskerling collects
/// no usage data, so what parents choose to write is how the app learns what's wrong. Everything
/// filled in here sits in the draft to read before sending; nothing leaves the iPad unless they
/// send it. Same shape as Walkful's.
enum Feedback {
    static let address = "support@iamjarl.com"
    static let privacyURL = URL(string: "https://whiskerling.iamjarl.com/privacy/")!
    /// The App Store's write-review page for Whiskerling, which Rate opens. Apple advises a link
    /// like this for a button: `requestReview()` decides by itself whether to show anything.
    static let reviewURL = URL(string: "https://apps.apple.com/app/id6835849162?action=write-review")!

    /// The marketing version alone, as in "1.0".
    static var marketingVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
    }

    /// Version and build, as in "1.0 (1)".
    static var appVersion: String {
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?"
        return "\(marketingVersion) (\(build))"
    }

    /// "27.1", read from ProcessInfo so it needs no main actor.
    static var systemVersion: String {
        let v = ProcessInfo.processInfo.operatingSystemVersion
        return v.patchVersion > 0 ? "\(v.majorVersion).\(v.minorVersion).\(v.patchVersion)"
                                  : "\(v.majorVersion).\(v.minorVersion)"
    }

    /// `mailto:` with the subject `Whiskerling 1.0 feedback` and a body that leaves room to write
    /// above the app and iPadOS versions.
    static func mailURL(marketingVersion: String = Self.marketingVersion,
                        appVersion: String = Self.appVersion,
                        systemVersion: String = Self.systemVersion) -> URL {
        var components = URLComponents()
        components.scheme = "mailto"
        components.path = address
        components.queryItems = [
            URLQueryItem(name: "subject", value: "Whiskerling \(marketingVersion) feedback"),
            URLQueryItem(name: "body", value: "\n\n\n---\nWhiskerling \(appVersion)\niPadOS \(systemVersion)\n"),
        ]
        return components.url ?? URL(string: "mailto:\(address)")!
    }
}
