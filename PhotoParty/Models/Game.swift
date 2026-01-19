import Foundation

struct Game: Identifiable, Codable {
    let id: String // 6-character game code
    var players: [Player]
    var currentRound: Int
    var phase: GamePhase
    var currentPrompt: Prompt?
    var submissions: [Submission]
    var settings: GameSettings
    var usedPromptIds: Set<UUID>
    var roundWinners: [UUID] // Player IDs of round winners

    init(
        id: String = Game.generateGameCode(),
        players: [Player] = [],
        currentRound: Int = 0,
        phase: GamePhase = .lobby,
        currentPrompt: Prompt? = nil,
        submissions: [Submission] = [],
        settings: GameSettings = .default,
        usedPromptIds: Set<UUID> = [],
        roundWinners: [UUID] = []
    ) {
        self.id = id
        self.players = players
        self.currentRound = currentRound
        self.phase = phase
        self.currentPrompt = currentPrompt
        self.submissions = submissions
        self.settings = settings
        self.usedPromptIds = usedPromptIds
        self.roundWinners = roundWinners
    }

    static func generateGameCode() -> String {
        let characters = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789" // Removed confusing chars
        return String((0..<6).map { _ in characters.randomElement()! })
    }

    var host: Player? {
        players.first { $0.isHost }
    }

    var connectedPlayers: [Player] {
        players.filter { $0.isConnected }
    }

    var allPlayersSubmitted: Bool {
        let connectedIds = Set(connectedPlayers.map { $0.id })
        let submittedIds = Set(submissions.map { $0.playerId })
        return connectedIds.isSubset(of: submittedIds)
    }

    var allPlayersVoted: Bool {
        let connectedIds = connectedPlayers.map { $0.id }
        for playerId in connectedIds {
            // Check if this player has voted (appears in any submission's votes)
            // Players can't vote for themselves, so we check if they voted for others
            let hasVoted = submissions.contains { submission in
                submission.playerId != playerId && submission.votes.contains(playerId)
            }
            // If there's only one other submission, player must vote for it
            // If player hasn't voted and there are other submissions, return false
            let otherSubmissions = submissions.filter { $0.playerId != playerId }
            if !otherSubmissions.isEmpty && !hasVoted {
                return false
            }
        }
        return true
    }

    var leaderboard: [Player] {
        players.sorted { $0.score > $1.score }
    }

    var isLastRound: Bool {
        currentRound >= settings.roundCount
    }

    mutating func addPlayer(_ player: Player) {
        if !players.contains(where: { $0.id == player.id }) {
            players.append(player)
        }
    }

    mutating func removePlayer(_ playerId: UUID) {
        players.removeAll { $0.id == playerId }
    }

    mutating func updatePlayer(_ player: Player) {
        if let index = players.firstIndex(where: { $0.id == player.id }) {
            players[index] = player
        }
    }

    mutating func addSubmission(_ submission: Submission) {
        // Remove any existing submission from this player
        submissions.removeAll { $0.playerId == submission.playerId }
        submissions.append(submission)
    }

    mutating func addVote(from voterId: UUID, to submissionId: UUID) {
        if let index = submissions.firstIndex(where: { $0.id == submissionId }) {
            submissions[index].addVote(from: voterId)
        }
    }

    mutating func calculateRoundResults() -> Player? {
        // Find the submission with the most votes
        guard let winningSubmission = submissions.max(by: { $0.voteCount < $1.voteCount }),
              winningSubmission.voteCount > 0 else {
            return nil
        }

        // Award points
        let pointsPerVote = 100
        for submission in submissions {
            if let index = players.firstIndex(where: { $0.id == submission.playerId }) {
                players[index].score += submission.voteCount * pointsPerVote
            }
        }

        // Track round winner
        roundWinners.append(winningSubmission.playerId)

        return players.first { $0.id == winningSubmission.playerId }
    }

    mutating func resetForNextRound() {
        submissions.removeAll()
        for i in players.indices {
            players[i].hasSubmitted = false
            players[i].hasVoted = false
        }
    }

    mutating func resetGame() {
        currentRound = 0
        phase = .lobby
        currentPrompt = nil
        submissions.removeAll()
        usedPromptIds.removeAll()
        roundWinners.removeAll()
        for i in players.indices {
            players[i].score = 0
            players[i].hasSubmitted = false
            players[i].hasVoted = false
        }
    }
}

enum GamePhase: String, Codable {
    case lobby
    case promptDisplay
    case photoSelection
    case waitingForSubmissions
    case photoReveal
    case voting
    case roundResults
    case finalResults

    var displayName: String {
        switch self {
        case .lobby: return "Lobby"
        case .promptDisplay: return "Get Ready!"
        case .photoSelection: return "Pick Your Photo"
        case .waitingForSubmissions: return "Waiting..."
        case .photoReveal: return "Photo Reveal"
        case .voting: return "Vote!"
        case .roundResults: return "Results"
        case .finalResults: return "Game Over"
        }
    }
}

extension Game {
    static let preview = Game(
        players: Player.previewPlayers,
        currentRound: 1,
        phase: .lobby,
        currentPrompt: Prompt.preview
    )
}
