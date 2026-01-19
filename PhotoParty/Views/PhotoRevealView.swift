import SwiftUI

struct PhotoRevealView: View {
    @EnvironmentObject var viewModel: GameViewModel
    @State private var revealedIndex = 0
    @State private var isAnimating = false

    var body: some View {
        VStack(spacing: 24) {
            // Prompt
            if let prompt = viewModel.game.currentPrompt {
                Text(prompt.text)
                    .font(AppFonts.heading(24))
                    .foregroundColor(.white)
                    .padding(.top, 16)
            }

            Spacer()

            // Photo reveal
            if viewModel.game.submissions.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.system(size: 60))
                        .foregroundColor(.white.opacity(0.3))

                    Text("No photos submitted")
                        .font(AppFonts.body())
                        .foregroundColor(.white.opacity(0.5))
                }
            } else {
                TabView(selection: $revealedIndex) {
                    ForEach(Array(viewModel.game.submissions.enumerated()), id: \.element.id) { index, submission in
                        RevealCard(
                            submission: submission,
                            player: viewModel.getPlayer(for: submission),
                            isRevealed: index <= viewModel.currentRevealIndex
                        )
                        .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .automatic))
                .frame(maxHeight: 450)
            }

            Spacer()

            // Progress dots
            HStack(spacing: 8) {
                ForEach(0..<viewModel.game.submissions.count, id: \.self) { index in
                    Circle()
                        .fill(index <= viewModel.currentRevealIndex ? AppColors.primary : Color.white.opacity(0.3))
                        .frame(width: 8, height: 8)
                }
            }
            .padding(.bottom, 24)
        }
        .onChange(of: viewModel.currentRevealIndex) { _, newIndex in
            withAnimation(.easeInOut(duration: 0.3)) {
                revealedIndex = newIndex
            }
        }
    }
}

struct RevealCard: View {
    let submission: Submission
    let player: Player?
    let isRevealed: Bool

    @State private var cardRotation: Double = 0
    @State private var showFront = false

    var body: some View {
        ZStack {
            // Back of card (mystery)
            VStack(spacing: 16) {
                Image(systemName: "questionmark")
                    .font(.system(size: 60, weight: .bold))
                    .foregroundColor(.white.opacity(0.5))

                Text("???")
                    .font(AppFonts.heading(24))
                    .foregroundColor(.white.opacity(0.5))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(
                LinearGradient(
                    colors: [AppColors.backgroundLight, AppColors.backgroundMedium],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .opacity(showFront ? 0 : 1)

            // Front of card (photo)
            VStack(spacing: 0) {
                if let imageData = submission.imageData.asUIImage {
                    Image(uiImage: imageData)
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity)
                        .frame(height: 350)
                        .clipped()
                }

                // Player info
                HStack(spacing: 12) {
                    Text(player?.avatarEmoji ?? "👤")
                        .font(.system(size: 24))

                    Text(player?.name ?? "Player")
                        .font(AppFonts.heading(16))
                        .foregroundColor(.white)

                    Spacer()
                }
                .padding(16)
                .background(Color.black.opacity(0.5))
            }
            .frame(maxWidth: .infinity)
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .opacity(showFront ? 1 : 0)
            .rotation3DEffect(.degrees(showFront ? 0 : 180), axis: (x: 0, y: 1, z: 0))
        }
        .padding(.horizontal, 24)
        .rotation3DEffect(.degrees(cardRotation), axis: (x: 0, y: 1, z: 0))
        .onChange(of: isRevealed) { _, revealed in
            if revealed {
                flipCard()
            }
        }
        .onAppear {
            if isRevealed {
                showFront = true
            }
        }
    }

    private func flipCard() {
        withAnimation(.easeInOut(duration: 0.6)) {
            cardRotation = 180
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            showFront = true
        }

        AudioService.shared.playHaptic(.medium)
    }
}

#Preview {
    PhotoRevealView()
        .environmentObject(GameViewModel())
        .background(AppColors.backgroundDark)
}
