import SwiftUI

struct ResultsView: View {
    @EnvironmentObject var viewModel: GameViewModel
    @State private var showConfetti = false
    @State private var animateScores = false

    var body: some View {
        VStack(spacing: 24) {
            // Round winner announcement
            VStack(spacing: 16) {
                Text("ROUND \(viewModel.game.currentRound) WINNER")
                    .font(AppFonts.caption())
                    .foregroundColor(.white.opacity(0.5))
                    .tracking(2)

                if let winner = viewModel.roundWinner {
                    VStack(spacing: 8) {
                        Text(winner.avatarEmoji)
                            .font(.system(size: 80))
                            .scaleEffect(showConfetti ? 1.2 : 0.5)
                            .animation(.spring(response: 0.5, dampingFraction: 0.5), value: showConfetti)

                        Text(winner.name)
                            .font(AppFonts.title(28))
                            .foregroundColor(.white)

                        if let winningSubmission = viewModel.game.submissions.first(where: { $0.playerId == winner.id }) {
                            Text("\(winningSubmission.voteCount) votes")
                                .font(AppFonts.body())
                                .foregroundColor(AppColors.success)
                        }
                    }
                } else {
                    Text("No winner this round")
                        .font(AppFonts.heading(20))
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            .padding(.top, 16)

            // Winning photo
            if let winner = viewModel.roundWinner,
               let winningSubmission = viewModel.game.submissions.first(where: { $0.playerId == winner.id }),
               let image = winningSubmission.imageData.asUIImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: AppColors.primary.opacity(0.5), radius: 20)
            }

            // Leaderboard
            VStack(alignment: .leading, spacing: 12) {
                Text("Leaderboard")
                    .font(AppFonts.heading(18))
                    .foregroundColor(.white)

                VStack(spacing: 8) {
                    ForEach(Array(viewModel.game.leaderboard.enumerated()), id: \.element.id) { index, player in
                        LeaderboardRow(
                            rank: index + 1,
                            player: player,
                            isLocalPlayer: player.id == viewModel.localPlayer?.id,
                            animate: animateScores
                        )
                    }
                }
            }
            .padding(.horizontal, 24)

            Spacer()

            // Next round indicator
            if !viewModel.game.isLastRound {
                HStack {
                    ProgressView()
                        .tint(.white)

                    Text("Next round starting soon...")
                        .font(AppFonts.body())
                        .foregroundColor(.white.opacity(0.7))
                }
                .padding(.bottom, 24)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) {
                showConfetti = true
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.easeOut(duration: 0.5)) {
                    animateScores = true
                }
            }
        }
    }
}

struct LeaderboardRow: View {
    let rank: Int
    let player: Player
    let isLocalPlayer: Bool
    let animate: Bool

    var body: some View {
        HStack(spacing: 12) {
            // Rank
            ZStack {
                if rank <= 3 {
                    Circle()
                        .fill(rankColor)
                        .frame(width: 32, height: 32)
                }

                Text("\(rank)")
                    .font(AppFonts.heading(16))
                    .foregroundColor(rank <= 3 ? .white : .white.opacity(0.7))
            }
            .frame(width: 32)

            // Player info
            Text(player.avatarEmoji)
                .font(.system(size: 24))

            Text(player.name)
                .font(AppFonts.body())
                .foregroundColor(.white)

            if isLocalPlayer {
                Text("(You)")
                    .font(AppFonts.caption())
                    .foregroundColor(.white.opacity(0.5))
            }

            Spacer()

            // Score
            Text("\(player.score)")
                .font(AppFonts.heading(18))
                .foregroundColor(.white)
                .contentTransition(.numericText())
        }
        .padding(12)
        .background(isLocalPlayer ? AppColors.primary.opacity(0.2) : Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isLocalPlayer ? AppColors.primary : Color.clear, lineWidth: 2)
        )
        .offset(x: animate ? 0 : 50)
        .opacity(animate ? 1 : 0)
        .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(Double(rank) * 0.1), value: animate)
    }

    var rankColor: Color {
        switch rank {
        case 1: return Color.yellow
        case 2: return Color.gray
        case 3: return Color(hex: "CD7F32") // Bronze
        default: return Color.clear
        }
    }
}

#Preview {
    ResultsView()
        .environmentObject(GameViewModel())
        .background(AppColors.backgroundDark)
}
