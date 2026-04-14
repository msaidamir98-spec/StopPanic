import SwiftUI

// MARK: - SP

// Вдохновлено Calm, Headspace, Rootd — но уникально.
// Тёплые тёмные тона + мягкий неон = безопасность + технология.
//
// ⚡️ Все цвета — ДИНАМИЧЕСКИЕ. Делегируют в ThemeManager.shared.
// Это значит, что все 470+ ссылок SP.Colors.* во всех экранах
// автоматически переключаются при смене темы — без единого изменения в UI-коде.

enum SP {
    // MARK: - Color Palette (dynamic → ThemeManager.shared)

    @MainActor
    enum Colors {
        /// Backgrounds
        static var bg: Color {
            ThemeManager.shared.bg
        }

        static var bgSoft: Color {
            ThemeManager.shared.bgSoft
        }

        static var bgCard: Color {
            ThemeManager.shared.bgCard
        }

        static var bgCardHover: Color {
            ThemeManager.shared.bgCardHover
        }

        static var bgElevated: Color {
            ThemeManager.shared.bgElevated
        }

        /// Accent
        static var accent: Color {
            ThemeManager.shared.accent
        }

        static var accentSoft: Color {
            ThemeManager.shared.accentSoft
        }

        static var accentGlow: Color {
            ThemeManager.shared.accentGlow
        }

        /// Semantic
        static var calm: Color {
            ThemeManager.shared.calm
        }

        static var calmSoft: Color {
            ThemeManager.shared.calmSoft
        }

        static var warmth: Color {
            ThemeManager.shared.warmth
        }

        static var danger: Color {
            ThemeManager.shared.danger
        }

        static var dangerGlow: Color {
            ThemeManager.shared.dangerGlow
        }

        static var success: Color {
            ThemeManager.shared.success
        }

        static var warning: Color {
            ThemeManager.shared.warning
        }

        /// Text
        static var textPrimary: Color {
            ThemeManager.shared.textPrimary
        }

        static var textSecondary: Color {
            ThemeManager.shared.textSecondary
        }

        static var textTertiary: Color {
            ThemeManager.shared.textTertiary
        }

        static var textOnAccent: Color {
            ThemeManager.shared.textOnAccent
        }

        /// Gradients
        static var heroGradient: LinearGradient {
            ThemeManager.shared.heroGradient
        }

        static var sosGradient: LinearGradient {
            ThemeManager.shared.sosGradient
        }

        static var calmGradient: LinearGradient {
            ThemeManager.shared.calmGradient
        }

        static var warmGradient: LinearGradient {
            ThemeManager.shared.warmGradient
        }

        static var bgGradient: LinearGradient {
            ThemeManager.shared.bgGradient
        }

        static var shimmerGradient: LinearGradient {
            ThemeManager.shared.shimmerGradient
        }
    }

    // MARK: - Typography

    enum Typography {
        static let heroTitle = Font.system(size: 34, weight: .bold, design: .rounded)
        static let title1 = Font.system(size: 28, weight: .bold, design: .rounded)
        static let title2 = Font.system(size: 22, weight: .semibold, design: .rounded)
        static let title3 = Font.system(size: 20, weight: .semibold, design: .rounded)
        static let headline = Font.system(size: 17, weight: .semibold, design: .rounded)
        static let body = Font.system(size: 16, weight: .regular, design: .rounded)
        static let callout = Font.system(size: 15, weight: .regular, design: .rounded)
        static let subheadline = Font.system(size: 14, weight: .regular, design: .rounded)
        static let footnote = Font.system(size: 13, weight: .regular, design: .rounded)
        static let caption = Font.system(size: 12, weight: .medium, design: .rounded)
        static let caption2 = Font.system(size: 11, weight: .regular, design: .rounded)

        // Special
        static let sosButton = Font.system(size: 52, weight: .black, design: .rounded)
        static let bigNumber = Font.system(size: 48, weight: .bold, design: .rounded)
        static let breathPhase = Font.system(size: 28, weight: .medium, design: .rounded)
    }

    // MARK: - Spacing & Layout

    enum Layout {
        static let padding: CGFloat = 20
        static let paddingSmall: CGFloat = 12
        static let paddingTiny: CGFloat = 8
        static let cardPadding: CGFloat = 18

        static let cornerLarge: CGFloat = 28
        static let cornerMedium: CGFloat = 20
        static let cornerSmall: CGFloat = 14
        static let cornerTiny: CGFloat = 10

        static let spacing: CGFloat = 16
        static let spacingSmall: CGFloat = 10
        static let spacingTiny: CGFloat = 6

        static let sosButtonSize: CGFloat = 200
        static let breathCircleSize: CGFloat = 220
    }

    // MARK: - Shadows (dynamic)

    @MainActor
    enum Shadows {
        static var soft: Color {
            ThemeManager.shared.shadowSoft
        }

        static var medium: Color {
            ThemeManager.shared.shadowMedium
        }

        static var glow: Color {
            Colors.accent.opacity(0.4)
        }

        static var dangerGlow: Color {
            Colors.danger.opacity(0.5)
        }

        static var calmGlow: Color {
            Colors.calm.opacity(0.4)
        }
    }

    // MARK: - Haptics

    enum Haptic {
        static func light() {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }

        static func medium() {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        }

        static func heavy() {
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        }

        static func soft() {
            UIImpactFeedbackGenerator(style: .soft).impactOccurred()
        }

        static func rigid() {
            UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
        }

        static func success() {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }

        static func warning() {
            UINotificationFeedbackGenerator().notificationOccurred(.warning)
        }

        static func error() {
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        }

        static func selectionChanged() {
            UISelectionFeedbackGenerator().selectionChanged()
        }
    }

    // MARK: - Animations

    enum Anim {
        static let spring = Animation.spring(response: 0.5, dampingFraction: 0.8)
        static let springFast = Animation.spring(response: 0.3, dampingFraction: 0.7)
        static let springBouncy = Animation.spring(response: 0.6, dampingFraction: 0.6)
        static let springSnappy = Animation.spring(response: 0.35, dampingFraction: 0.85)
        static let smooth = Animation.easeInOut(duration: 0.3)
        static let smoothSlow = Animation.easeInOut(duration: 0.6)
        static let breathe = Animation.easeInOut(duration: 4).repeatForever(autoreverses: true)
        static let pulse = Animation.easeInOut(duration: 1.2).repeatForever(autoreverses: true)
        static let sosPulse = Animation.easeInOut(duration: 0.8).repeatForever(autoreverses: true)
        static let shimmer = Animation.linear(duration: 2.5).repeatForever(autoreverses: false)
        static let float = Animation.easeInOut(duration: 3).repeatForever(autoreverses: true)
        static let glow = Animation.easeInOut(duration: 2).repeatForever(autoreverses: true)
    }
}

// MARK: - Color Extension for Hex

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
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

// MARK: - SPCard

struct SPCard: ViewModifier {
    @Environment(AppCoordinator.self)
    var coordinator

    var cornerRadius: CGFloat = SP.Layout.cornerMedium
    var padding: CGFloat = SP.Layout.cardPadding

    func body(content: Content) -> some View {
        let theme = coordinator.themeManager
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(theme.bgCard)
                    .shadow(color: theme.shadowSoft, radius: 16, y: 8)
            )
    }
}

// MARK: - SPGlassCard

/// Glass card — в light-режиме использует тёплую заливку вместо .material,
/// чтобы избежать белого системного фона.
struct SPGlassCard: ViewModifier {
    @Environment(AppCoordinator.self)
    var coordinator

    var cornerRadius: CGFloat = SP.Layout.cornerMedium

    func body(content: Content) -> some View {
        let theme = coordinator.themeManager
        content
            .padding(SP.Layout.cardPadding)
            .background(
                ZStack {
                    if theme.isLight {
                        // Тёплая полупрозрачная заливка — никакого белого!
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(Color(hex: "EDE5D8").opacity(0.75))
                    } else {
                        // Оригинальный glass для тёмной темы
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(.ultraThinMaterial)
                    }

                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .stroke(theme.glassBorder, lineWidth: 0.5)
                }
                .shadow(color: theme.shadowSoft, radius: 20, y: 10)
            )
    }
}

// MARK: - SPPrimaryButton

struct SPPrimaryButton: ViewModifier {
    @Environment(AppCoordinator.self)
    var coordinator

    func body(content: Content) -> some View {
        let theme = coordinator.themeManager
        content
            .font(SP.Typography.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(theme.heroGradient)
            .clipShape(RoundedRectangle(cornerRadius: SP.Layout.cornerSmall))
            .shadow(color: theme.accent.opacity(0.4), radius: 12, y: 6)
    }
}

// MARK: - SPSecondaryButton

struct SPSecondaryButton: ViewModifier {
    @Environment(AppCoordinator.self)
    var coordinator

    func body(content: Content) -> some View {
        let theme = coordinator.themeManager
        content
            .font(SP.Typography.headline)
            .foregroundColor(theme.accent)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(theme.accent.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: SP.Layout.cornerSmall))
    }
}

extension View {
    func spCard(cornerRadius: CGFloat = SP.Layout.cornerMedium, padding: CGFloat = SP.Layout.cardPadding) -> some View {
        modifier(SPCard(cornerRadius: cornerRadius, padding: padding))
    }

    func spGlassCard(cornerRadius: CGFloat = SP.Layout.cornerMedium) -> some View {
        modifier(SPGlassCard(cornerRadius: cornerRadius))
    }

    func spPrimaryButton() -> some View {
        modifier(SPPrimaryButton())
    }

    func spSecondaryButton() -> some View {
        modifier(SPSecondaryButton())
    }

    func spBackground() -> some View {
        background(ThemeManager.shared.bg.ignoresSafeArea())
    }
}

// MARK: - FloatingParticle

/// Floating particle for breathing/meditation backgrounds
struct FloatingParticle: View {
    // MARK: Internal

    let color: Color
    let size: CGFloat

    var body: some View {
        Circle()
            .fill(color)
            .frame(width: size, height: size)
            .blur(radius: size * 0.3)
            .opacity(opacity)
            .offset(offset)
            .onAppear {
                let randomX = CGFloat.random(in: -150 ... 150)
                let randomY = CGFloat.random(in: -300 ... 300)
                let randomDelay = Double.random(in: 0 ... 2)
                let randomDuration = Double.random(in: 3 ... 7)

                offset = CGSize(
                    width: CGFloat.random(in: -100 ... 100),
                    height: CGFloat.random(in: -200 ... 200)
                )

                withAnimation(.easeIn(duration: 1).delay(randomDelay)) {
                    opacity = Double.random(in: 0.15 ... 0.5)
                }
                withAnimation(
                    .easeInOut(duration: randomDuration)
                        .repeatForever(autoreverses: true)
                        .delay(randomDelay)
                ) {
                    offset = CGSize(width: randomX, height: randomY)
                }
            }
    }

    // MARK: Private

    @State
    private var offset: CGSize = .zero
    @State
    private var opacity: Double = 0
}

// MARK: - AmbientBackground

/// Animated ambient background with floating orbs
struct AmbientBackground: View {
    // MARK: Internal

    @Environment(AppCoordinator.self)
    var coordinator

    let primaryColor: Color
    var secondaryColor: Color?

    var body: some View {
        let theme = coordinator.themeManager
        let secondary = secondaryColor ?? theme.accent

        ZStack {
            theme.bg.ignoresSafeArea()

            // Large primary orb — ярче в light mode
            Circle()
                .fill(primaryColor.opacity(theme.ambientPrimaryOpacity))
                .frame(width: 350, height: 350)
                .blur(radius: 100)
                .offset(x: animate ? -60 : -100, y: animate ? -180 : -220)

            // Secondary orb
            Circle()
                .fill(secondary.opacity(theme.ambientSecondaryOpacity))
                .frame(width: 250, height: 250)
                .blur(radius: 80)
                .offset(x: animate ? 140 : 100, y: animate ? 280 : 320)

            // Третий тёплый орб для light mode — добавляет глубину
            if theme.isLight {
                Circle()
                    .fill(theme.warmth.opacity(0.05))
                    .frame(width: 300, height: 300)
                    .blur(radius: 90)
                    .offset(x: animate ? 80 : 40, y: animate ? 60 : 20)
            }

            // Accent particles
            ForEach(0 ..< 6, id: \.self) { i in
                FloatingParticle(
                    color: i.isMultiple(of: 2) ? primaryColor : secondary,
                    size: CGFloat.random(in: 4 ... 12)
                )
            }
        }
        .onAppear {
            withAnimation(SP.Anim.float) {
                animate = true
            }
        }
    }

    // MARK: Private

    @State
    private var animate = false
}

// MARK: - ShimmerEffect

/// Shimmer effect overlay
struct ShimmerEffect: ViewModifier {
    // MARK: Internal

    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geo in
                    SP.Colors.shimmerGradient
                        .frame(width: geo.size.width * 2)
                        .offset(x: -geo.size.width + (phase * geo.size.width * 2))
                }
                .mask(content)
            )
            .onAppear {
                withAnimation(SP.Anim.shimmer) {
                    phase = 1
                }
            }
    }

    // MARK: Private

    @State
    private var phase: CGFloat = 0
}

extension View {
    func shimmer() -> some View {
        modifier(ShimmerEffect())
    }
}

// MARK: - AnimatedNumber

/// Animated counting number
struct AnimatedNumber: View {
    // MARK: Internal

    let value: Int
    let font: Font
    let color: Color

    var body: some View {
        Text("\(displayValue)")
            .font(font)
            .foregroundColor(color)
            .monospacedDigit()
            .contentTransition(.numericText())
            .onChange(of: value) { _, newValue in
                withAnimation(SP.Anim.springSnappy) {
                    displayValue = newValue
                }
            }
            .onAppear { displayValue = value }
    }

    // MARK: Private

    @State
    private var displayValue: Int = 0
}

// MARK: - PremiumButtonStyle

/// Premium scale button style with haptic
struct PremiumButtonStyle: ButtonStyle {
    var scale: CGFloat = 0.97

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1.0)
            .opacity(configuration.isPressed ? 0.85 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

// MARK: - GlowPulse

/// Glow pulsing modifier
struct GlowPulse: ViewModifier {
    // MARK: Internal

    let color: Color
    let radius: CGFloat

    func body(content: Content) -> some View {
        content
            .shadow(color: color.opacity(glowing ? 0.6 : 0.2), radius: glowing ? radius : radius * 0.5, y: 4)
            .onAppear {
                withAnimation(SP.Anim.glow) {
                    glowing = true
                }
            }
    }

    // MARK: Private

    @State
    private var glowing = false
}

extension View {
    func glowPulse(color: Color = Color(hex: "6C63FF"), radius: CGFloat = 20) -> some View {
        modifier(GlowPulse(color: color, radius: radius))
    }
}

// MARK: - WarmGlass

/// В light-режиме .ultraThinMaterial показывает белый фон.
/// Этот ShapeStyle автоматически заменяет его тёплым fill.
@MainActor
struct WarmGlass: ShapeStyle {
    func resolve(in environment: EnvironmentValues) -> some ShapeStyle {
        if ThemeManager.shared.isLight {
            Color(hex: "EDE5D8").opacity(0.7)
        } else {
            Color(hex: "1A1F35").opacity(0.4)
        }
    }
}

extension ShapeStyle where Self == WarmGlass {
    @MainActor
    static var warmGlass: WarmGlass {
        WarmGlass()
    }
}
