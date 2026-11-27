import SwiftUI

/// Choose a kitten and give it a name.
struct StartView: View {
    let model: GameModel
    @State private var coat = "orange"
    @State private var name = ""
    @FocusState private var nameFocused: Bool
    @Environment(\.colorSchemeContrast) private var contrast
    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        GeometryReader { geo in
            let narrow = geo.size.width < 520 // a narrow window (#15)
            // A short, wide screen (an iPad mini on its side) gets the coats in two rows, so the
            // name and the button still fit without scrolling (#19).
            // With large text the coats stay in wide tiles, two to a row (#42).
            let low = !narrow && !typeSize.isAccessibilitySize && geo.size.height < 900 && geo.size.width > geo.size.height
            ScrollView {
                card(narrow: narrow, low: low)
                    .padding(narrow ? Tokens.Spacing.md : Tokens.Spacing.xl)
                    // Centre the card on a tall screen; it still scrolls when the keyboard is up.
                    .frame(maxWidth: .infinity, minHeight: geo.size.height)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .foregroundStyle(Theme.text)
        .background(Theme.screen.ignoresSafeArea())
        // A Pro coat tapped before buying Pro is chosen once the purchase goes through.
        .onChange(of: model.startCoat) { _, picked in
            guard let picked else { return }
            coat = picked
            model.startCoat = nil
        }
    }

    private func card(narrow: Bool, low: Bool) -> some View {
            VStack(spacing: low ? Tokens.Spacing.md : Tokens.Spacing.lg) {
                Text(verbatim: "Whiskerling 🐾").themeFont(44, .heavy)
                    .lineLimit(1).minimumScaleFactor(0.5)
                // A second kitten (#21): a friend for the cat there is
                Text(verbatim: model.adopting ? L10n.adoptTitle(model.hud.name) : L10n.chooseKitten)
                    .themeFont(20, .semibold).foregroundStyle(Theme.muted).multilineTextAlignment(.center)
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: Tokens.Spacing.md),
                                         count: typeSize.isAccessibilitySize ? 2 : (low ? 5 : 3)),
                          spacing: Tokens.Spacing.md) {
                    ForEach(Catalog.coats) { c in coatButton(c) }
                }
                Text(verbatim: L10n.nameQuestion).themeFont(20, .semibold).foregroundStyle(Theme.muted)
                TextField(L10n.namePlaceholder, text: $name)
                    .themeFont(28)
                    .multilineTextAlignment(.center)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled()
                    .submitLabel(.done)
                    .focused($nameFocused)
                    .padding(.vertical, Tokens.Spacing.md)
                    .frame(maxWidth: 380)
                    .background(Color.white, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(Theme.barLine, lineWidth: 3))
                    .foregroundStyle(Theme.onPastel)
                    .onChange(of: name) { _, new in if new.count > 14 { name = String(new.prefix(14)) } }
                Button(action: start) {
                    Text(verbatim: L10n.bringHome).themeFont(24).multilineTextAlignment(.center)
                        .padding(.horizontal, 36).padding(.vertical, Tokens.Spacing.sm).frame(minHeight: 68)
                }
                .buttonStyle(PillButtonStyle(color: Theme.go))
                if model.adopting {
                    Button(L10n.adoptCancel, action: model.cancelAdopt)
                        .themeFont(18)
                        .foregroundStyle(Theme.muted)
                }
            }
            .padding(narrow || low ? Tokens.Spacing.lg : Tokens.Spacing.xxl)
            .frame(maxWidth: low ? 860 : 680)
            .background(Theme.card, in: RoundedRectangle(cornerRadius: 32, style: .continuous))
    }

    private func coatButton(_ c: Coat) -> some View {
        let locked = !c.isFree && !model.isPro
        let chosen = coat == c.id
        return Button {
            model.sound.click()
            if locked { model.askForPro(.startCoat(c.id)) } else { coat = c.id }
        } label: {
            VStack(spacing: 2) {
                // As large as the tile allows, up to 110 points, so tiles never overlap. Square first,
                // then capped: capped first, a wide tile gave a narrow, tall canvas that cut the cat off.
                KittenPortrait(coat: c).aspectRatio(1, contentMode: .fit).frame(maxWidth: 110)
                    .opacity(locked ? 0.5 : 1) // the picture fades, the words keep their contrast (#43)
                Text(verbatim: c.name).themeFont(17).lineLimit(2).minimumScaleFactor(0.7).multilineTextAlignment(.center)
                Text(verbatim: locked ? "🔒 " + L10n.askGrownUp : " ").themeFont(13, .semibold).foregroundStyle(Theme.muted)
                    .lineLimit(2).minimumScaleFactor(0.6).multilineTextAlignment(.center)
            }
            .padding(.vertical, Tokens.Spacing.sm)
            .frame(maxWidth: .infinity)
            .background(chosen ? Color(hex: "D2F2CF") : Theme.option, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay {
                if chosen {
                    RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(Theme.chosen, lineWidth: 4)
                } else if contrast == .increased {
                    RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(Theme.barLine, lineWidth: 2)
                }
            }
            .foregroundStyle(chosen ? Theme.onPastel : Theme.text)
                    }
        .buttonStyle(.plain)
        .accessibilityLabel(c.name)
        .accessibilityAddTraits(chosen ? .isSelected : [])
    }

    private func start() {
        nameFocused = false
        let trimmed = name.split(whereSeparator: \.isWhitespace).joined(separator: " ")
        let final = trimmed.isEmpty ? L10n.namePlaceholder : String(trimmed.prefix(14))
        let chosen = Catalog.coat(coat)
        let id = chosen.isFree || model.isPro ? chosen.id : "orange"
        if model.adopting { model.adopt(name: final, coat: id) } else { model.startNewCat(name: final, coat: id) }
    }
}
