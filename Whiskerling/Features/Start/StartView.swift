import SwiftUI

/// Choose a kitten and give it a name.
struct StartView: View {
    let model: GameModel
    @State private var coat = "orange"
    @State private var name = ""
    @FocusState private var nameFocused: Bool

    var body: some View {
        GeometryReader { geo in
            ScrollView {
                card
                    .padding(Tokens.Spacing.xl)
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

    private var card: some View {
            VStack(spacing: Tokens.Spacing.lg) {
                Text(verbatim: "Whiskerling 🐾").font(Theme.font(44, .heavy))
                Text(verbatim: L10n.chooseKitten).font(Theme.font(20, .semibold)).foregroundStyle(Theme.muted)
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: Tokens.Spacing.md), count: 3),
                          spacing: Tokens.Spacing.md) {
                    ForEach(Catalog.coats) { c in coatButton(c) }
                }
                Text(verbatim: L10n.nameQuestion).font(Theme.font(20, .semibold)).foregroundStyle(Theme.muted)
                TextField(L10n.namePlaceholder, text: $name)
                    .font(Theme.font(28))
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
                    Text(verbatim: L10n.bringHome).font(Theme.font(24)).padding(.horizontal, 36).frame(height: 68)
                }
                .buttonStyle(PillButtonStyle(color: Theme.go))
            }
            .padding(Tokens.Spacing.xxl)
            .frame(maxWidth: 680)
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
                KittenPortrait(coat: c).frame(width: 110, height: 110)
                Text(verbatim: c.name).font(Theme.font(17))
                Text(verbatim: locked ? "🔒 " + L10n.askGrownUp : " ").font(Theme.font(13, .semibold)).foregroundStyle(Theme.muted)
            }
            .padding(.vertical, Tokens.Spacing.sm)
            .frame(maxWidth: .infinity)
            .background(chosen ? Color(hex: "D2F2CF") : Theme.option, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay {
                if chosen { RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(Theme.chosen, lineWidth: 4) }
            }
            .foregroundStyle(chosen ? Theme.onPastel : Theme.text)
            .opacity(locked ? 0.6 : 1)
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
        model.startNewCat(name: final, coat: chosen.isFree || model.isPro ? chosen.id : "orange")
    }
}
