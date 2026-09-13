import SwiftUI

/// Central design system. Everything here is original (own color values,
/// own naming) — deliberately not copying any brand's exact hex codes or
/// asset files, just the general "dark, high-contrast, card-based" language
/// common to modern streaming apps.
enum Theme {
    enum Color {
        static let background = SwiftUI.Color(red: 0.043, green: 0.043, blue: 0.043)     // near-black
        static let surface = SwiftUI.Color(red: 0.11, green: 0.11, blue: 0.11)
        static let surfaceElevated = SwiftUI.Color(red: 0.16, green: 0.16, blue: 0.16)
        static let accent = SwiftUI.Color(red: 0.11, green: 0.84, blue: 0.38)             // brand-neutral green
        static let accentSecondary = SwiftUI.Color(red: 0.35, green: 0.55, blue: 1.0)
        static let textPrimary = SwiftUI.Color.white
        static let textSecondary = SwiftUI.Color(white: 0.7)
        static let textTertiary = SwiftUI.Color(white: 0.5)
        static let divider = SwiftUI.Color(white: 1.0).opacity(0.08)

        static let cardGradient = LinearGradient(
            colors: [SwiftUI.Color.black.opacity(0.0), SwiftUI.Color.black.opacity(0.55)],
            startPoint: .top, endPoint: .bottom
        )
    }

    enum Font {
        static func title() -> SwiftUI.Font { .system(size: 28, weight: .bold, design: .rounded) }
        static func heading() -> SwiftUI.Font { .system(size: 20, weight: .bold) }
        static func subheading() -> SwiftUI.Font { .system(size: 16, weight: .semibold) }
        static func body() -> SwiftUI.Font { .system(size: 14, weight: .regular) }
        static func caption() -> SwiftUI.Font { .system(size: 12, weight: .medium) }
    }

    enum Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
    }

    enum Radius {
        static let card: CGFloat = 12
        static let pill: CGFloat = 999
        static let sheet: CGFloat = 24
    }

    enum Animation {
        static let spring = SwiftUI.Animation.spring(response: 0.45, dampingFraction: 0.82)
        static let quickSpring = SwiftUI.Animation.spring(response: 0.28, dampingFraction: 0.86)
        static let easeFast = SwiftUI.Animation.easeInOut(duration: 0.18)
    }

    /// Light, tasteful haptics used throughout the app.
    enum Haptics {
        static func light() {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
        }
        static func medium() {
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
        }
        static func selection() {
            UISelectionFeedbackGenerator().selectionChanged()
        }
    }
}

/// Reusable button style with a soft scale-down press animation, used for
/// nearly every tappable element to give the app a "premium" tactile feel.
struct PressableStyle: ButtonStyle {
    var scale: CGFloat = 0.96
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1)
            .animation(Theme.Animation.quickSpring, value: configuration.isPressed)
    }
}
