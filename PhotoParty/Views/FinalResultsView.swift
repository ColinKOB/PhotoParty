import SwiftUI

struct FinalResultsView: View {
    @EnvironmentObject var viewModel: GameViewModel
    @State private var showTrophy = false
    @State private var showLeaderboard = false
    @State private var celebrateWinner = false

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                // Game Over header
                Text("GAME OVER")
                    .font(AppFonts.caption())
                    .foregroundColor(.white.opacity(0.5))
                    .tracking(4)
                    .padding(.top, 24)

                // Winner announcement
                if let winner = viewModel.gameWinner {
                    VStack(spacing: 16) {
                        // Trophy
                        ZStack {
                            Circle()
                                .fill(
                                    RadialGradient(
                                        colors: [Color.yellow.opacity(0.3), Color.clear],
                                        center: .center,
                                        startRadius: 0,
                                        endRadius: 100
                                    )
                                )
                                .frame(width: 200, height: 200)
                                .scaleEffect(celebrateWinner ? 1.5 : 1)
                                .opacity(celebrateWinner ? 0 : 0.5)
                                .animation(.easeOut(duration: 1).repeatForever(autoreverses: false), value: celebrateWinner)

                            Text("🏆")
                                .font(.system(size: 100))
                                .scaleEffect(showTrophy ? 1 : 0)
                                .rotationEffect(.degrees(showTrophy ? 0 : -30))
                                .animation(.spring(response: 0.6, dampingFraction: 0.5), value: showTrophy)
                        }

                        Text("WINNER")
                            .font(AppFonts.heading(14))
                            .foregroundColor(.yellow)
                            .tracking(4)

                        HStack(spacing: 12) {
                            Text(winner.avatarEmoji)
                                .font(.system(size: 48))

                            VStack(alignment: .leading, spacing: 4) {
                                Text(winner.name)
                                    .font(AppFonts.title(32))
                                    .foregroundColor(.white)

                                Text("\(winner.score) points")
                                    .font(AppFonts.heading(18))
                                    .foregroundColor(.yellow)
                            }
                        }
                    }
                }

                // Full leaderboard
                VStack(alignment: .leading, spacing: 16) {
                    Text("Final Standings")
                        .font(AppFonts.heading(20))
                        .foregroundColor(.white)

                    VStack(spacing: 8) {
                        ForEach(Array(viewModel.game.leaderboard.enumerated()), id: \.element.id) { index, player in
                            FinalLeaderboardRow(
                                rank: index + 1,
                                player: player,
                                isLocalPlayer: player.id == viewModel.localPlayer?.id,
                                totalRounds: viewModel.game.settings.roundCount,
                                roundsWon: viewModel.game.roundWinners.filter { $0 == player.id }.count,
                                show: showLeaderboard
                            )
                        }
                    }
                }
                .padding(.horizontal, 24)

                // Stats
                VStack(spacing: 16) {
                    Text("Game Stats")
                        .font(AppFonts.heading(18))
                        .foregroundColor(.white)

                    HStack(spacing: 24) {
                        StatCard(
                            icon: "person.3.fill",
                            value: "\(viewModel.game.players.count)",
                            label: "Players"
                        )

                        StatCard(
                            icon: "photo.stack",
                            value: "\(viewModel.game.settings.roundCount)",
                            label: "Rounds"
                        )

                        StatCard(
                            icon: "hand.thumbsup.fill",
                            value: "\(totalVotes)",
                            label: "Votes"
                        )
                    }
                }
                .padding(.horizontal, 24)

                // Action buttons
                VStack(spacing: 12) {
                    if viewModel.isHost {
                        Button {
                            viewModel.playAgain()
                        } label: {
                            HStack {
                                Image(systemName: "arrow.counterclockwise")
                                Text("Play Again")
                            }
                            .primaryButtonStyle()
                        }
                    }

                    Button {
                        viewModel.leaveGame()
                    } label: {
                        Text("Leave Game")
                            .secondaryButtonStyle()
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5).delay(0.2)) {
                showTrophy = true
            }

            withAnimation(.easeOut(duration: 0.5).delay(0.5)) {
                showLeaderboard = true
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                celebrateWinner = true
            }
        }
    }

    private var totalVotes: Int {
        viewModel.game.submissions.reduce(0) { $0 + $1.voteCount }
    }
}

struct FinalLeaderboardRow: View {
    let rank: Int
    let player: Player
    let isLocalPlayer: Bool
    let totalRounds: Int
    let roundsWon: Int
    let show: Bool

    var body: some View {
        HStack(spacing: 12) {
            // Rank badge
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(rankGradient)
                    .frame(width: 36, height: 36)

                if rank == 1 {
                    Text("🥇")
                        .font(.system(size: 20))
                } else if rank == 2 {
                    Text("🥈")
                        .font(.system(size: 20))
                } else if rank == 3 {
                    Text("🥉")
                        .font(.system(size: 20))
                } else {
                    Text("\(rank)")
                        .font(AppFonts.heading(16))
                        .foregroundColor(.white)
                }
            }

            // Player info
            Text(player.avatarEmoji)
                .font(.system(size: 28))

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(player.name)
                        .font(AppFonts.heading(16))
                        .foregroundColor(.white)

                    if isLocalPlayer {
                        Text("YOU")
                            .font(AppFonts.caption(10))
                            .foregroundColor(.black)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.yellow)
                            .clipShape(Capsule())
                    }
                }

                Text("\(roundsWon) round\(roundsWon == 1 ? "" : "s") won")
                    .font(AppFonts.caption())
                    .foregroundColor(.white.opacity(0.5))
            }

            Spacer()

            // Score
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(player.score)")
                    .font(AppFonts.title(24))
                    .foregroundColor(.white)

                Text("pts")
                    .font(AppFonts.caption())
                    .foregroundColor(.white.opacity(0.5))
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(isLocalPlayer ? AppColors.primary.opacity(0.2) : Color.white.opacity(0.05))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(rank == 1 ? Color.yellow.opacity(0.5) : (isLocalPlayer ? AppColors.primary : Color.clear), lineWidth: 2)
        )
        .offset(y: show ? 0 : 20)
        .opacity(show ? 1 : 0)
        .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(Double(rank) * 0.1), value: show)
    }

    var rankGradient: LinearGradient {
        switch rank {
        case 1:
            return LinearGradient(colors: [Color.yellow, Color.orange], startPoint: .top, endPoint: .bottom)
        case 2:
            return LinearGradient(colors: [Color.gray.opacity(0.8), Color.gray], startPoint: .top, endPoint: .bottom)
        case 3:
            return LinearGradient(colors: [Color(hex: "CD7F32"), Color(hex: "8B4513")], startPoint: .top, endPoint: .bottom)
        default:
            return LinearGradient(colors: [Color.white.opacity(0.1)], startPoint: .top, endPoint: .bottom)
        }
    }
}

struct StatCard: View {
    let icon: String
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(AppColors.primary)

            Text(value)
                .font(AppFonts.title(28))
                .foregroundColor(.white)

            Text(label)
                .font(AppFonts.caption())
                .foregroundColor(.white.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

#Preview {
    FinalResultsView()
        .environmentObject(GameViewModel())
        .background(AppColors.backgroundDark)
}
