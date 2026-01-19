import Foundation

struct Player: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var avatarEmoji: String
    var score: Int
    var isHost: Bool
    var isConnected: Bool
    var hasSubmitted: Bool
    var hasVoted: Bool

    init(
        id: UUID = UUID(),
        name: String,
        avatarEmoji: String = Player.randomEmoji(),
        score: Int = 0,
        isHost: Bool = false,
        isConnected: Bool = true,
        hasSubmitted: Bool = false,
        hasVoted: Bool = false
    ) {
        self.id = id
        self.name = name
        self.avatarEmoji = avatarEmoji
        self.score = score
        self.isHost = isHost
        self.isConnected = isConnected
        self.hasSubmitted = hasSubmitted
        self.hasVoted = hasVoted
    }

    static func randomEmoji() -> String {
        let emojis = [
            "😀", "😎", "🤩", "😈", "👻", "🤖", "👽", "🎃",
            "🦄", "🐶", "🐱", "🦊", "🐸", "🐵", "🐷", "🐻",
            "🦁", "🐯", "🐨", "🐼", "🐔", "🦆", "🦉", "🐙",
            "🦋", "🐝", "🌸", "🌺", "🔥", "⭐", "🌈", "💎"
        ]
        return emojis.randomElement() ?? "😀"
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: Player, rhs: Player) -> Bool {
        lhs.id == rhs.id
    }
}

extension Player {
    static let preview = Player(name: "Player 1", isHost: true)
    static let previewPlayers = [
        Player(name: "Alice", avatarEmoji: "😎", score: 150, isHost: true),
        Player(name: "Bob", avatarEmoji: "🤖", score: 120),
        Player(name: "Charlie", avatarEmoji: "🦊", score: 90),
        Player(name: "Diana", avatarEmoji: "🌸", score: 80)
    ]
}
