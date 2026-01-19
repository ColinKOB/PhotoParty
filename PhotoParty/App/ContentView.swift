import SwiftUI

struct ContentView: View {
    @EnvironmentObject var viewModel: GameViewModel

    var body: some View {
        NavigationStack(path: $viewModel.navigationPath) {
            HomeView()
                .navigationDestination(for: GameScreen.self) { screen in
                    switch screen {
                    case .lobby:
                        LobbyView()
                    case .game:
                        GameView()
                    case .joinGame:
                        JoinGameView()
                    }
                }
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "An error occurred")
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(GameViewModel())
}
