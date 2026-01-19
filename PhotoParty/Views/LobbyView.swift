import SwiftUI

struct LobbyView: View {
    @EnvironmentObject var viewModel: GameViewModel
    @State private var showSettings = false
    @State private var copied = false

    var body: some View {
        ZStack {
            AppColors.backgroundDark.ignoresSafeArea()

            VStack(spacing: 24) {
                // Game code display
                VStack(spacing: 8) {
                    Text("GAME CODE")
                        .font(AppFonts.caption())
                        .foregroundColor(.white.opacity(0.5))
                        .tracking(2)

                    HStack(spacing: 8) {
                        ForEach(Array(viewModel.game.id.enumerated()), id: \.offset) { index, char in
                            Text(String(char))
                                .font(AppFonts.gameCode())
                                .foregroundColor(.white)
                                .frame(width: 44, height: 56)
                                .background(Color.white.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }

                    Button {
                        UIPasteboard.general.string = viewModel.game.id
                        copied = true
                        AudioService.shared.playHaptic(.success)

                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            copied = false
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: copied ? "checkmark" : "doc.on.doc")
                            Text(copied ? "Copied!" : "Copy Code")
                        }
                        .font(AppFonts.caption())
                        .foregroundColor(copied ? AppColors.success : .white.opacity(0.7))
                    }
                    .padding(.top, 8)
                }
                .padding(.top, 16)

                // Players list
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("Players")
                            .font(AppFonts.heading(20))
                            .foregroundColor(.white)

                        Spacer()

                        Text("\(viewModel.game.players.count)/\(AppConstants.maxPlayers)")
                            .font(AppFonts.body())
                            .foregroundColor(.white.opacity(0.5))
                    }

                    ScrollView {
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 16) {
                            ForEach(viewModel.game.players) { player in
                                PlayerCard(
                                    player: player,
                                    isLocalPlayer: player.id == viewModel.localPlayer?.id
                                )
                            }

                            // Empty slots
                            ForEach(0..<(AppConstants.maxPlayers - viewModel.game.players.count), id: \.self) { _ in
                                EmptyPlayerSlot()
                            }
                        }
                    }
                }
                .padding(.horizontal, 24)

                Spacer()

                // Action buttons
                VStack(spacing: 12) {
                    if viewModel.isHost {
                        Button {
                            viewModel.startGame()
                        } label: {
                            HStack {
                                Image(systemName: "play.fill")
                                Text("Start Game")
                            }
                            .primaryButtonStyle()
                        }
                        .disabled(!viewModel.canStartGame)
                        .opacity(viewModel.canStartGame ? 1 : 0.5)

                        if !viewModel.canStartGame {
                            Text("Need at least \(AppConstants.minPlayers) players to start")
                                .font(AppFonts.caption())
                                .foregroundColor(.white.opacity(0.5))
                        }
                    } else {
                        WaitingForHostView()
                    }

                    Button {
                        viewModel.leaveGame()
                    } label: {
                        Text("Leave Game")
                            .font(AppFonts.body())
                            .foregroundColor(AppColors.error)
                    }
                    .padding(.top, 8)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Text(viewModel.isHost ? "Your Game" : "Lobby")
                    .font(AppFonts.heading(20))
                    .foregroundColor(.white)
            }

            if viewModel.isHost {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .foregroundColor(.white)
                    }
                }
            }
        }
        .sheet(isPresented: $showSettings) {
            GameSettingsSheet(settings: viewModel.game.settings) { newSettings in
                viewModel.updateSettings(newSettings)
            }
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
        .onChange(of: viewModel.game.phase) { _, newPhase in
            if newPhase != .lobby {
                viewModel.navigationPath.append(.game)
            }
        }
    }
}

struct PlayerCard: View {
    let player: Player
    let isLocalPlayer: Bool

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(
                        isLocalPlayer ?
                            AppColors.primaryGradient :
                            LinearGradient(colors: [Color.white.opacity(0.1)], startPoint: .top, endPoint: .bottom)
                    )
                    .frame(width: 60, height: 60)

                Text(player.avatarEmoji)
                    .font(.system(size: 32))

                if player.isHost {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.yellow)
                        .offset(x: 20, y: -20)
                }
            }

            Text(player.name)
                .font(AppFonts.body(14))
                .foregroundColor(.white)
                .lineLimit(1)

            if isLocalPlayer {
                Text("(You)")
                    .font(AppFonts.caption(10))
                    .foregroundColor(.white.opacity(0.5))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isLocalPlayer ? AppColors.primary : Color.white.opacity(0.1), lineWidth: isLocalPlayer ? 2 : 1)
        )
    }
}

struct EmptyPlayerSlot: View {
    var body: some View {
        VStack(spacing: 8) {
            Circle()
                .strokeBorder(Color.white.opacity(0.2), style: StrokeStyle(lineWidth: 2, dash: [8]))
                .frame(width: 60, height: 60)

            Text("Waiting...")
                .font(AppFonts.body(14))
                .foregroundColor(.white.opacity(0.3))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color.white.opacity(0.02))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct WaitingForHostView: View {
    @State private var dotCount = 0

    var body: some View {
        HStack(spacing: 8) {
            ProgressView()
                .tint(.white)

            Text("Waiting for host to start" + String(repeating: ".", count: dotCount))
                .font(AppFonts.body())
                .foregroundColor(.white.opacity(0.7))
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .onAppear {
            Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
                dotCount = (dotCount + 1) % 4
            }
        }
    }
}

struct GameSettingsSheet: View {
    @Environment(\.dismiss) var dismiss
    @State var settings: GameSettings
    let onSave: (GameSettings) -> Void

    var body: some View {
        NavigationView {
            Form {
                Section {
                    Stepper("Rounds: \(settings.roundCount)", value: $settings.roundCount, in: AppConstants.minRounds...AppConstants.maxRounds)

                    Stepper("Selection Time: \(settings.selectionTimeLimit)s", value: $settings.selectionTimeLimit, in: AppConstants.minSelectionTime...AppConstants.maxSelectionTime, step: 15)

                    Stepper("Voting Time: \(settings.votingTimeLimit)s", value: $settings.votingTimeLimit, in: AppConstants.minVotingTime...AppConstants.maxVotingTime, step: 10)
                } header: {
                    Text("Game Rules")
                }
            }
            .scrollContentBackground(.hidden)
            .background(AppColors.backgroundDark)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        onSave(settings)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        LobbyView()
            .environmentObject(GameViewModel())
    }
}
