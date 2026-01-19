import SwiftUI

struct GameView: View {
    @EnvironmentObject var viewModel: GameViewModel

    var body: some View {
        ZStack {
            AppColors.backgroundDark.ignoresSafeArea()

            VStack {
                // Header with round info and timer
                GameHeader(
                    round: viewModel.game.currentRound,
                    totalRounds: viewModel.game.settings.roundCount,
                    phase: viewModel.game.phase,
                    timeRemaining: viewModel.timeRemaining,
                    isTimerRunning: viewModel.isTimerRunning
                )

                // Main content based on phase
                switch viewModel.game.phase {
                case .lobby:
                    EmptyView()

                case .promptDisplay:
                    PromptDisplayView(prompt: viewModel.game.currentPrompt)

                case .photoSelection:
                    PhotoSelectionView()

                case .waitingForSubmissions:
                    WaitingForSubmissionsView()

                case .photoReveal:
                    PhotoRevealView()

                case .voting:
                    VotingView()

                case .roundResults:
                    ResultsView()

                case .finalResults:
                    FinalResultsView()
                }
            }
        }
        .navigationBarBackButtonHidden(true)
    }
}

struct GameHeader: View {
    let round: Int
    let totalRounds: Int
    let phase: GamePhase
    let timeRemaining: Int
    let isTimerRunning: Bool

    var body: some View {
        HStack {
            // Round indicator
            VStack(alignment: .leading, spacing: 2) {
                Text("ROUND")
                    .font(AppFonts.caption(10))
                    .foregroundColor(.white.opacity(0.5))

                Text("\(round)/\(totalRounds)")
                    .font(AppFonts.heading(20))
                    .foregroundColor(.white)
            }

            Spacer()

            // Phase indicator
            Text(phase.displayName)
                .font(AppFonts.body(14))
                .foregroundColor(.white.opacity(0.7))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.white.opacity(0.1))
                .clipShape(Capsule())

            Spacer()

            // Timer
            if isTimerRunning {
                TimerView(timeRemaining: timeRemaining)
            } else {
                Color.clear.frame(width: 60)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color.black.opacity(0.3))
    }
}

struct PromptDisplayView: View {
    let prompt: Prompt?
    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            VStack(spacing: 24) {
                Text(prompt?.category.icon ?? "🎲")
                    .font(.system(size: 60))

                Text(prompt?.text ?? "Get Ready!")
                    .font(AppFonts.title(36))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                Text(prompt?.category.rawValue ?? "")
                    .font(AppFonts.body())
                    .foregroundColor(.white.opacity(0.5))
            }
            .scaleEffect(scale)
            .opacity(opacity)

            Spacer()

            Text("Find a photo from your camera roll!")
                .font(AppFonts.body())
                .foregroundColor(.white.opacity(0.7))
                .padding(.bottom, 48)
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                scale = 1.0
                opacity = 1.0
            }
            AudioService.shared.playSound(.countdown)
            AudioService.shared.playHaptic(.medium)
        }
    }
}

struct PhotoSelectionView: View {
    @EnvironmentObject var viewModel: GameViewModel
    @State private var showingPicker = false

    var body: some View {
        VStack(spacing: 24) {
            // Prompt reminder
            if let prompt = viewModel.game.currentPrompt {
                Text(prompt.text)
                    .font(AppFonts.heading(24))
                    .foregroundColor(.white)
                    .padding(.top, 16)
            }

            Spacer()

            // Selected image or picker button
            if let selectedImage = viewModel.selectedImage {
                VStack(spacing: 16) {
                    Image(uiImage: selectedImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 300)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: .black.opacity(0.3), radius: 10)

                    HStack(spacing: 16) {
                        Button {
                            viewModel.clearSelectedImage()
                        } label: {
                            HStack {
                                Image(systemName: "arrow.counterclockwise")
                                Text("Change")
                            }
                            .secondaryButtonStyle()
                        }

                        Button {
                            viewModel.submitPhoto()
                        } label: {
                            HStack {
                                Image(systemName: "paperplane.fill")
                                Text("Submit")
                            }
                            .primaryButtonStyle()
                        }
                    }
                    .padding(.horizontal, 24)
                }
            } else {
                Button {
                    showingPicker = true
                } label: {
                    VStack(spacing: 16) {
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.system(size: 60))
                            .foregroundColor(.white.opacity(0.5))

                        Text("Tap to choose a photo")
                            .font(AppFonts.heading(18))
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 300)
                    .background(Color.white.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: 24))
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .strokeBorder(Color.white.opacity(0.2), style: StrokeStyle(lineWidth: 2, dash: [10]))
                    )
                }
                .padding(.horizontal, 24)
                .bounceOnTap()
            }

            Spacer()

            // Submission status
            SubmissionStatusView(
                players: viewModel.game.players,
                submissions: viewModel.game.submissions
            )
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .sheet(isPresented: $showingPicker) {
            PhotoPickerView { image in
                viewModel.selectImage(image)
            }
        }
    }
}

struct SubmissionStatusView: View {
    let players: [Player]
    let submissions: [Submission]

    var body: some View {
        HStack(spacing: 12) {
            ForEach(players) { player in
                let hasSubmitted = submissions.contains { $0.playerId == player.id }

                VStack(spacing: 4) {
                    ZStack {
                        Circle()
                            .fill(hasSubmitted ? AppColors.success : Color.white.opacity(0.1))
                            .frame(width: 40, height: 40)

                        if hasSubmitted {
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
}

struct WaitingForSubmissionsView: View {
    @EnvironmentObject var viewModel: GameViewModel

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            if viewModel.hasSubmitted {
                VStack(spacing: 16) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(AppColors.success)

                    Text("Photo Submitted!")
                        .font(AppFonts.heading(24))
                        .foregroundColor(.white)

                    Text("Waiting for other players...")
                        .font(AppFonts.body())
                        .foregroundColor(.white.opacity(0.7))
                }
            } else {
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.5)
                        .tint(.white)

                    Text("Time's up!")
                        .font(AppFonts.heading(24))
                        .foregroundColor(.white)
                }
            }

            Spacer()

            SubmissionStatusView(
                players: viewModel.game.players,
                submissions: viewModel.game.submissions
            )
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
    }
}

#Preview {
    GameView()
        .environmentObject(GameViewModel())
}
