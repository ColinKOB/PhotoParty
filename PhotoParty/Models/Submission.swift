import Foundation

struct Submission: Identifiable, Codable {
    let id: UUID
    let playerId: UUID
    let imageData: Data
    let timestamp: Date
    var votes: [UUID] // Player IDs who voted for this

    init(
        id: UUID = UUID(),
        playerId: UUID,
        imageData: Data,
        timestamp: Date = Date(),
        votes: [UUID] = []
    ) {
        self.id = id
        self.playerId = playerId
        self.imageData = imageData
        self.timestamp = timestamp
        self.votes = votes
    }

    var voteCount: Int {
        votes.count
    }

    mutating func addVote(from playerId: UUID) {
        if !votes.contains(playerId) {
            votes.append(playerId)
        }
    }
}

extension Submission {
    static var preview: Submission {
        Submission(
            playerId: UUID(),
            imageData: Data()
        )
    }
}
