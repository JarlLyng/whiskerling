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

    var body: some View {
        let hud = model.hud
        HStack(spacing: Tokens.Spacing.md) {
            VStack(alignment: .leading, spacing: 2) {
                Text(verbatim: hud.name).font(Theme.font(24)).lineLimit(1)
                Text(verbatim: hud.stageLabel).font(Theme.font(14, .semibold)).foregroundStyle(Theme.muted).lineLimit(1)
            }
            .frame(minWidth: 118, maxWidth: 210, alignment: .leading)
            .contentShape(Rectangle())
            // The grown-up menu: hold the name for two seconds.
            .onLongPressGesture(minimumDuration: 2) { model.adult = .menu }

            HStack(spacing: Tokens.Spacing.md) {
                Meter(icon: "🐟", label: L10n.meterFood, value: hud.needs.food)
                Meter(icon: "😺", label: L10n.meterFun, value: hud.needs.fun)
                Meter(icon: "⚡", label: L10n.meterEnergy, value: hud.needs.energy)
                Meter(icon: "🛁", label: L10n.meterClean, value: hud.needs.clean)
            }
            .frame(maxWidth: .infinity)

            Text(verbatim: "❤️ \(hud.hearts)")
                .font(Theme.font(22))
                .contentTransition(.numericText())
                .animation(.spring(duration: 0.4), value: hud.hearts)
                .accessibilityLabel(L10n.hearts(hud.hearts))

            Button(action: model.toggleSound) {
                Text(verbatim: hud.sound ? "🔊" : "🔇").font(.system(size: 22))
                    .frame(width: 46, height: 46)
                    .background(Theme.option, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .accessibilityLabel(hud.sound ? L10n.soundOn : L10n.soundOff)
        }
        .foregroundStyle(Theme.text)
        .padding(.horizontal, Tokens.Spacing.md)
        .padding(.vertical, Tokens.Spacing.sm)
        .background(Theme.bar)
        .overlay(alignment: .bottom) { Rectangle().fill(Theme.barLine).frame(height: 3) }
    }
}

struct Meter: View {
    let icon: String
    let label: String
    let value: Double
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(spacing: 5) {
            // A low need makes its icon pulse, or with Reduce Motion simply stay larger.
            Text(verbatim: icon)
                .font(.system(size: 24))
                .scaleEffect(value < 25 ? 1.25 : 1)
                .animation(reduceMotion ? nil : (value < 25 ? .easeInOut(duration: 0.7).repeatForever() : .default),
                           value: value < 25)
                .id(reduceMotion) // a pulse already running stops when the setting is turned on
            VStack(alignment: .leading, spacing: 2) {
                Text(verbatim: label).font(Theme.font(12)).foregroundStyle(Theme.muted).lineLimit(1)
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
                    let outside = model.hud.room == .garden
                    action(outside ? "🏠" : "🌳", outside ? L10n.indoors : L10n.garden, Theme.garden,
                           dim: model.hud.lightsOff, model.tapRoom)
                        .overlay(alignment: .topTrailing) {
                            if !outside && !model.isPro { LockBadge().offset(x: 4, y: -6) }
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
                Text(verbatim: icon).font(.system(size: 36))
                Text(verbatim: label).font(Theme.font(18)).lineLimit(1).minimumScaleFactor(0.7)
            }
            .frame(maxWidth: 170).frame(height: 88)
        }
        .buttonStyle(PillButtonStyle(color: color))
        .opacity(dim ? 0.4 : 1)
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
