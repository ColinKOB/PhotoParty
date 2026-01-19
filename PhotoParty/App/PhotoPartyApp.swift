import SwiftUI

@main
struct PhotoPartyApp: App {
    @StateObject private var gameViewModel = GameViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(gameViewModel)
                .preferredColorScheme(.dark)
        }
    }
}
