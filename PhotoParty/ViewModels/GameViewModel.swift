import Foundation
import SwiftUI
import Combine

@MainActor
class GameViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var game: Game = Game()
    @Published var localPlayer: Player?
    @Published var selectedImage: UIImage?
    @Published var selectedImageData: Data?

    @Published var timeRemaining: Int = 0
    @Published var isTimerRunning = false

    @Published var currentRevealIndex: Int = 0
    @Published var showingResults = false

    @Published var errorMessage: String?
    @Published var showError = false

    @Published var navigationPath: [GameScreen] = []

    // MARK: - Services

    private let multipeerService = MultipeerService()
    private let promptService = PromptService.shared
    private let audioService = AudioService.shared

    private var timerCancellable: AnyCancellable?
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Computed Properties

    var isHost: Bool {
        localPlayer?.isHost ?? false
    }

    var canStartGame: Bool {
        game.players.count >= AppConstants.minPlayers && isHost
    }

    var mySubmission: Submission? {
        guard let playerId = localPlayer?.id else { return nil }
        return game.submissions.first { $0.playerId == playerId }
    }

    var hasSubmitted: Bool {
        mySubmission != nil
    }

    var hasVoted: Bool {
        guard let playerId = localPlayer?.id else { return false }
        return game.submissions.contains { $0.votes.contains(playerId) }
    }

    var otherSubmissions: [Submission] {
        guard let playerId = localPlayer?.id else { return game.submissions }
        return game.submissions.filter { $0.playerId != playerId }
    }

    var roundWinner: Player? {
        guard let winningSubmission = game.submissions.max(by: { $0.voteCount < $1.voteCount }) else {
            return nil
        }
        return game.players.first { $0.id == winningSubmission.playerId }
    }

    var gameWinner: Player? {
        game.leaderboard.first
    }

    // MARK: - Initialization

    init() {
        multipeerService.delegate = self
    }

    // MARK: - Player Setup

    func createPlayer(name: String) {
        let player = Player(name: name, isHost: false)
        localPlayer = player
        multipeerService.setup(playerName: name, playerId: player.id)
    }

    // MARK: - Game Creation

    func createGame() {
        guard var player = localPlayer else { return }

        player.isHost = true
        localPlayer = player

        game = Game(players: [player])
        multipeerService.startHosting(gameCode: game.id, player: player)

        navigationPath.append(.lobby)
        audioService.playHaptic(.success)
    }

    func startBrowsingForGames() {
        multipeerService.startBrowsing()
    }

    func stopBrowsingForGames() {
        multipeerService.stopBrowsing()
    }

    var availableGames: [DiscoveredGame] {
        multipeerService.availableGames
    }

    func joinGame(_ discoveredGame: DiscoveredGame) {
        guard let player = localPlayer else { return }

        multipeerService.joinGame(discoveredGame, player: player)
        navigationPath.append(.lobby)
        audioService.playHaptic(.success)
    }

    func joinGameWithCode(_ code: String) {
        // Find game with matching code
        if let game = multipeerService.availableGames.first(where: { $0.gameCode == code.uppercased() }) {
            joinGame(game)
        } else {
            showError(message: "Game not found. Make sure the code is correct and the host is nearby.")
        }
    }

    // MARK: - Game Flow

    func startGame() {
        guard isHost, canStartGame else { return }

        game.currentRound = 1
        startNewRound()

        audioService.playSound(.success)
        audioService.playHaptic(.success)
    }

    func startNewRound() {
        guard isHost else { return }

        // Get new prompt
        guard let prompt = promptService.getRandomPrompt(
            excluding: game.usedPromptIds,
            categories: game.settings.categories
        ) else {
            showError(message: "No more prompts available!")
            return
        }

        game.currentPrompt = prompt
        game.usedPromptIds.insert(prompt.id)
        game.phase = .promptDisplay
        game.resetForNextRound()

        broadcastGameState()

        // After prompt display, move to photo selection
        Task {
            try? await Task.sleep(nanoseconds: UInt64(AppConstants.promptDisplayDuration * 1_000_000_000))
            await MainActor.run {
                self.transitionToPhotoSelection()
            }
        }
    }

    private func transitionToPhotoSelection() {
        guard isHost else { return }

        game.phase = .photoSelection
        broadcastGameState()

        startTimer(duration: game.settings.selectionTimeLimit)
    }

    func submitPhoto() {
        guard let player = localPlayer,
              let imageData = selectedImageData else { return }

        let submission = Submission(playerId: player.id, imageData: imageData)
        game.addSubmission(submission)

        if let index = game.players.firstIndex(where: { $0.id == player.id }) {
            game.players[index].hasSubmitted = true
        }

        multipeerService.sendSubmission(submission)

        audioService.playSound(.submit)
        audioService.playHaptic(.success)

        // Clear selection
        selectedImage = nil
        selectedImageData = nil

        // Check if all players submitted
        checkAllSubmissions()
    }

    private func checkAllSubmissions() {
        if isHost && game.allPlayersSubmitted {
            stopTimer()
            transitionToPhotoReveal()
        }
    }

    private func transitionToPhotoReveal() {
        guard isHost else { return }

        game.phase = .photoReveal
        currentRevealIndex = 0
        broadcastGameState()

        // Reveal photos one by one
        revealNextPhoto()
    }

    private func revealNextPhoto() {
        guard isHost else { return }

        if currentRevealIndex < game.submissions.count {
            audioService.playSound(.reveal)
            audioService.playHaptic(.medium)

            Task {
                try? await Task.sleep(nanoseconds: UInt64(AppConstants.photoRevealDuration * 1_000_000_000))
                await MainActor.run {
                    self.currentRevealIndex += 1
                    self.revealNextPhoto()
                }
            }
        } else {
            transitionToVoting()
        }
    }

    private func transitionToVoting() {
        guard isHost else { return }

        game.phase = .voting
        broadcastGameState()

        startTimer(duration: game.settings.votingTimeLimit)
    }

    func vote(for submission: Submission) {
        guard let player = localPlayer,
              submission.playerId != player.id,
              !hasVoted else { return }

        game.addVote(from: player.id, to: submission.id)
        multipeerService.sendVote(from: player.id, for: submission.id)

        audioService.playSound(.vote)
        audioService.playHaptic(.light)

        checkAllVotes()
    }

    private func checkAllVotes() {
        if isHost && game.allPlayersVoted {
            stopTimer()
            transitionToRoundResults()
        }
    }

    private func transitionToRoundResults() {
        guard isHost else { return }

        _ = game.calculateRoundResults()
        game.phase = .roundResults
        broadcastGameState()

        audioService.playSound(.roundEnd)
        audioService.playHaptic(.success)

        // Wait then either next round or final results
        Task {
            try? await Task.sleep(nanoseconds: UInt64(AppConstants.resultsDisplayDuration * 1_000_000_000))
            await MainActor.run {
                if self.game.isLastRound {
                    self.transitionToFinalResults()
                } else {
                    self.game.currentRound += 1
                    self.startNewRound()
                }
            }
        }
    }

    private func transitionToFinalResults() {
        guard isHost else { return }

        game.phase = .finalResults
        broadcastGameState()

        audioService.playSound(.gameEnd)
        audioService.playHaptic(.success)
    }

    func playAgain() {
        guard isHost else { return }

        game.resetGame()
        broadcastGameState()

        audioService.playHaptic(.success)
    }

    func leaveGame() {
        multipeerService.disconnect()
        game = Game()
        localPlayer = nil
        selectedImage = nil
        selectedImageData = nil
        navigationPath.removeAll()
    }

    // MARK: - Timer

    private func startTimer(duration: Int) {
        timeRemaining = duration
        isTimerRunning = true

        timerCancellable = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self else { return }

                if self.timeRemaining > 0 {
                    self.timeRemaining -= 1

                    if self.timeRemaining <= 5 {
                        self.audioService.playSound(.tick)
                        self.audioService.playHaptic(.light)
                    }
                } else {
                    self.timerExpired()
                }
            }
    }

    private func stopTimer() {
        timerCancellable?.cancel()
        timerCancellable = nil
        isTimerRunning = false
    }

    private func timerExpired() {
        stopTimer()

        guard isHost else { return }

        switch game.phase {
        case .photoSelection:
            // Force transition even if not all submitted
            transitionToPhotoReveal()
        case .voting:
            // Force transition even if not all voted
            transitionToRoundResults()
        default:
            break
        }
    }

    // MARK: - Networking

    private func broadcastGameState() {
        multipeerService.sendGameState(game)
    }

    // MARK: - Image Selection

    func selectImage(_ image: UIImage) {
        selectedImage = image
        selectedImageData = image.compressed()
    }

    func clearSelectedImage() {
        selectedImage = nil
        selectedImageData = nil
    }

    // MARK: - Helpers

    func getPlayer(for submission: Submission) -> Player? {
        game.players.first { $0.id == submission.playerId }
    }

    func showError(message: String) {
        errorMessage = message
        showError = true
        audioService.playSound(.error)
        audioService.playHaptic(.error)
    }

    // MARK: - Settings

    func updateSettings(_ settings: GameSettings) {
        game.settings = settings
        if isHost {
            broadcastGameState()
        }
    }
}

// MARK: - MultipeerServiceDelegate

extension GameViewModel: MultipeerServiceDelegate {
    nonisolated func didReceiveGameState(_ game: Game) {
        Task { @MainActor in
            self.game = game
        }
    }

    nonisolated func didReceiveSubmission(_ submission: Submission) {
        Task { @MainActor in
            self.game.addSubmission(submission)
            if self.isHost {
                self.checkAllSubmissions()
            }
        }
    }

    nonisolated func didReceiveVote(from playerId: UUID, for submissionId: UUID) {
        Task { @MainActor in
            self.game.addVote(from: playerId, to: submissionId)
            if self.isHost {
                self.checkAllVotes()
            }
        }
    }

    nonisolated func playerDidConnect(_ player: Player) {
        Task { @MainActor in
            self.game.addPlayer(player)
            if self.isHost {
                self.broadcastGameState()
            }
        }
    }

    nonisolated func playerDidDisconnect(_ playerId: UUID) {
        Task { @MainActor in
            if let index = self.game.players.firstIndex(where: { $0.id == playerId }) {
                self.game.players[index].isConnected = false
            }
            if self.isHost {
                self.broadcastGameState()
            }
        }
    }

    nonisolated func didReceiveError(_ error: MultipeerError) {
        Task { @MainActor in
            switch error {
            case .notConnected:
                self.showError(message: "Not connected to the game")
            case .encodingFailed, .decodingFailed:
                self.showError(message: "Communication error")
            case .sessionFailed:
                self.showError(message: "Connection failed")
            case .timeout:
                self.showError(message: "Connection timed out")
            }
        }
    }
}

// MARK: - Navigation

enum GameScreen: Hashable {
    case lobby
    case game
    case joinGame
}
