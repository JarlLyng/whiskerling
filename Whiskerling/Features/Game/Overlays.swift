import SwiftUI

/// Choose what the cat eats.
struct FoodOverlay: View {
    let model: GameModel

    var body: some View {
        // wider with the fourth choice, fish cookies (#38), so no name breaks in the middle
        ChoiceCard(title: L10n.foodTitle(model.hud.name), maxWidth: model.hud.cookies > 0 ? 800 : 600,
                   onClose: { model.overlay = nil }) { fit in
            // fish cookies only while the kitchen's jar has some (#38)
            ForEach(Food.allCases.filter { $0 != .cookie || model.hud.cookies > 0 }) { food in
                Button { model.feed(food) } label: {
                    ChoiceLabel(icon: food.icon, title: L10n.foodName(food),
                                note: food == .cookie ? L10n.cookieNote(model.hud.cookies) : L10n.foodNote(food), fit: fit, tall: 150)
                }
                .buttonStyle(PillButtonStyle(color: Theme.feed))
            }
        }
    }
}

/// Go to another room (#38): the living room, and with Pro the kitchen and the garden.
struct RoomsOverlay: View {
    let model: GameModel

    var body: some View {
        ChoiceCard(title: L10n.roomsTitle(model.hud.name), maxWidth: 720, onClose: { model.overlay = nil }) { fit in
            room(.living, "🛋️", L10n.livingRoom, L10n.livingRoomNote, fit: fit)
            room(.kitchen, "🍪", L10n.kitchen, L10n.kitchenNote, fit: fit)
            room(.garden, "🌳", L10n.gardenRoom, L10n.gardenNote, fit: fit)
        }
    }

    private func room(_ r: Room, _ icon: String, _ title: String, _ note: String, fit: ChoiceFit) -> some View {
        let locked = r != .living && !model.isPro, here = model.hud.room == r
        return Button { model.go(to: r) } label: {
            ChoiceLabel(icon: icon, title: title, note: here ? L10n.youAreHere : (locked ? "🔒 " + L10n.askGrownUp : note),
                        fit: fit, tall: 170, iconSize: 54, titleSize: 19)
        }
        .buttonStyle(PillButtonStyle(color: locked ? Theme.option : Theme.garden))
        .opacity(locked ? 0.75 : (here ? 0.6 : 1))
        .disabled(here)
        .accessibilityLabel(Text(verbatim: locked ? "\(title), \(L10n.pro)" : title))
    }
}

/// Choose a game: the feather is free, Catch the fish comes with Pro.
struct GamesOverlay: View {
    let model: GameModel

    var body: some View {
        ChoiceCard(title: L10n.gamesTitle(model.hud.name), maxWidth: 720, onClose: { model.overlay = nil }) { fit in
            game("🪶", L10n.featherGame, L10n.featherGameNote, locked: false, fit: fit, action: model.playFeather)
            game("🐟", L10n.fishGame, model.isPro ? L10n.fishGameNote : "🔒 " + L10n.askGrownUp,
                 locked: !model.isPro, fit: fit, action: model.playFish)
            game("🙈", L10n.hideGame, model.isPro ? L10n.hideGameNote : "🔒 " + L10n.askGrownUp,
                 locked: !model.isPro, fit: fit, action: model.playHide)
        }
    }

    private func game(_ icon: String, _ title: String, _ note: String, locked: Bool, fit: ChoiceFit,
                      action: @escaping () -> Void) -> some View {
        Button(action: action) {
            ChoiceLabel(icon: icon, title: title, note: note, fit: fit, tall: 170, iconSize: 54, titleSize: 19)
        }
        .buttonStyle(PillButtonStyle(color: locked ? Theme.option : Theme.play))
        .opacity(locked ? 0.75 : 1)
        .accessibilityLabel(Text(verbatim: locked ? "\(title), \(L10n.pro)" : title))
    }
}

/// How the choices on a card fit the room: side by side and tall, side by side but low (a short
/// window), or as rows under each other (a narrow window), #15.
enum ChoiceFit {
    case wide, short, rows

    static func `for`(_ size: CGSize) -> ChoiceFit {
        if size.width < 520 { return .rows }
        return size.height < 470 ? .short : .wide
    }
}

/// The card the food and game choices sit on, centred in the room over a dimmed backdrop. It
/// scrolls when the room is shorter than the card, so it never covers the bars around the room.
struct ChoiceCard<Choices: View>: View {
    let title: String
    let maxWidth: CGFloat
    let onClose: () -> Void
    @ViewBuilder let choices: (ChoiceFit) -> Choices

    var body: some View {
        GeometryReader { geo in
            let fit = ChoiceFit.for(geo.size)
            let roomy = fit == .wide
            ZStack {
                Color.black.opacity(0.35).ignoresSafeArea()
                ScrollView {
                    VStack(spacing: roomy ? Tokens.Spacing.lg : Tokens.Spacing.md) {
                        Text(verbatim: title).font(Theme.font(roomy ? 26 : 22))
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                        let layout = fit == .rows ? AnyLayout(VStackLayout(spacing: Tokens.Spacing.sm))
                                                  : AnyLayout(HStackLayout(spacing: Tokens.Spacing.md))
                        layout { choices(fit) }
                        Button(L10n.close, action: onClose)
                            .font(Theme.font(20))
                            .padding(.horizontal, 34).frame(height: roomy ? 56 : 48)
                            .background(Theme.option, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                    }
                    .foregroundStyle(Theme.text)
                    .padding(roomy ? Tokens.Spacing.xl : Tokens.Spacing.lg)
                    .frame(maxWidth: maxWidth)
                    .background(Theme.card, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
                    .contentShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                    .onTapGesture {} // a tap on the card itself doesn't close it
                    .padding(roomy ? Tokens.Spacing.xl : Tokens.Spacing.md)
                    .frame(maxWidth: .infinity, minHeight: geo.size.height)
                    .contentShape(Rectangle())
                    .onTapGesture(perform: onClose) // a tap beside the card does
                }
                .scrollBounceBehavior(.basedOnSize)
            }
        }
        .transition(.opacity)
    }
}

/// One choice: an icon over its name and a note, or beside them in a row.
struct ChoiceLabel: View {
    let icon: String
    let title: String
    let note: String
    let fit: ChoiceFit
    /// The height, icon and title size when there is room for them.
    let tall: CGFloat
    var iconSize: CGFloat = 46
    var titleSize: CGFloat = 17

    var body: some View {
        if fit == .rows {
            HStack(spacing: Tokens.Spacing.md) {
                Text(verbatim: icon).font(.system(size: 36))
                VStack(alignment: .leading, spacing: 2) {
                    Text(verbatim: title).font(Theme.font(18))
                    Text(verbatim: note).font(Theme.font(14, .semibold)).opacity(0.75)
                }
                Spacer(minLength: 0)
            }
            .padding(.vertical, Tokens.Spacing.sm).padding(.horizontal, Tokens.Spacing.md)
            .frame(maxWidth: .infinity, minHeight: 64)
        } else {
            VStack(spacing: 4) {
                Text(verbatim: icon).font(.system(size: fit == .wide ? iconSize : 36))
                Text(verbatim: title).font(Theme.font(titleSize))
                Text(verbatim: note).font(Theme.font(14, .semibold)).opacity(0.75)
                    .multilineTextAlignment(.center)
            }
            .padding(.vertical, Tokens.Spacing.md).padding(.horizontal, Tokens.Spacing.sm)
            .frame(maxWidth: .infinity, minHeight: fit == .wide ? tall : 0)
        }
    }
}

/// Dress up: accessories, coats and things for the room. Sits at the side (or top) so the cat
/// and the room stay in view.
struct WardrobeOverlay: View {
    let model: GameModel

    var body: some View {
        GeometryReader { geo in
            let landscape = geo.size.width > geo.size.height
            ZStack(alignment: landscape ? .leading : .top) {
                Color.black.opacity(0.12).ignoresSafeArea()
                    .onTapGesture { model.overlay = nil }
                panel(columns: landscape || geo.size.width < 520 ? 3 : 4)
                    .frame(width: landscape ? min(400, geo.size.width * 0.46) : nil)
                    .frame(maxHeight: landscape ? .infinity : geo.size.height * 0.62)
                    .padding(Tokens.Spacing.md)
            }
        }
        .transition(.opacity)
    }

    private func panel(columns: Int) -> some View {
        let grid = Array(repeating: GridItem(.flexible(), spacing: Tokens.Spacing.md), count: columns)
        let save = model.world.save
        return ScrollView {
            VStack(alignment: .leading, spacing: Tokens.Spacing.md) {
                Text(verbatim: L10n.wardrobeTitle).font(Theme.font(26)).frame(maxWidth: .infinity)
                Text(verbatim: L10n.wardrobeInfo(model.hud.hearts, model.hud.name))
                    .font(Theme.font(16, .semibold)).foregroundStyle(Theme.muted).frame(maxWidth: .infinity)
                    .multilineTextAlignment(.center)

                Text(verbatim: L10n.wardrobeItems).font(Theme.font(19))
                LazyVGrid(columns: grid, spacing: Tokens.Spacing.md) {
                    ForEach(Catalog.items) { item in
                        let locked = !item.isFree && !model.isPro
                        let worn = save?.wear[item.slot] == item.id
                        let earned = model.hud.hearts >= item.cost
                        Button { model.choose(item: item) } label: {
                            tile(icon: Text(verbatim: item.icon).font(.system(size: 40)), title: item.name,
                                 note: locked ? L10n.pro : (!earned ? "🔒 \(item.cost) ❤️" : (worn ? L10n.takeOff : L10n.wear)),
                                 chosen: worn, dim: locked || !earned)
                        }
                        .buttonStyle(.plain)
                    }
                }

                Text(verbatim: L10n.wardrobeCoats).font(Theme.font(19)).padding(.top, Tokens.Spacing.sm)
                LazyVGrid(columns: grid, spacing: Tokens.Spacing.md) {
                    ForEach(Catalog.coats) { coat in
                        let locked = !coat.isFree && !model.isPro
                        let chosen = save?.coat == coat.id
                        Button { model.choose(coat: coat) } label: {
                            tile(icon: KittenPortrait(coat: coat, wear: save?.wear ?? Wear()).frame(width: 64, height: 64),
                                 title: coat.name, note: locked ? L10n.pro : (chosen ? L10n.wearing : ""),
                                 chosen: chosen, dim: locked)
                        }
                        .buttonStyle(.plain)
                    }
                }

                // Things for the living room (#18), after the crown, with hearts the same way.
                Text(verbatim: L10n.wardrobeRoom).font(Theme.font(19)).padding(.top, Tokens.Spacing.sm)
                LazyVGrid(columns: grid, spacing: Tokens.Spacing.md) {
                    ForEach(Catalog.decor) { decor in
                        let locked = !decor.isFree && !model.isPro
                        let shown = save?.decor?.contains(decor.id) == true
                        let earned = model.hud.hearts >= decor.cost
                        Button { model.choose(decor: decor) } label: {
                            tile(icon: DecorIcon(id: decor.id, pose: model.world.portraitPose).frame(width: 64, height: 54),
                                 title: decor.name,
                                 note: locked ? L10n.pro : (!earned ? "🔒 \(decor.cost) ❤️" : (shown ? L10n.takeDown : L10n.putUp)),
                                 chosen: shown, dim: locked || !earned)
                        }
                        .buttonStyle(.plain)
                    }
                }

                Button(L10n.done) { model.overlay = nil }
                    .font(Theme.font(20))
                    .padding(.horizontal, 34).frame(height: 56)
                    .background(Theme.option, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .frame(maxWidth: .infinity)
                    .padding(.top, Tokens.Spacing.sm)
            }
            .padding(Tokens.Spacing.lg)
        }
        .foregroundStyle(Theme.text)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private func tile<Icon: View>(icon: Icon, title: String, note: String, chosen: Bool, dim: Bool) -> some View {
        VStack(spacing: 2) {
            icon
            Text(verbatim: title).font(Theme.font(15)).lineLimit(1).minimumScaleFactor(0.7)
            Text(verbatim: note).font(Theme.font(13, .semibold)).foregroundStyle(Theme.muted).lineLimit(1)
        }
        .padding(.vertical, Tokens.Spacing.sm).padding(.horizontal, 4)
        .frame(maxWidth: .infinity)
        .background(chosen ? Color(hex: "D2F2CF") : Theme.option, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            if chosen { RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(Theme.chosen, lineWidth: 4) }
        }
        .foregroundStyle(chosen ? Theme.onPastel : Theme.text)
        .opacity(dim ? 0.55 : 1)
    }
}

/// A small drawing of a kitten in a given coat, for pickers.
struct KittenPortrait: View {
    let coat: Coat
    var wear = Wear()

    var body: some View {
        Canvas { ctx, size in
            let p = Pen(ctx)
            let s = size.height / 190
            var pose = CatPose(coat: coat, stage: Catalog.stages[0])
            pose.x = size.width * 0.48; pose.y = size.height * 0.95; pose.s = s
            pose.blush = true; pose.tail = 0.6; pose.shadow = false; pose.wear = wear
            CatArt.drawCat(p, pose)
        }
        .accessibilityHidden(true)
    }
}

/// A small drawing of a decoration for the room, for the wardrobe's tiles (#18).
struct DecorIcon: View {
    let id: String
    var pose: CatPose?

    var body: some View {
        Canvas { ctx, size in
            let p = Pen(ctx)
            let w = size.width, h = size.height
            switch id {
            case "plant":
                DecorArt.plant(p, w / 2, h * 0.97, h / 160)
            case "cattree":
                DecorArt.catTree(p, w / 2 - 3, h * 0.97, h / 222)
            case "rug":
                p.ell(w / 2, h * 0.6, w * 0.46, h * 0.28); p.fill(DecorArt.pinkRug)
                p.dash = [5, 4]
                p.ell(w / 2, h * 0.6, w * 0.4, h * 0.2); p.stroke(.white, 2)
                p.dash = []
            case "wallpaper":
                p.rr(4, 2, w - 8, h - 4, 8); p.fill(Color(hex: "FDF0DD"))
                p.fillColor = Color(hex: "F2A7B8")
                for row in 0..<3 {
                    for col in 0..<3 {
                        let x = w * (0.24 + 0.26 * CGFloat(col)) + (row % 2 == 0 ? 0 : w * 0.06)
                        DecorArt.heart(p, x, h * (0.24 + 0.27 * CGFloat(row)), w * 0.06); p.fill()
                    }
                }
            case "portrait":
                let r = CGRect(x: w * 0.16, y: h * 0.12, width: w * 0.68, height: h * 0.72)
                p.rr(r.minX - 4, r.minY - 4, r.width + 8, r.height + 8, 4); p.fill(Color(hex: "C98B4F"))
                if let pose { DecorArt.portrait(p, r, cat: pose, unit: 1) }
            default: // the fairy lights
                DecorArt.lights(p, from: CGPoint(x: 2, y: h * 0.28), to: CGPoint(x: w - 2, y: h * 0.28),
                                sag: h * 0.14, bulb: w * 0.05, glow: false, t: 0, perSwag: 3)
            }
        }
        .accessibilityHidden(true)
    }
}
