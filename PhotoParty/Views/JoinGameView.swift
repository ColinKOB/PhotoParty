import SwiftUI

struct JoinGameView: View {
    @EnvironmentObject var viewModel: GameViewModel
    @Environment(\.dismiss) var dismiss
    @State private var gameCode: String = ""
    @State private var isSearching = true
    @FocusState private var isCodeFieldFocused: Bool

    var body: some View {
        ZStack {
            AppColors.backgroundDark.ignoresSafeArea()

            VStack(spacing: 32) {
                // Header
                VStack(spacing: 8) {
                    Text("Join Game")
                        .font(AppFonts.title())
                        .foregroundColor(.white)

                    Text("Enter the game code or select a nearby game")
                        .font(AppFonts.body())
                        .foregroundColor(.white.opacity(0.7))
                }
                .padding(.top, 24)

                // Game code input
                VStack(spacing: 16) {
                    Text("GAME CODE")
                        .font(AppFonts.caption())
                        .foregroundColor(.white.opacity(0.5))
                        .tracking(2)

                    TextField("", text: $gameCode)
                        .font(AppFonts.gameCode(36))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                        .focused($isCodeFieldFocused)
                        .onChange(of: gameCode) { _, newValue in
                            gameCode = String(newValue.uppercased().prefix(6))
                        }
                        .padding()
                        .background(Color.white.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(gameCode.count == 6 ? AppColors.success : Color.white.opacity(0.2), lineWidth: 2)
                        )

                    Button {
                        viewModel.joinGameWithCode(gameCode)
                    } label: {
                        Text("Join with Code")
                            .primaryButtonStyle()
                    }
                    .disabled(gameCode.count != 6)
                    .opacity(gameCode.count == 6 ? 1 : 0.5)
                }
                .padding(.horizontal, 24)

                // Divider
                HStack {
                    Rectangle()
                        .fill(Color.white.opacity(0.2))
                        .frame(height: 1)
                    Text("OR")
                        .font(AppFonts.caption())
                        .foregroundColor(.white.opacity(0.5))
                    Rectangle()
                        .fill(Color.white.opacity(0.2))
                        .frame(height: 1)
                }
                .padding(.horizontal, 24)

                // Nearby games
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("Nearby Games")
                            .font(AppFonts.heading(18))
                            .foregroundColor(.white)

                        Spacer()

                        if isSearching {
                            ProgressView()
                                .tint(.white)
                        }
                    }

                    if viewModel.availableGames.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "wifi.slash")
                                .font(.system(size: 40))
                                .foregroundColor(.white.opacity(0.3))

                            Text("No games found nearby")
                                .font(AppFonts.body())
                                .foregroundColor(.white.opacity(0.5))

                            Text("Make sure the host has created a game")
                                .font(AppFonts.caption())
                                .foregroundColor(.white.opacity(0.3))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 32)
                    } else {
                        ScrollView {
                            VStack(spacing: 12) {
                                ForEach(viewModel.availableGames) { game in
                                    NearbyGameRow(game: game) {
                                        viewModel.joinGame(game)
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 24)

                Spacer()
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                }
            }
        }
        .onAppear {
            viewModel.startBrowsingForGames()
        }
        .onDisappear {
            viewModel.stopBrowsingForGames()
        }
    }
}

struct NearbyGameRow: View {
    let game: DiscoveredGame
    let onJoin: () -> Void

    var body: some View {
        Button(action: onJoin) {
            HStack(spacing: 16) {
                Text(game.hostEmoji)
                    .font(.system(size: 32))
                    .frame(width: 50, height: 50)
                    .background(Color.white.opacity(0.1))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 4) {
                    Text("\(game.hostName)'s Game")
                        .font(AppFonts.heading(16))
                        .foregroundColor(.white)

                    Text("Code: \(game.gameCode)")
                        .font(AppFonts.caption())
                        .foregroundColor(.white.opacity(0.5))
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white.opacity(0.5))
            }
            .padding(16)
            .background(Color.white.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
        }
        .bounceOnTap()
    }
}

#Preview {
    NavigationStack {
        JoinGameView()
            .environmentObject(GameViewModel())
    }
}
