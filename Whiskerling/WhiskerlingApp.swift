import SwiftUI

@main
struct WhiskerlingApp: App {
    @State private var model = GameModel()

    var body: some Scene {
        WindowGroup {
            RootView(model: model)
        }
    }
}

struct RootView: View {
    @Bindable var model: GameModel
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        ZStack {
            if model.hasCat && !model.adopting {
                GameView(model: model)
            } else {
                StartView(model: model)
            }
        }
        .sheet(item: $model.adult, onDismiss: model.adultClosed) { route in
            GrownupSheet(model: model, route: route)
        }
        .task { await model.store.load() }
        .onChange(of: model.store.isPro, initial: true) { _, _ in model.proChanged() }
        .onChange(of: model.store.entitlementChecked) { _, _ in model.proChanged() }
        .onChange(of: scenePhase) { _, phase in
            switch phase {
            case .active: model.didBecomeActive()
            case .inactive, .background: model.willResignActive()
            @unknown default: break
            }
        }
        .persistentSystemOverlays(.hidden)
    }
}
