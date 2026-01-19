import Foundation
import AVFoundation

class AudioService {
    static let shared = AudioService()

    private var audioPlayers: [String: AVAudioPlayer] = [:]
    private var isMuted: Bool = false

    private init() {
        setupAudioSession()
    }

    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to setup audio session: \(error)")
        }
    }

    func playSound(_ sound: GameSound) {
        guard !isMuted else { return }

        // Use system sounds for MVP (no custom audio files needed)
        let systemSoundID: SystemSoundID

        switch sound {
        case .countdown:
            systemSoundID = 1057 // Tock
        case .submit:
            systemSoundID = 1004 // Mail sent
        case .vote:
            systemSoundID = 1306 // Begin recording
        case .reveal:
            systemSoundID = 1315 // Shake
        case .roundEnd:
            systemSoundID = 1025 // New mail
        case .gameEnd:
            systemSoundID = 1023 // Fanfare
        case .playerJoin:
            systemSoundID = 1003 // Received message
        case .playerLeave:
            systemSoundID = 1006 // Voicemail
        case .tick:
            systemSoundID = 1103 // Tink
        case .error:
            systemSoundID = 1053 // Negative
        case .success:
            systemSoundID = 1054 // Positive
        }

        AudioServicesPlaySystemSound(systemSoundID)
    }

    func playHaptic(_ type: HapticType) {
        switch type {
        case .light:
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
        case .medium:
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
        case .heavy:
            let generator = UIImpactFeedbackGenerator(style: .heavy)
            generator.impactOccurred()
        case .success:
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
        case .warning:
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.warning)
        case .error:
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.error)
        case .selection:
            let generator = UISelectionFeedbackGenerator()
            generator.selectionChanged()
        }
    }

    func toggleMute() {
        isMuted.toggle()
    }

    func setMuted(_ muted: Bool) {
        isMuted = muted
    }

    var muted: Bool {
        isMuted
    }
}

enum GameSound {
    case countdown
    case submit
    case vote
    case reveal
    case roundEnd
    case gameEnd
    case playerJoin
    case playerLeave
    case tick
    case error
    case success
}

enum HapticType {
    case light
    case medium
    case heavy
    case success
    case warning
    case error
    case selection
}
