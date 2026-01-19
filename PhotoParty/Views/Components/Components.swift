import SwiftUI

struct GradientButton: View {
    let title: String
    let icon: String?
    let gradient: LinearGradient
    let action: () -> Void

    init(
        _ title: String,
        icon: String? = nil,
        gradient: LinearGradient = AppColors.primaryGradient,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.gradient = gradient
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let icon = icon {
                    Image(systemName: icon)
                }
                Text(title)
            }
            .font(AppFonts.heading(18))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(gradient)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: AppColors.primary.opacity(0.4), radius: 8, y: 4)
        }
        .bounceOnTap()
    }
}

struct OutlineButton: View {
    let title: String
    let icon: String?
    let action: () -> Void

    init(_ title: String, icon: String? = nil, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let icon = icon {
                    Image(systemName: icon)
                }
                Text(title)
            }
            .font(AppFonts.heading(18))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.white.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
            )
        }
        .bounceOnTap()
    }
}

struct PulsatingView<Content: View>: View {
    let content: Content
    @State private var isPulsating = false

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .scaleEffect(isPulsating ? 1.05 : 1.0)
            .opacity(isPulsating ? 0.8 : 1.0)
            .animation(
                Animation.easeInOut(duration: 1.0)
                    .repeatForever(autoreverses: true),
                value: isPulsating
            )
            .onAppear {
                isPulsating = true
            }
    }
}

struct LoadingView: View {
    let message: String

    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(.white)

            Text(message)
                .font(AppFonts.body())
                .foregroundColor(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColors.backgroundDark)
    }
}

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 60))
                .foregroundColor(.white.opacity(0.3))

            Text(title)
                .font(AppFonts.heading(20))
                .foregroundColor(.white)

            Text(message)
                .font(AppFonts.body())
                .foregroundColor(.white.opacity(0.5))
                .multilineTextAlignment(.center)
        }
        .padding(32)
    }
}

struct CountdownOverlay: View {
    let count: Int
    @State private var scale: CGFloat = 2.0
    @State private var opacity: Double = 0

    var body: some View {
        ZStack {
            Color.black.opacity(0.7)
                .ignoresSafeArea()

            Text("\(count)")
                .font(.system(size: 120, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .scaleEffect(scale)
                .opacity(opacity)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) {
                scale = 1.0
                opacity = 1.0
            }

            withAnimation(.easeIn(duration: 0.3).delay(0.7)) {
                opacity = 0
            }
        }
    }
}

struct ConfettiView: View {
    @State private var particles: [ConfettiParticle] = []

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(particles) { particle in
                    Circle()
                        .fill(particle.color)
                        .frame(width: particle.size, height: particle.size)
                        .position(particle.position)
                        .opacity(particle.opacity)
                }
            }
            .onAppear {
                createParticles(in: geometry.size)
            }
        }
        .allowsHitTesting(false)
    }

    private func createParticles(in size: CGSize) {
        let colors: [Color] = [.red, .yellow, .green, .blue, .purple, .orange, .pink]

        for _ in 0..<50 {
            let particle = ConfettiParticle(
                position: CGPoint(x: CGFloat.random(in: 0...size.width), y: -20),
                color: colors.randomElement()!,
                size: CGFloat.random(in: 5...15)
            )
            particles.append(particle)
        }

        // Animate particles falling
        for i in particles.indices {
            let duration = Double.random(in: 2...4)
            let delay = Double.random(in: 0...1)

            withAnimation(.easeIn(duration: duration).delay(delay)) {
                particles[i].position.y = size.height + 50
                particles[i].position.x += CGFloat.random(in: -100...100)
                particles[i].opacity = 0
            }
        }
    }
}

struct ConfettiParticle: Identifiable {
    let id = UUID()
    var position: CGPoint
    let color: Color
    let size: CGFloat
    var opacity: Double = 1.0
}
