import Foundation

struct GameSettings: Codable {
    var roundCount: Int
    var selectionTimeLimit: Int // seconds
    var votingTimeLimit: Int // seconds
    var categories: Set<PromptCategory>

    init(
        roundCount: Int = 5,
        selectionTimeLimit: Int = 60,
        votingTimeLimit: Int = 30,
        categories: Set<PromptCategory> = Set(PromptCategory.allCases)
    ) {
        self.roundCount = roundCount
        self.selectionTimeLimit = selectionTimeLimit
        self.votingTimeLimit = votingTimeLimit
        self.categories = categories
    }

    static let `default` = GameSettings()

    static let quick = GameSettings(
        roundCount: 3,
        selectionTimeLimit: 45,
        votingTimeLimit: 20
    )

    static let extended = GameSettings(
        roundCount: 10,
        selectionTimeLimit: 90,
        votingTimeLimit: 45
    )
}
