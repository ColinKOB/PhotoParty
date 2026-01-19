import Foundation

class PromptService {
    static let shared = PromptService()

    private var prompts: [Prompt] = []

    private init() {
        loadPrompts()
    }

    private func loadPrompts() {
        guard let url = Bundle.main.url(forResource: "Prompts", withExtension: "json"),
              let data = try? Data(contentsOf: url) else {
            print("Failed to load Prompts.json")
            loadFallbackPrompts()
            return
        }

        do {
            let decoder = JSONDecoder()
            let response = try decoder.decode(PromptResponse.self, from: data)
            prompts = response.prompts.map { item in
                Prompt(
                    text: item.text,
                    category: PromptCategory(rawValue: item.category.capitalized) ?? .random
                )
            }
            print("Loaded \(prompts.count) prompts")
        } catch {
            print("Failed to decode prompts: \(error)")
            loadFallbackPrompts()
        }
    }

    private func loadFallbackPrompts() {
        prompts = [
            Prompt(text: "Dying Laughing", category: .funny),
            Prompt(text: "Questionable Life Choices", category: .embarrassing),
            Prompt(text: "Friendship Goals", category: .wholesome),
            Prompt(text: "Best Travel Photo", category: .travel),
            Prompt(text: "Food Porn", category: .food),
            Prompt(text: "Pet Perfection", category: .pets),
            Prompt(text: "Throwback Thursday", category: .throwback),
            Prompt(text: "Accidental Renaissance", category: .artistic),
            Prompt(text: "Peak Chaos Energy", category: .chaotic),
            Prompt(text: "Most Random Photo", category: .random)
        ]
    }

    func getRandomPrompt(excluding usedIds: Set<UUID>, categories: Set<PromptCategory>? = nil) -> Prompt? {
        var availablePrompts = prompts.filter { !usedIds.contains($0.id) }

        if let categories = categories, !categories.isEmpty {
            availablePrompts = availablePrompts.filter { categories.contains($0.category) }
        }

        return availablePrompts.randomElement()
    }

    func getPrompts(for category: PromptCategory) -> [Prompt] {
        prompts.filter { $0.category == category }
    }

    func getAllPrompts() -> [Prompt] {
        prompts
    }

    func getPromptCount() -> Int {
        prompts.count
    }
}

private struct PromptResponse: Codable {
    let prompts: [PromptItem]
}

private struct PromptItem: Codable {
    let text: String
    let category: String
}
