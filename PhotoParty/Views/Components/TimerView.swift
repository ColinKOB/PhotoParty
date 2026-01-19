import SwiftUI

struct TimerView: View {
    let timeRemaining: Int
    let totalTime: Int?

    init(timeRemaining: Int, totalTime: Int? = nil) {
        self.timeRemaining = timeRemaining
        self.totalTime = totalTime
    }

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "clock.fill")
                .font(.system(size: 14))
                .foregroundColor(timerColor)

            Text(formattedTime)
                .font(AppFonts.heading(18))
                .foregroundColor(timerColor)
                .monospacedDigit()
                .contentTransition(.numericText())
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(timerColor.opacity(0.2))
        .clipShape(Capsule())
        .animation(.easeInOut(duration: 0.3), value: timeRemaining)
    }

    var formattedTime: String {
        let minutes = timeRemaining / 60
        let seconds = timeRemaining % 60

        if minutes > 0 {
            return String(format: "%d:%02d", minutes, seconds)
        } else {
            return "\(seconds)"
        }
    }

    var timerColor: Color {
        if timeRemaining <= 5 {
            return AppColors.error
        } else if timeRemaining <= 15 {
            return AppColors.warning
        } else {
            return .white
        }
    }
}

struct CircularTimerView: View {
    let timeRemaining: Int
    let totalTime: Int

    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .stroke(Color.white.opacity(0.2), lineWidth: 8)

            // Progress circle
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    timerColor,
                    style: StrokeStyle(lineWidth: 8, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 1), value: timeRemaining)

            // Time text
            VStack(spacing: 2) {
                Text("\(timeRemaining)")
                    .font(AppFonts.title(32))
                    .foregroundColor(timerColor)
                    .monospacedDigit()
                    .contentTransition(.numericText())

                Text("sec")
                    .font(AppFonts.caption())
                    .foregroundColor(.white.opacity(0.5))
            }
        }
        .frame(width: 100, height: 100)
    }

    var progress: CGFloat {
        guard totalTime > 0 else { return 0 }
        return CGFloat(timeRemaining) / CGFloat(totalTime)
    }

    var timerColor: Color {
        if timeRemaining <= 5 {
            return AppColors.error
        } else if timeRemaining <= 15 {
            return AppColors.warning
        } else {
            return AppColors.success
        }
    }
}

struct CountdownTimerView: View {
    @Binding var count: Int
    let onComplete: () -> Void

    @State private var scale: CGFloat = 1.0
    @State private var opacity: Double = 1.0

    var body: some View {
        ZStack {
            // Background blur
            Color.black.opacity(0.7)
                .ignoresSafeArea()

            // Countdown number
            Text("\(count)")
                .font(.system(size: 150, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .scaleEffect(scale)
                .opacity(opacity)
        }
        .onAppear {
            startCountdown()
        }
    }

    private func startCountdown() {
        animateNumber()
    }

    private func animateNumber() {
        // Reset
        scale = 2.0
        opacity = 0

        // Animate in
        withAnimation(.easeOut(duration: 0.3)) {
            scale = 1.0
            opacity = 1.0
        }

        // Animate out after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
            withAnimation(.easeIn(duration: 0.2)) {
                scale = 0.5
                opacity = 0
            }
        }

        // Next number or complete
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            if count > 1 {
                count -= 1
                animateNumber()
            } else {
                onComplete()
            }
        }

        // Play sound
        AudioService.shared.playSound(.countdown)
        AudioService.shared.playHaptic(.medium)
    }
}

#Preview {
    VStack(spacing: 40) {
        TimerView(timeRemaining: 45)
        TimerView(timeRemaining: 10)
        TimerView(timeRemaining: 3)

        CircularTimerView(timeRemaining: 45, totalTime: 60)
        CircularTimerView(timeRemaining: 10, totalTime: 60)
    }
    .padding()
    .background(AppColors.backgroundDark)
}
