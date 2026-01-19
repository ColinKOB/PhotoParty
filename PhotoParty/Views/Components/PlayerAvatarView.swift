import SwiftUI

struct PlayerAvatarView: View {
    let player: Player
    let size: AvatarSize
    let showName: Bool
    let showStatus: Bool

    enum AvatarSize {
        case small, medium, large

        var dimension: CGFloat {
            switch self {
            case .small: return 40
            case .medium: return 60
            case .large: return 80
            }
        }

        var fontSize: CGFloat {
            switch self {
            case .small: return 20
            case .medium: return 32
            case .large: return 44
            }
        }

        var nameFontSize: CGFloat {
            switch self {
            case .small: return 10
            case .medium: return 14
            case .large: return 16
            }
        }
    }

    init(player: Player, size: AvatarSize = .medium, showName: Bool = true, showStatus: Bool = false) {
        self.player = player
        self.size = size
        self.showName = showName
        self.showStatus = showStatus
    }

    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                // Background circle
                Circle()
                    .fill(player.isConnected ? AppColors.primaryGradient : LinearGradient(colors: [Color.gray], startPoint: .top, endPoint: .bottom))
                    .frame(width: size.dimension, height: size.dimension)

                // Emoji
                Text(player.avatarEmoji)
                    .font(.system(size: size.fontSize))

                // Host crown
                if player.isHost {
                    Image(systemName: "crown.fill")
                        .font(.system(size: size.dimension * 0.2))
                        .foregroundColor(.yellow)
                        .offset(x: size.dimension * 0.35, y: -size.dimension * 0.35)
                }

                // Connection status
                if showStatus {
                    Circle()
                        .fill(player.isConnected ? Color.green : Color.red)
                        .frame(width: size.dimension * 0.25, height: size.dimension * 0.25)
                        .overlay(
                            Circle()
                                .stroke(Color.white, lineWidth: 2)
                        )
                        .offset(x: size.dimension * 0.35, y: size.dimension * 0.35)
                }

                // Submitted/voted indicator
                if player.hasSubmitted || player.hasVoted {
                    Circle()
                        .fill(AppColors.success)
                        .frame(width: size.dimension * 0.3, height: size.dimension * 0.3)
                        .overlay(
                            Image(systemName: "checkmark")
                                .font(.system(size: size.dimension * 0.15, weight: .bold))
                                .foregroundColor(.white)
                        )
                        .offset(x: size.dimension * 0.35, y: size.dimension * 0.35)
                }
            }

            if showName {
                Text(player.name)
                    .font(AppFonts.body(size.nameFontSize))
                    .foregroundColor(.white)
                    .lineLimit(1)
            }
        }
    }
}

struct PlayerAvatarRow: View {
    let players: [Player]
    let size: PlayerAvatarView.AvatarSize
    let showNames: Bool
    let spacing: CGFloat

    init(players: [Player], size: PlayerAvatarView.AvatarSize = .small, showNames: Bool = false, spacing: CGFloat = 8) {
        self.players = players
        self.size = size
        self.showNames = showNames
        self.spacing = spacing
    }

    var body: some View {
        HStack(spacing: spacing) {
            ForEach(players) { player in
                PlayerAvatarView(player: player, size: size, showName: showNames)
            }
        }
    }
}

struct PlayerScoreView: View {
    let player: Player
    let rank: Int?
    let isHighlighted: Bool

    var body: some View {
        HStack(spacing: 12) {
            if let rank = rank {
                Text("\(rank)")
                    .font(AppFonts.heading(18))
                    .foregroundColor(rankColor)
                    .frame(width: 30)
            }

            PlayerAvatarView(player: player, size: .small, showName: false)

            VStack(alignment: .leading, spacing: 2) {
                Text(player.name)
                    .font(AppFonts.body())
                    .foregroundColor(.white)

                if player.isHost {
                    Text("Host")
                        .font(AppFonts.caption(10))
                        .foregroundColor(.white.opacity(0.5))
                }
            }

            Spacer()

            Text("\(player.score)")
                .font(AppFonts.heading(20))
                .foregroundColor(.white)
        }
        .padding(12)
        .background(isHighlighted ? AppColors.primary.opacity(0.2) : Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    var rankColor: Color {
        switch rank {
        case 1: return .yellow
        case 2: return .gray
        case 3: return Color(hex: "CD7F32")
        default: return .white.opacity(0.5)
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        PlayerAvatarView(player: .preview, size: .large)
        PlayerAvatarView(player: .preview, size: .medium)
        PlayerAvatarView(player: .preview, size: .small)
        PlayerAvatarRow(players: Player.previewPlayers)
        PlayerScoreView(player: .preview, rank: 1, isHighlighted: true)
    }
    .padding()
    .background(AppColors.backgroundDark)
}
