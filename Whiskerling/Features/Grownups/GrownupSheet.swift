import StoreKit
import SwiftUI

/// Everything for grown-ups sits behind a parental gate: buying Pro and the settings.
/// Apple requires a gate before purchases in apps made for children.
struct GrownupSheet: View {
    let model: GameModel
    let route: AdultRoute
    @Environment(\.dismiss) private var dismiss
    @State private var passed = false

    var body: some View {
        Group {
            if !passed {
                ParentGateView(onPass: { passed = true }, onCancel: { dismiss() })
            } else if route == .paywall {
                PaywallView(store: model.store, onClose: { dismiss() })
            } else {
                GrownupMenu(model: model, onClose: { dismiss() })
            }
        }
        .foregroundStyle(Theme.text)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.card)
    }
}

/// A question from the small times table (6 to 9 times 6 to 9), entered on a keypad. Quick for a
/// grown-up, out of reach for the youngest players; Apple asks only for an adult-level task.
struct ParentGateView: View {
    static let factors = 6...9

    let onPass: () -> Void
    let onCancel: () -> Void
    @State private var a = ParentGateView.firstFactor(7)
    @State private var b = ParentGateView.firstFactor(8)

    /// A random factor, or a fixed one in the App Store screenshots, so the poster shows the
    /// same 7 × 8 as the site.
    private static func firstFactor(_ screenshot: Int) -> Int {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("-screenshots") { return screenshot }
        #endif
        return Int.random(in: factors)
    }
    @State private var answer = ""
    @State private var wrong = false
    /// The keys grow with their digits (#42).
    @ScaledMetric(relativeTo: .title) private var keyWidth: CGFloat = 84
    @ScaledMetric(relativeTo: .title) private var keyHeight: CGFloat = 64

    var body: some View {
        // Centred when it fits, smaller keys in a short window, and scrolling below that, so
        // OK and Cancel are always within reach (#15).
        GeometryReader { geo in
            let short = geo.size.height < 600
            let narrow = geo.size.width < 520
            // Three keys to a row always fit the window, however large the text (#42).
            let fit = (geo.size.width - 2 * (narrow ? Tokens.Spacing.md : Tokens.Spacing.xxl) - 2 * Tokens.Spacing.sm) / 3
            ScrollView {
                gate(short: short, narrow: narrow, keyWidth: min(keyWidth, fit))
                    .frame(maxWidth: .infinity, minHeight: geo.size.height)
            }
            .scrollBounceBehavior(.basedOnSize)
        }
    }

    private func gate(short: Bool, narrow: Bool, keyWidth: CGFloat) -> some View {
        VStack(spacing: short ? Tokens.Spacing.sm : Tokens.Spacing.lg) {
            Text(verbatim: L10n.forGrownUps).themeFont(short ? 22 : 28).multilineTextAlignment(.center)
            Text(verbatim: L10n.gateQuestion(a, b)).themeFont(short ? 20 : 24, .semibold).multilineTextAlignment(.center)
            Text(verbatim: answer.isEmpty ? " " : answer)
                .themeFont(short ? 30 : 40, .heavy).monospacedDigit()
                .padding(.horizontal, Tokens.Spacing.md)
                .frame(minWidth: 200, minHeight: short ? 46 : 64)
                .background(Theme.option, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            // The line is always there, so the keypad never jumps under a grown-up's finger.
            Text(verbatim: wrong ? L10n.gateWrong : " ").themeFont(16, .semibold).foregroundStyle(Color(hex: "D64545"))
            Grid(horizontalSpacing: Tokens.Spacing.sm, verticalSpacing: Tokens.Spacing.sm) {
                ForEach(0..<3) { row in
                    GridRow {
                        ForEach(1...3, id: \.self) { col in key(String(row * 3 + col), short: short, width: keyWidth) }
                    }
                }
                GridRow {
                    key("⌫", short: short, width: keyWidth)
                    key("0", short: short, width: keyWidth)
                    key(L10n.ok, short: short, width: keyWidth)
                }
            }
            Button(L10n.cancel, action: onCancel).themeFont(18).padding(.top, short ? 0 : Tokens.Spacing.sm)
        }
        .padding(short || narrow ? Tokens.Spacing.md : Tokens.Spacing.xxl)
    }

    private func key(_ label: String, short: Bool, width: CGFloat) -> some View {
        Button {
            if label != L10n.ok { wrong = false }
            switch label {
            case "⌫": if !answer.isEmpty { answer.removeLast() }
            case L10n.ok: check()
            default: if answer.count < 4 { answer += label }
            }
        } label: {
            Text(verbatim: label).themeFont(short ? 22 : 26).lineLimit(1).minimumScaleFactor(0.5)
                .frame(width: width, height: keyHeight * (short ? 46.0 / 64 : 1))
        }
        .buttonStyle(PillButtonStyle(color: label == L10n.ok ? Theme.go : Theme.feed))
    }

    private func check() {
        if Int(answer) == a * b {
            onPass()
        } else {
            wrong = true
            answer = ""
            a = Int.random(in: ParentGateView.factors)
            b = Int.random(in: ParentGateView.factors)
        }
    }
}

struct PaywallView: View {
    let store: Store
    let onClose: () -> Void
    @Environment(\.dynamicTypeSize) private var typeSize
    @ScaledMetric(relativeTo: .title) private var iconWidth: CGFloat = 36

    var body: some View {
        // Centred when it fits, scrolling when it doesn't (an iPad mini in landscape with the
        // offline note), so no line is ever cut short.
        GeometryReader { geo in
            ScrollView {
                content.frame(maxWidth: .infinity, minHeight: geo.size.height)
            }
            .scrollBounceBehavior(.basedOnSize)
        }
        .task { await store.loadProduct() }
        .alert(L10n.purchaseTitle, isPresented: Binding(get: { store.purchaseError != nil }, set: { if !$0 { store.purchaseError = nil } })) {
            Button(L10n.ok) { store.purchaseError = nil }
        } message: {
            Text(verbatim: store.purchaseError ?? "")
        }
    }

    private var content: some View {
        VStack(spacing: Tokens.Spacing.xl) {
            VStack(spacing: Tokens.Spacing.sm) {
                Text(verbatim: L10n.proTitle).themeFont(34, .heavy).multilineTextAlignment(.center)
                Text(verbatim: L10n.proSubtitle).themeFont(19, .semibold).foregroundStyle(Theme.muted).multilineTextAlignment(.center)
            }
            VStack(alignment: .leading, spacing: Tokens.Spacing.lg) {
                row("paintpalette.fill", L10n.proCoatsTitle, L10n.proCoatsBody)
                row("crown.fill", L10n.proItemsTitle, L10n.proItemsBody)
                row("leaf.fill", L10n.proGardenTitle, L10n.proGardenBody)
                row("pawprint.fill", L10n.proSecondCatTitle, L10n.proSecondCatBody)
                row("sparkles", L10n.proFutureTitle, L10n.proFutureBody)
                row("lock.shield.fill", L10n.proPrivateTitle, L10n.proPrivateBody)
            }
            .frame(maxWidth: typeSize.isAccessibilitySize ? 640 : 460, alignment: .leading)

            if store.isPro {
                Text(verbatim: L10n.proUnlocked).themeFont(20).foregroundStyle(Theme.chosen)
                Button(L10n.close, action: onClose).themeFont(20)
            } else {
                Button { Task { await store.purchase() } } label: {
                    Group {
                        if store.isPurchasing { ProgressView() } else {
                            Text(verbatim: store.proProduct.map { L10n.unlockPro($0.displayPrice) } ?? L10n.unlockProPlain)
                        }
                    }
                    .themeFont(22).multilineTextAlignment(.center)
                    .padding(.horizontal, 34).padding(.vertical, Tokens.Spacing.sm).frame(minHeight: 64)
                }
                .buttonStyle(PillButtonStyle(color: Theme.go))
                .opacity(store.proProduct == nil ? 0.6 : 1)
                if store.loadFailed && store.proProduct == nil {
                    Text(verbatim: L10n.storeOffline).themeFont(15, .semibold).foregroundStyle(Theme.muted)
                        .multilineTextAlignment(.center)
                    Button(L10n.tryAgain) { Task { await store.loadProduct() } }.themeFont(17)
                }
                // side by side when they fit, under each other with large text (#42)
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: Tokens.Spacing.xxl) { restoreAndNotNow }
                    VStack(spacing: Tokens.Spacing.md) { restoreAndNotNow }
                }
                .themeFont(17, .semibold)
            }
        }
        .padding(Tokens.Spacing.xxl)
    }

    @ViewBuilder private var restoreAndNotNow: some View {
        Button(L10n.restore) { Task { await store.restore() } }
        Button(L10n.notNow, action: onClose)
    }

    private func row(_ symbol: String, _ title: String, _ body: String) -> some View {
        HStack(alignment: .top, spacing: Tokens.Spacing.md) {
            Image(systemName: symbol).themeFont(26, .regular).foregroundStyle(Color(hex: "E76B86")).frame(width: iconWidth)
            VStack(alignment: .leading, spacing: 2) {
                Text(verbatim: title).themeFont(19)
                Text(verbatim: body).themeFont(16, .regular).foregroundStyle(Theme.muted)
            }
        }
    }
}

struct GrownupMenu: View {
    let model: GameModel
    let onClose: () -> Void
    @State private var resetArmed = false
    @State private var showPaywall = false
    @State private var shownName = ""
    @State private var otherName = ""
    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        if showPaywall {
            PaywallView(store: model.store, onClose: { showPaywall = false })
        } else {
            // Centred when it fits, tighter in a small window, and scrolling below that, so
            // Close is always within reach (#15).
            GeometryReader { geo in
                let small = geo.size.height < 640 || geo.size.width < 480
                ScrollView {
                    menu(small: small).frame(maxWidth: .infinity, minHeight: geo.size.height)
                }
                .scrollBounceBehavior(.basedOnSize)
            }
        }
    }

    private func menu(small: Bool) -> some View {
        VStack(spacing: small ? Tokens.Spacing.md : Tokens.Spacing.lg) {
            Text(verbatim: L10n.menuTitle).themeFont(small ? 24 : 28).multilineTextAlignment(.center)
            if let s = model.world.save {
                // Same day number as the top bar ("Kitten · day 1").
                let day = Int(Date().timeIntervalSince(s.born) / 86_400) + 1
                Text(verbatim: L10n.menuInfo(s.name, day, s.hearts)).themeFont(17, .semibold).foregroundStyle(Theme.muted)
                    .multilineTextAlignment(.center)
            }
            if model.store.isPro {
                // A status, not a button: the same green line as on the paywall.
                Text(verbatim: L10n.proUnlocked).themeFont(20).foregroundStyle(Theme.chosen)
                    .padding(.vertical, Tokens.Spacing.sm)
            } else {
                wide(L10n.unlockProPlain, color: Theme.dress, small: small) { showPaywall = true }
            }
            wide(L10n.restore, color: Theme.option, small: small) { Task { await model.store.restore() } }
            if model.hasCat {
                // A new name for a cat, or for both (#21)
                VStack(spacing: Tokens.Spacing.sm) {
                    Text(verbatim: L10n.renameTitle).themeFont(17).foregroundStyle(Theme.text)
                    nameField($shownName, current: model.hud.name, other: false)
                    if let other = model.hud.otherName { nameField($otherName, current: other, other: true) }
                }
                .onAppear { shownName = model.hud.name; otherName = model.hud.otherName ?? "" }
            }
            wide(model.hud.sound ? L10n.menuSoundOn : L10n.menuSoundOff, color: Theme.option, small: small) { model.toggleSoundFromMenu() }
            if model.hasCat {
                wide(resetArmed ? L10n.startOverConfirm(model.hud.otherName.map { L10n.twoNames(model.hud.name, $0) } ?? model.hud.name) : L10n.startOver, color: Color(hex: "FFD3D3"), small: small) {
                    if resetArmed { model.startOver(); onClose() } else { resetArmed = true }
                }
            }
            // Links out of the app live here, behind the parental gate, as Apple's Kids
            // category asks. Rate is a link to the App Store's review page, never a prompt.
            VStack(spacing: Tokens.Spacing.xs) {
                // Side by side when they fit, under each other in a narrow window.
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: Tokens.Spacing.xl) { links }
                    VStack(spacing: Tokens.Spacing.sm) { links }
                }
                .themeFont(16, .semibold)
                Text(verbatim: L10n.feedbackNote).themeFont(13, .regular).foregroundStyle(Theme.muted)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, Tokens.Spacing.sm)
            Text(verbatim: "Whiskerling \(Feedback.appVersion)").themeFont(13, .regular).foregroundStyle(Theme.muted)
            Button(L10n.close, action: onClose).themeFont(18)
        }
        .padding(small ? Tokens.Spacing.lg : Tokens.Spacing.xxl)
        .frame(maxWidth: typeSize.isAccessibilitySize ? 680 : 520)
    }

    /// Each link with a hit area of at least 44 by 44 points (#43).
    @ViewBuilder private var links: some View {
        link(L10n.sendFeedback, Feedback.mailURL())
        link(L10n.rateApp, Feedback.reviewURL)
        link(L10n.privacyPolicy, Feedback.privacyURL)
    }

    private func link(_ title: String, _ url: URL) -> some View {
        Link(destination: url) {
            Text(verbatim: title).underline()
                .padding(.horizontal, Tokens.Spacing.sm)
                .frame(minWidth: 44, minHeight: 44)
                .contentShape(Rectangle())
        }
    }

    private func nameField(_ text: Binding<String>, current: String, other: Bool) -> some View {
        let tidy = text.wrappedValue.split(whereSeparator: \.isWhitespace).joined(separator: " ")
        let changed = !tidy.isEmpty && tidy != current
        // the field and Save under each other with large text (#42)
        let layout = typeSize.isAccessibilitySize ? AnyLayout(VStackLayout(spacing: Tokens.Spacing.sm))
                                                  : AnyLayout(HStackLayout(spacing: Tokens.Spacing.sm))
        return layout {
            TextField(L10n.namePlaceholder, text: text)
                .themeFont(20)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()
                .submitLabel(.done)
                .onSubmit { if changed { model.rename(text.wrappedValue, other: other) } }
                .onChange(of: text.wrappedValue) { _, new in if new.count > 14 { text.wrappedValue = String(new.prefix(14)) } }
                .padding(.horizontal, Tokens.Spacing.md).padding(.vertical, Tokens.Spacing.xs).frame(minHeight: 52)
                .background(Color.white, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(Theme.barLine, lineWidth: 2))
                .foregroundStyle(Theme.onPastel)
                .accessibilityLabel(L10n.renameField(current))
            Button(L10n.save) { model.rename(text.wrappedValue, other: other) }
                .themeFont(18)
                .frame(minWidth: 44, minHeight: 44)
                .disabled(!changed)
        }
        .frame(maxWidth: typeSize.isAccessibilitySize ? 600 : 420)
    }

    private func wide(_ title: String, color: Color, small: Bool, _ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(verbatim: title).themeFont(19).multilineTextAlignment(.center)
                .padding(small ? Tokens.Spacing.md : Tokens.Spacing.lg).frame(maxWidth: .infinity)
        }
        .buttonStyle(PillButtonStyle(color: color))
    }
}
