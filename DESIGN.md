# PhotoParty - App Design Document

## Overview
PhotoParty is a multiplayer party game where players compete by finding photos from their camera roll that best match a given prompt. Think "Apples to Apples" but with personal photos instead of cards.

## Core Gameplay Loop
1. **Lobby Phase**: Host creates a game, players join via game code
2. **Prompt Phase**: All players see the same prompt (e.g., "Dying Laughing", "Most Embarrassing", "Peak Friendship")
3. **Selection Phase**: Players browse their camera roll and select a photo (timed - 60 seconds default)
4. **Reveal Phase**: All submitted photos are revealed one by one
5. **Voting Phase**: Players vote for the best photo (can't vote for own)
6. **Results Phase**: Points awarded, leaderboard updated
7. **Repeat** for configured number of rounds

## Technical Architecture

### Platform & Frameworks
- **iOS 17+** (Swift, SwiftUI)
- **Networking**: MultipeerConnectivity (local WiFi/Bluetooth) + Firebase for remote play
- **Photo Access**: PhotoKit (PHPickerViewController for privacy-friendly access)
- **Data Persistence**: SwiftData for local, Firestore for remote

### Screens
1. **HomeScreen** - Start/Join game options, settings
2. **LobbyScreen** - Game code display, player list, settings
3. **GameScreen** - Prompt display, photo picker, timer
4. **VotingScreen** - Photo carousel, voting UI
5. **ResultsScreen** - Round winner, scores, animations
6. **FinalResultsScreen** - Game winner, stats, play again

### Data Models

```swift
// Player
struct Player {
    let id: UUID
    var name: String
    var avatarEmoji: String
    var score: Int
    var isHost: Bool
    var isConnected: Bool
}

// Game
struct Game {
    let id: String // 6-character code
    var players: [Player]
    var currentRound: Int
    var totalRounds: Int
    var phase: GamePhase
    var currentPrompt: Prompt
    var submissions: [Submission]
    var settings: GameSettings
}

// Prompt
struct Prompt {
    let id: UUID
    let text: String
    let category: PromptCategory
}

// Submission
struct Submission {
    let playerId: UUID
    let imageData: Data
    let timestamp: Date
    var votes: Int
}

// GameSettings
struct GameSettings {
    var roundCount: Int = 5
    var selectionTimeLimit: Int = 60
    var votingTimeLimit: Int = 30
    var allowNSFW: Bool = false
}
```

### Game Phases (State Machine)
```
LOBBY → PROMPT_DISPLAY → PHOTO_SELECTION → SUBMISSION_WAIT →
PHOTO_REVEAL → VOTING → ROUND_RESULTS → (loop or) FINAL_RESULTS
```

### Networking Architecture

**Local Play (MultipeerConnectivity)**
- Host advertises game
- Players browse and connect
- Host manages game state, broadcasts to all
- Low latency, no internet required

**Remote Play (Firebase)**
- Firestore document per game
- Real-time listeners for state changes
- Cloud Storage for photo uploads
- Cloud Functions for game logic validation

### Photo Handling
- Use PHPickerViewController (iOS 14+) - no permission prompt needed
- Compress images before sending (max 500KB)
- Store temporarily during game, delete after
- No photos saved to server permanently (privacy)

### Prompt Categories
- Funny
- Embarrassing
- Wholesome
- Travel
- Food
- Pets
- Throwback
- Artistic
- Random

### Prompt Examples (150+ needed)
- "Dying Laughing"
- "Most Likely to Go Viral"
- "Peak Chaos Energy"
- "Friendship Goals"
- "Would NOT Show My Parents"
- "Main Character Moment"
- "Questionable Life Choices"
- "This Aged Well"
- "Accidental Renaissance"
- "Looks Illegal But Isn't"

## UI/UX Design Principles
- **Bold, playful colors** - Gradients, vibrant palette
- **Large touch targets** - Party game = drinks = clumsy fingers
- **Clear feedback** - Haptics, sounds, animations
- **Minimal text** - Icons and visuals where possible
- **Dark mode support**

## App Store Requirements
- Privacy policy (photo access explanation)
- Age rating: 12+ (user-generated content)
- Screenshots for all device sizes
- App Preview video
- Localization (start with English)

## MVP Feature Set (v1.0)
- [x] Local multiplayer (2-8 players)
- [x] 100+ prompts
- [x] Photo selection from camera roll
- [x] Voting system
- [x] Score tracking
- [x] Basic animations
- [x] Sound effects

## Future Features (v2.0+)
- Remote play via Firebase
- Custom prompts
- Photo filters/stickers
- Game history
- Achievements
- Share to social media
- AI-generated prompts

## File Structure
```
PhotoParty/
├── App/
│   ├── PhotoPartyApp.swift
│   └── ContentView.swift
├── Models/
│   ├── Player.swift
│   ├── Game.swift
│   ├── Prompt.swift
│   └── Submission.swift
├── ViewModels/
│   ├── GameViewModel.swift
│   ├── LobbyViewModel.swift
│   └── PhotoPickerViewModel.swift
├── Views/
│   ├── Home/
│   ├── Lobby/
│   ├── Game/
│   ├── Voting/
│   ├── Results/
│   └── Components/
├── Services/
│   ├── MultipeerService.swift
│   ├── GameStateManager.swift
│   ├── PromptService.swift
│   └── AudioService.swift
├── Resources/
│   ├── Prompts.json
│   ├── Sounds/
│   └── Assets.xcassets
└── Utilities/
    ├── Extensions.swift
    └── Constants.swift
```
