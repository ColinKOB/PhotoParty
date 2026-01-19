import SwiftUI
import UIKit

// MARK: - Color Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - View Extensions

extension View {
    func cardStyle() -> some View {
        self
            .background(AppColors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
    }

    func primaryButtonStyle() -> some View {
        self
            .font(AppFonts.heading(18))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(AppColors.primaryGradient)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: AppColors.primary.opacity(0.4), radius: 8, y: 4)
    }

    func secondaryButtonStyle() -> some View {
        self
            .font(AppFonts.heading(18))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.white.opacity(0.15))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
            )
    }

    func shake(_ shake: Bool) -> some View {
        self.modifier(ShakeEffect(shake: shake))
    }

    func bounceOnTap() -> some View {
        self.modifier(BounceModifier())
    }
}

// MARK: - Animation Modifiers

struct ShakeEffect: ViewModifier {
    var shake: Bool

    func body(content: Content) -> some View {
        content
            .offset(x: shake ? -5 : 0)
            .animation(
                shake ?
                    Animation.easeInOut(duration: 0.1).repeatCount(3) :
                    .default,
                value: shake
            )
    }
}

struct BounceModifier: ViewModifier {
    @State private var isPressed = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in isPressed = true }
                    .onEnded { _ in isPressed = false }
            )
    }
}

// MARK: - Image Compression

extension UIImage {
    func compressed(maxSize: CGFloat = AppConstants.maxImageSize, quality: CGFloat = AppConstants.imageCompressionQuality) -> Data? {
        let ratio = min(maxSize / size.width, maxSize / size.height)
        let newSize = CGSize(
            width: size.width * min(ratio, 1),
            height: size.height * min(ratio, 1)
        )

        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        draw(in: CGRect(origin: .zero, size: newSize))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        guard let image = resizedImage else { return nil }

        var compressionQuality = quality
        var imageData = image.jpegData(compressionQuality: compressionQuality)

        // Reduce quality until under max size
        while let data = imageData,
              data.count > AppConstants.maxImageDataSize,
              compressionQuality > 0.1 {
            compressionQuality -= 0.1
            imageData = image.jpegData(compressionQuality: compressionQuality)
        }

        return imageData
    }
}

// MARK: - Data to Image

extension Data {
    var asUIImage: UIImage? {
        UIImage(data: self)
    }
}

// MARK: - String Extensions

extension String {
    var isValidGameCode: Bool {
        count == AppConstants.gameCodeLength &&
        allSatisfy { $0.isLetter || $0.isNumber }
    }
}

// MARK: - Date Extensions

extension Date {
    var timeAgoString: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: self, relativeTo: Date())
    }
}

// MARK: - Array Extensions

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}
