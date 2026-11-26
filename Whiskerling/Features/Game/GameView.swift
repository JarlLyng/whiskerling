import SwiftUI

struct GameView: View {
    @Bindable var model: GameModel

    var body: some View {
        VStack(spacing: 0) {
            HUDBar(model: model)
            ZStack(alignment: .top) {
                GameCanvas(model: model)
                if let toast = model.toast {
                    Text(toast)
                        .font(Theme.font(19))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 18).padding(.vertical, 10)
                        .background(Color(hex: "4A3B35").opacity(0.9), in: Capsule())
                        .padding(.top, 12)
                        .transition(.opacity)
                        .allowsHitTesting(false)
                }
                if model.overlay == .food { FoodOverlay(model: model) }
                if model.overlay == .games { GamesOverlay(model: model) }
                if model.overlay == .wardrobe { WardrobeOverlay(model: model) }
                if model.overlay == .rooms { RoomsOverlay(model: model) }
            }
            .animation(.easeInOut(duration: Tokens.Motion.Duration.normal), value: model.toast)
            ActionBar(model: model)
        }
        .background(Theme.bar)
    }
}

/// The room. Redrawn every frame; touches go straight to the world.
struct GameCanvas: View {
    let model: GameModel
    @State private var down = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { ctx, size in
                model.world.frame(ctx, size: size, date: timeline.date)
                if model.world.wantsSync { model.scheduleSync() }
            }
        }
        // Follows the setting live, also when it changes while the app is open (#14).
        .onChange(of: reduceMotion, initial: true) { _, on in model.world.reduceMotion = on }
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    if !down {
                        down = true
                        model.world.pointerDown(value.location)
                    } else {
                        model.world.pointerMove(value.location)
                    }
                }
                .onEnded { _ in
                    down = false
                    model.world.pointerUp()
                }
        )
        .accessibilityElement()
        .accessibilityLabel(Text(verbatim: model.hud.name))
        .accessibilityAddTraits(.isImage)
    }
}

struct HUDBar: View {
    let model: GameModel
    /// Below this width the meters get a row of their own, so their labels never get cut (#15).
    static let compactWidth: CGFloat = 700
    @State private var width: CGFloat = 1000

    var body: some View {
        let hud = model.hud
        Group {
            if width < HUDBar.compactWidth {
                VStack(spacing: Tokens.Spacing.sm) {
                    HStack(spacing: Tokens.Spacing.md) {
                        nameAndStage(hud).frame(maxWidth: .infinity, alignment: .leading)
                        hearts(hud)
                        soundButton(hud)
                    }
                    meters(hud, compact: true)
                }
            } else {
                HStack(spacing: Tokens.Spacing.md) {
                    nameAndStage(hud).frame(minWidth: 118, maxWidth: 260, alignment: .leading)
                    meters(hud).frame(maxWidth: .infinity)
                    hearts(hud)
                    soundButton(hud)
                }
            }
        }
        .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { width = $0 }
        .foregroundStyle(Theme.text)
        .padding(.horizontal, Tokens.Spacing.md)
        .padding(.vertical, Tokens.Spacing.sm)
        .background(Theme.bar)
        .overlay(alignment: .bottom) { Rectangle().fill(Theme.barLine).frame(height: 3) }
    }

    private func nameAndStage(_ hud: HUD) -> some View {
        HStack(spacing: Tokens.Spacing.sm) {
            VStack(alignment: .leading, spacing: 2) {
                Text(verbatim: hud.name).font(Theme.font(24)).lineLimit(1)
                Text(verbatim: hud.stageLabel).font(Theme.font(14, .semibold)).foregroundStyle(Theme.muted).lineLimit(1)
            }
            .contentShape(Rectangle())
            // The grown-up menu: hold the name for two seconds.
            .onLongPressGesture(minimumDuration: 2) { model.adult = .menu }
            otherCat(hud)
        }
    }

    /// The other cat, small: a tap shows it instead. Or, for a grown cat on its own, a "+" for a
    /// kitten to live with it (#21).
    @ViewBuilder private func otherCat(_ hud: HUD) -> some View {
        if let name = hud.otherName, let coat = hud.otherCoat {
            Button(action: model.switchCats) {
                KittenPortrait(coat: Catalog.coat(coat), wear: hud.otherWear)
                    .frame(width: 40, height: 40)
                    .padding(3)
                    .background(Theme.option, in: Circle())
            }
            .buttonStyle(.plain)
            .disabled(model.mode != .normal)
            .accessibilityLabel(L10n.showCat(name))
        } else if hud.canAdopt {
            Button(action: model.tapAdopt) {
                Image(systemName: "plus")
                    .font(.system(size: 18, weight: .heavy))
                    .frame(width: 40, height: 40)
                    .background(Theme.option, in: Circle())
            }
            .buttonStyle(.plain)
            .disabled(model.mode != .normal)
            .accessibilityLabel(L10n.adoptButton)
        }
    }

    private func meters(_ hud: HUD, compact: Bool = false) -> some View {
        HStack(spacing: compact ? Tokens.Spacing.sm : Tokens.Spacing.md) {
            Meter(icon: "🐟", label: L10n.meterFood, value: hud.needs.food, compact: compact)
            Meter(icon: "😺", label: L10n.meterFun, value: hud.needs.fun, compact: compact)
            Meter(icon: "⚡", label: L10n.meterEnergy, value: hud.needs.energy, compact: compact)
            Meter(icon: "🛁", label: L10n.meterClean, value: hud.needs.clean, compact: compact)
        }
    }

    private func hearts(_ hud: HUD) -> some View {
        Text(verbatim: "❤️ \(hud.hearts)")
            .font(Theme.font(22))
            .contentTransition(.numericText())
            .animation(.spring(duration: 0.4), value: hud.hearts)
            .accessibilityLabel(L10n.hearts(hud.hearts))
    }

    private func soundButton(_ hud: HUD) -> some View {
        Button(action: model.toggleSound) {
            Text(verbatim: hud.sound ? "🔊" : "🔇").font(.system(size: 22))
                .frame(width: 46, height: 46)
                .background(Theme.option, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .accessibilityLabel(hud.sound ? L10n.soundOn : L10n.soundOff)
    }
}

struct Meter: View {
    let icon: String
    let label: String
    let value: Double
    /// Smaller, for the meters' own row in a narrow window.
    var compact = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(spacing: compact ? 3 : 5) {
            // A low need makes its icon pulse, or with Reduce Motion simply stay larger.
            Text(verbatim: icon)
                .font(.system(size: compact ? 19 : 24))
                .scaleEffect(value < 25 ? 1.25 : 1)
                .animation(reduceMotion ? nil : (value < 25 ? .easeInOut(duration: 0.7).repeatForever() : .default),
                           value: value < 25)
                .id(reduceMotion) // a pulse already running stops when the setting is turned on
            VStack(alignment: .leading, spacing: 2) {
                Text(verbatim: label).font(Theme.font(compact ? 11 : 12)).foregroundStyle(Theme.muted).lineLimit(1)
                    .minimumScaleFactor(0.8)
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Theme.track)
                        Capsule().fill(Theme.meter(value)).frame(width: max(6, geo.size.width * value / 100))
                    }
                }
                .frame(height: 14)
                .animation(.easeInOut(duration: 0.5), value: value)
            }
        }
        .frame(maxWidth: 170)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(label)
        .accessibilityValue(Text(verbatim: "\(Int(value.rounded())) %"))
    }
}

struct ActionBar: View {
    let model: GameModel

    var body: some View {
        Group {
            if model.mode == .normal {
                HStack(spacing: Tokens.Spacing.sm) {
                    action("🍽️", L10n.feed, Theme.feed, dim: model.hud.lightsOff, model.tapFeed)
                    action("🧶", L10n.play, Theme.play, dim: model.hud.lightsOff, model.tapPlay)
                    action("🧽", L10n.wash, Theme.wash, dim: model.hud.lightsOff, model.tapWash)
                    action(model.hud.lightsOff ? "☀️" : "🌙", model.hud.lightsOff ? L10n.lightsOn : L10n.sleep, Theme.sleep, dim: false, model.tapSleep)
                    action("🎀", L10n.dressUp, Theme.dress, dim: false, model.openWardrobe)
                        .overlay(alignment: .topTrailing) {
                            if model.hud.hasNewItems {
                                Text(verbatim: "!").font(Theme.font(15)).foregroundStyle(.white)
                                    .frame(minWidth: 26, minHeight: 26)
                                    .background(Color(hex: "EF476F"), in: Capsule())
                                    .offset(x: 4, y: -6)
                            }
                        }
                    // "Go to…": the living room, the kitchen and the garden (#38)
                    action("🚪", L10n.goTo, Theme.garden, dim: model.hud.lightsOff, model.tapRoom)
                        .overlay(alignment: .topTrailing) {
                            if !model.isPro { LockBadge().offset(x: 4, y: -6) }
                        }
                }
                .frame(maxWidth: 1000)
            } else {
                HStack(spacing: Tokens.Spacing.md) {
                    Text(verbatim: model.modeHint).font(Theme.font(21)).frame(maxWidth: .infinity, alignment: .leading)
                    Button(action: model.tapDone) {
                        Text(verbatim: L10n.done + " ✓").font(Theme.font(22)).padding(.horizontal, 30).frame(height: 72)
                    }
                    .buttonStyle(PillButtonStyle(color: Theme.go))
                }
                .frame(height: 88)
            }
        }
        .foregroundStyle(Theme.text)
        .padding(.horizontal, Tokens.Spacing.sm)
        .padding(.top, Tokens.Spacing.md)
        .padding(.bottom, Tokens.Spacing.md)
        .frame(maxWidth: .infinity)
        .background(Theme.bar)
        .overlay(alignment: .top) { Rectangle().fill(Theme.barLine).frame(height: 3) }
    }

    private func action(_ icon: String, _ label: String, _ color: Color, dim: Bool, _ fn: @escaping () -> Void) -> some View {
        Button(action: fn) {
            VStack(spacing: 0) {
                // while the cat sleeps: a quiet face and a faded icon, the words still clear (#43)
                Text(verbatim: icon).font(.system(size: 36)).opacity(dim ? 0.4 : 1)
                Text(verbatim: label).font(Theme.font(18)).lineLimit(1).minimumScaleFactor(0.7)
            }
            .frame(maxWidth: 170).frame(height: 88)
        }
        .buttonStyle(PillButtonStyle(color: dim ? Theme.restingFace : color))
    }
}

/// A small padlock on something that needs Pro. Tapping it leads to the parental gate.
struct LockBadge: View {
    var body: some View {
        Text(verbatim: "🔒").font(.system(size: 15))
            .frame(width: 30, height: 30)
            .background(Color.white, in: Circle())
            .overlay(Circle().stroke(Theme.barLine, lineWidth: 2))
            .accessibilityLabel(L10n.pro)
    }
}
