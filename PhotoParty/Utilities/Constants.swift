import SwiftUI

enum AppConstants {
    static let minPlayers = 2
    static let maxPlayers = 8

    static let defaultRounds = 5
    static let minRounds = 3
    static let maxRounds = 15

    static let defaultSelectionTime = 60
    static let minSelectionTime = 30
    static let maxSelectionTime = 120

    static let defaultVotingTime = 30
    static let minVotingTime = 15
    static let maxVotingTime = 60

    static let promptDisplayDuration: Double = 3.0
    static let photoRevealDuration: Double = 2.0
    static let resultsDisplayDuration: Double = 5.0

    static let maxImageSize: CGFloat = 1024
    static let imageCompressionQuality: CGFloat = 0.7
    static let maxImageDataSize = 500 * 1024 // 500KB

    static let gameCodeLength = 6
}

enum AppColors {
    static let primaryGradient = LinearGradient(
        colors: [Color(hex: "667eea"), Color(hex: "764ba2")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let secondaryGradient = LinearGradient(
        colors: [Color(hex: "f093fb"), Color(hex: "f5576c")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let successGradient = LinearGradient(
        colors: [Color(hex: "11998e"), Color(hex: "38ef7d")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let warningGradient = LinearGradient(
        colors: [Color(hex: "f7971e"), Color(hex: "ffd200")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let primary = Color(hex: "667eea")
    static let secondary = Color(hex: "764ba2")
    static let accent = Color(hex: "f093fb")
    static let success = Color(hex: "38ef7d")
    static let warning = Color(hex: "ffd200")
    static let error = Color(hex: "f5576c")

    static let backgroundDark = Color(hex: "1a1a2e")
    static let backgroundMedium = Color(hex: "16213e")
    static let backgroundLight = Color(hex: "0f3460")

    static let cardBackground = Color.white.opacity(0.1)
    static let cardBackgroundSolid = Color(hex: "2a2a4a")
}

enum AppFonts {
    static func title(_ size: CGFloat = 32) -> Font {
        .system(size: size, weight: .bold, design: .rounded)
    }

    static func heading(_ size: CGFloat = 24) -> Font {
        .system(size: size, weight: .semibold, design: .rounded)
    }

    static func body(_ size: CGFloat = 16) -> Font {
        .system(size: size, weight: .regular, design: .rounded)
    }

    static func caption(_ size: CGFloat = 12) -> Font {
        .system(size: size, weight: .medium, design: .rounded)
    }

    static func gameCode(_ size: CGFloat = 48) -> Font {
        .system(size: size, weight: .heavy, design: .monospaced)
    }
}
