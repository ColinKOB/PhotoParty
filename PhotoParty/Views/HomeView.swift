import SwiftUI

struct HomeView: View {
    @EnvironmentObject var viewModel: GameViewModel
    @State private var playerName: String = ""
    @State private var showNameEntry = false
    @State private var pendingAction: HomeAction?
    @FocusState private var isNameFieldFocused: Bool

    enum HomeAction {
        case createGame
        case joinGame
    }

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    AppColors.backgroundDark,
                    AppColors.backgroundMedium,
                    AppColors.backgroundLight.opacity(0.5)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                // Logo and title
                VStack(spacing: 16) {
                    Text("📸")
                        .font(.system(size: 80))
                        .shadow(color: .white.opacity(0.3), radius: 20)

                    Text("PhotoParty")
                        .font(AppFonts.title(42))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.white, AppColors.accent],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )

                    Text("The party game where your camera roll becomes the game!")
                        .font(AppFonts.body())
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }

                Spacer()

                // Action buttons
                VStack(spacing: 16) {
                    Button {
                        pendingAction = .createGame
                        checkNameAndProceed()
                    } label: {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Create Game")
                        }
                        .primaryButtonStyle()
                    }
                    .bounceOnTap()

                    Button {
                        pendingAction = .joinGame
                        checkNameAndProceed()
                    } label: {
                        HStack {
                            Image(systemName: "person.2.fill")
                            Text("Join Game")
                        }
                        .secondaryButtonStyle()
                    }
                    .bounceOnTap()
                }
                .padding(.horizontal, 24)

                Spacer()

                // Footer
                Text("2-8 players • Local multiplayer")
                    .font(AppFonts.caption())
                    .foregroundColor(.white.opacity(0.5))
                    .padding(.bottom, 24)
            }
        }
        .sheet(isPresented: $showNameEntry) {
            NameEntrySheet(
                playerName: $playerName,
                onConfirm: {
                    proceedWithAction()
                }
            )
            .presentationDetents([.height(280)])
            .presentationDragIndicator(.visible)
        }
        .navigationBarHidden(true)
    }

    private func checkNameAndProceed() {
        if viewModel.localPlayer != nil {
            proceedWithAction()
        } else {
            showNameEntry = true
        }
    }

    private func proceedWithAction() {
        showNameEntry = false

        if viewModel.localPlayer == nil && !playerName.isEmpty {
            viewModel.createPlayer(name: playerName)
        }

        guard viewModel.localPlayer != nil else { return }

        switch pendingAction {
        case .createGame:
            viewModel.createGame()
        case .joinGame:
            viewModel.navigationPath.append(.joinGame)
        case .none:
            break
        }

        pendingAction = nil
    }
}

struct NameEntrySheet: View {
    @Binding var playerName: String
    let onConfirm: () -> Void
    @FocusState private var isFocused: Bool
    @State private var selectedEmoji: String = Player.randomEmoji()

    private let emojis = [
        "😀", "😎", "🤩", "😈", "👻", "🤖", "👽", "🎃",
        "🦄", "🐶", "🐱", "🦊", "🐸", "🐵", "🐷", "🐻"
    ]

    var body: some View {
        VStack(spacing: 24) {
            Text("What's your name?")
                .font(AppFonts.heading())
                .foregroundColor(.white)

            // Emoji selector
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(emojis, id: \.self) { emoji in
                        Text(emoji)
                            .font(.system(size: 32))
                            .padding(8)
                            .background(
                                Circle()
                                    .fill(selectedEmoji == emoji ? AppColors.primary : Color.white.opacity(0.1))
                            )
                            .onTapGesture {
                                selectedEmoji = emoji
                                AudioService.shared.playHaptic(.selection)
                            }
                    }
                }
                .padding(.horizontal)
            }

            TextField("Enter your name", text: $playerName)
                .font(AppFonts.heading())
                .foregroundColor(.white)
                .padding()
                .background(Color.white.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .focused($isFocused)
                .submitLabel(.done)
                .onSubmit {
                    if !playerName.isEmpty {
                        onConfirm()
                    }
                }

            Button {
                onConfirm()
            } label: {
                Text("Let's Go!")
                    .primaryButtonStyle()
            }
            .disabled(playerName.trimmingCharacters(in: .whitespaces).isEmpty)
            .opacity(playerName.trimmingCharacters(in: .whitespaces).isEmpty ? 0.5 : 1)
        }
        .padding(24)
        .background(AppColors.backgroundDark)
        .onAppear {
            isFocused = true
        }
    }
}

#Preview {
    HomeView()
        .environmentObject(GameViewModel())
}
