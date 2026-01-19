# PhotoParty

A multiplayer party game for iOS where players compete by finding the best photos from their camera roll to match fun prompts.

## Overview

PhotoParty is like "Apples to Apples" but with personal photos! Players are given prompts like "Dying Laughing" or "Peak Chaos Energy" and must search their camera roll to find the perfect photo. Everyone votes on the best submission, and points are awarded to the winners.

## Features

- **Local Multiplayer**: 2-8 players can play together on the same WiFi network or Bluetooth
- **150+ Prompts**: Hilarious prompts across 10 categories (Funny, Embarrassing, Wholesome, Travel, Food, Pets, Throwback, Artistic, Chaotic, Random)
- **Privacy-Focused**: Photos are only shared temporarily during gameplay and never stored on servers
- **Beautiful UI**: Dark mode design with smooth animations and haptic feedback
- **Customizable Settings**: Adjust round count, timer durations, and prompt categories

## How to Play

1. **Create or Join**: One player creates a game and shares the 6-character code. Others join using the code.
2. **Get the Prompt**: Everyone sees the same prompt (e.g., "Questionable Life Choices")
3. **Pick Your Photo**: You have 60 seconds to find the perfect photo from your camera roll
4. **Vote**: After everyone submits, players vote on their favorite (you can't vote for yourself!)
5. **Score**: The player with the most votes wins the round and earns points
6. **Repeat**: Play 5 rounds (configurable) and crown the ultimate winner!

## Requirements

- iOS 17.0+
- iPhone or iPad
- Xcode 15.0+ (for building)

## Installation

### From Source

1. Clone the repository:
```bash
git clone https://github.com/yourusername/PhotoParty.git
cd PhotoParty
```

2. Open the project in Xcode:
```bash
open PhotoParty.xcodeproj
```

3. Select your target device or simulator

4. Build and run (Cmd + R)

### From TestFlight

Coming soon!

## Project Structure

```
PhotoParty/
├── App/
│   ├── PhotoPartyApp.swift      # App entry point
│   └── ContentView.swift        # Root navigation
├── Models/
│   ├── Player.swift             # Player data model
│   ├── Game.swift               # Game state and logic
│   ├── Prompt.swift             # Prompt data model
│   ├── Submission.swift         # Photo submission model
│   └── GameSettings.swift       # Configurable settings
├── ViewModels/
│   └── GameViewModel.swift      # Main game logic and state
├── Views/
│   ├── HomeView.swift           # Home screen
│   ├── JoinGameView.swift       # Join game screen
│   ├── LobbyView.swift          # Game lobby
│   ├── GameView.swift           # Main game screen
│   ├── PhotoPickerView.swift    # Photo selection
│   ├── PhotoRevealView.swift    # Photo reveal animation
│   ├── VotingView.swift         # Voting screen
│   ├── ResultsView.swift        # Round results
│   ├── FinalResultsView.swift   # Game winner screen
│   └── Components/              # Reusable UI components
├── Services/
│   ├── MultipeerService.swift   # Local networking
│   ├── PromptService.swift      # Prompt management
│   └── AudioService.swift       # Sound and haptics
├── Utilities/
│   ├── Constants.swift          # App constants and colors
│   └── Extensions.swift         # Swift extensions
└── Resources/
    ├── Assets.xcassets          # App icons and colors
    └── Prompts.json             # Prompt database
```

## Technical Details

### Networking

PhotoParty uses Apple's MultipeerConnectivity framework for local multiplayer:
- Host advertises the game on the local network
- Players discover and join nearby games
- Game state is synchronized across all devices
- Photos are compressed and sent peer-to-peer

### Photo Handling

- Uses `PHPickerViewController` for privacy-friendly photo access
- Images are compressed to max 500KB before transmission
- Photos are only held in memory during gameplay
- No photos are ever uploaded to external servers

### Game State Machine

```
LOBBY → PROMPT_DISPLAY → PHOTO_SELECTION → WAITING_FOR_SUBMISSIONS →
PHOTO_REVEAL → VOTING → ROUND_RESULTS → (loop or) FINAL_RESULTS
```

## Permissions Required

- **Photo Library**: To select photos for submission
- **Local Network**: To connect with nearby players

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- Inspired by "Apples to Apples" and "Cards Against Humanity"
- Built with SwiftUI and MultipeerConnectivity
- Sound effects use iOS system sounds

## Contact

For questions or feedback, please open an issue on GitHub.
