import SwiftUI

struct VotingView: View {
    @EnvironmentObject var viewModel: GameViewModel
    @State private var selectedSubmission: Submission?

    var body: some View {
        VStack(spacing: 16) {
            // Prompt
            if let prompt = viewModel.game.currentPrompt {
                VStack(spacing: 8) {
                    Text("Vote for the best")
                        .font(AppFonts.body())
                        .foregroundColor(.white.opacity(0.7))

                    Text(prompt.text)
                        .font(AppFonts.heading(24))
                        .foregroundColor(.white)
                }
                .padding(.top, 8)
            }

            if viewModel.hasVoted {
                // Already voted state
                VStack(spacing: 24) {
                    Spacer()

                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(AppColors.success)

                    Text("Vote Submitted!")
                        .font(AppFonts.heading(24))
                        .foregroundColor(.white)

                    Text("Waiting for other players...")
                        .font(AppFonts.body())
                        .foregroundColor(.white.opacity(0.7))

                    Spacer()

                    VotingStatusView(
                        players: viewModel.game.players,
                        submissions: viewModel.game.submissions,
                        localPlayerId: viewModel.localPlayer?.id
                    )
                    .padding(.horizontal, 24)
                }
            } else if viewModel.otherSubmissions.isEmpty {
                // No other submissions to vote on
                VStack(spacing: 16) {
                    Spacer()

                    Image(systemName: "hand.thumbsup")
                        .font(.system(size: 60))
                        .foregroundColor(.white.opacity(0.3))

                    Text("No other submissions to vote on")
                        .font(AppFonts.body())
                        .foregroundColor(.white.opacity(0.5))

                    Spacer()
                }
            } else {
                // Voting grid
                ScrollView {
                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: 16),
                        GridItem(.flexible(), spacing: 16)
                    ], spacing: 16) {
                        ForEach(viewModel.otherSubmissions) { submission in
                            VotingCard(
                                submission: submission,
                                player: viewModel.getPlayer(for: submission),
                                isSelected: selectedSubmission?.id == submission.id
                            ) {
                                selectedSubmission = submission
                                AudioService.shared.playHaptic(.selection)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                }

                // Vote button
                Button {
                    if let submission = selectedSubmission {
                        viewModel.vote(for: submission)
                    }
                } label: {
                    HStack {
                        Image(systemName: "hand.thumbsup.fill")
                        Text("Cast Vote")
                    }
                    .primaryButtonStyle()
                }
                .disabled(selectedSubmission == nil)
                .opacity(selectedSubmission == nil ? 0.5 : 1)
                .padding(.horizontal, 24)
            }
        }
        .padding(.bottom, 24)
    }
}

struct VotingCard: View {
    let submission: Submission
    let player: Player?
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 0) {
                // Photo
                if let image = submission.imageData.asUIImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 150)
                        .clipped()
                }

                // Player info
                HStack(spacing: 8) {
                    Text(player?.avatarEmoji ?? "👤")
                        .font(.system(size: 18))

                    Text(player?.name ?? "Player")
                        .font(AppFonts.caption())
                        .foregroundColor(.white)
                        .lineLimit(1)

                    Spacer()
                }
                .padding(10)
                .background(Color.black.opacity(0.5))
            }
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? AppColors.primary : Color.clear, lineWidth: 3)
            )
            .shadow(color: isSelected ? AppColors.primary.opacity(0.5) : .clear, radius: 10)
            .scaleEffect(isSelected ? 1.02 : 1.0)
            .animation(.spring(response: 0.3), value: isSelected)
        }
        .bounceOnTap()
    }
}

struct VotingStatusView: View {
    let players: [Player]
    let submissions: [Submission]
    let localPlayerId: UUID?

    var body: some View {
        HStack(spacing: 12) {
            ForEach(players) { player in
                let hasVoted = hasPlayerVoted(player)

                VStack(spacing: 4) {
                    ZStack {
                        Circle()
                            .fill(hasVoted ? AppColors.success : Color.white.opacity(0.1))
                            .frame(width: 40, height: 40)

                        if hasVoted {
                            Image(systemName: "checkmark")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                        } else {
                            Text(player.avatarEmoji)
                                .font(.system(size: 20))
                        }
                    }

                    Text(player.name)
                        .font(AppFonts.caption(10))
                        .foregroundColor(.white.opacity(0.5))
                        .lineLimit(1)
                }
            }
        }
    }

    private func hasPlayerVoted(_ player: Player) -> Bool {
        // Check if this player has voted for any submission
        submissions.contains { submission in
            submission.playerId != player.id && submission.votes.contains(player.id)
        }
    }
}

#Preview {
    VotingView()
        .environmentObject(GameViewModel())
        .background(AppColors.backgroundDark)
}
