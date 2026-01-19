import Foundation

struct Prompt: Identifiable, Codable, Hashable {
    let id: UUID
    let text: String
    let category: PromptCategory

    init(id: UUID = UUID(), text: String, category: PromptCategory = .random) {
        self.id = id
        self.text = text
        self.category = category
    }
}

enum PromptCategory: String, Codable, CaseIterable {
    case funny = "Funny"
    case embarrassing = "Embarrassing"
    case wholesome = "Wholesome"
    case travel = "Travel"
    case food = "Food"
    case pets = "Pets"
    case throwback = "Throwback"
    case artistic = "Artistic"
    case chaotic = "Chaotic"
    case random = "Random"

    var icon: String {
        switch self {
        case .funny: return "😂"
        case .embarrassing: return "🙈"
        case .wholesome: return "🥰"
        case .travel: return "✈️"
        case .food: return "🍕"
        case .pets: return "🐾"
        case .throwback: return "📼"
        case .artistic: return "🎨"
        case .chaotic: return "🔥"
        case .random: return "🎲"
        }
    }
}

extension Prompt {
    static let preview = Prompt(text: "Dying Laughing", category: .funny)
}
