import SwiftUI

@main
struct TomatickApp: App {
    @StateObject private var model = TimerModel()

    var body: some Scene {
        MenuBarExtra {
            MenuView(model: model)
        } label: {
            Text(model.menuBarTitle)
                .monospacedDigit()
        }
        .menuBarExtraStyle(.window)
    }
}
